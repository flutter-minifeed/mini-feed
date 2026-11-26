import 'dart:async';

import 'package:flutter/material.dart';

import '../models/post.dart';
import '../repository/post/post_repository.dart';
import '../repository/repository_scope.dart';
import '../viewmodels/write_view_model.dart';
import '../widgets/offline_banner.dart';
import '../widgets/post_card.dart';
import 'detail_screen.dart';
import 'write_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, required this.createWriteViewModel});

  final WriteViewModel Function() createWriteViewModel;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _scrollController = ScrollController();
  PostRepository? _repository;
  List<Post> _posts = const [];
  // 게시 결과로 먼저 표시했지만 아직 페이지 조회로 확인하지 않은 글.
  final _unpagedPostIds = <String>{};
  PostPage? _pendingPage;
  PostCursor? _nextCursor;
  int _newPostCount = 0;
  int _highlightedPostCount = 0;
  Post? _highlightBoundary;
  bool _loading = true;
  bool _failed = false;
  bool _refreshing = false;
  bool _loadingMore = false;
  bool _moreFailed = false;
  // #15 서버에 닿지 못해 기기 캐시의 글을 보여주는 중이면 true다.
  bool _offline = false;
  Timer? _offlineRetry;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = RepositoryScope.of(context).postRepository;
    if (repository != _repository) {
      _repository = repository;
      _posts = const [];
      _unpagedPostIds.clear();
      _nextCursor = null;
      _pendingPage = null;
      _newPostCount = 0;
      _highlightedPostCount = 0;
      _highlightBoundary = null;
      _offline = false;
      _loadPosts();
    }
  }

  Future<void> _loadPosts({
    bool revealNewPost = false,
    bool isRefresh = false,
  }) async {
    final requestId = ++_requestId;
    final repository = _repository!;
    _offlineRetry?.cancel();
    setState(() {
      // 새로고침 동안 기존 목록과 스크롤 위치를 유지한다.
      _loading = !isRefresh;
      _refreshing = isRefresh;
      _loadingMore = false;
      _moreFailed = false;
      if (!isRefresh) _failed = false;
    });

    try {
      final page = await repository.getPostPage();
      final posts = page.posts;
      if (!mounted || requestId != _requestId) return;

      final previousFirst = _posts.firstOrNull;
      final newPostCount = previousFirst == null
          ? posts.length
          : posts
                .takeWhile(
                  (post) => comparePostsNewestFirst(post, previousFirst) < 0,
                )
                .length;
      final showChip =
          isRefresh && !revealNewPost && _posts.isNotEmpty && newPostCount > 0;
      final showTop = revealNewPost && newPostCount > 0;
      final offline = page.fromCache;
      // 처음부터 캐시가 비어 있으면 보여줄 글이 없으니 불러오지 못한 것으로 안내한다.
      final nothingCached = offline && posts.isEmpty && _posts.isEmpty;
      final recovered = !offline && (_offline || (isRefresh && _failed));
      setState(() {
        _loading = false;
        _refreshing = false;
        _failed = nothingCached;
        _offline = offline;
        _pendingPage = showChip ? page : null;
        _newPostCount = showChip ? newPostCount : 0;
        if (!showChip) {
          _applyFirstPage(page, keepTail: isRefresh);
          _highlightedPostCount = 0;
          _highlightBoundary = null;
        }
      });
      if (offline) _scheduleOfflineRetry();
      // 상세가 위에 열려 있으면 띄우지 않는다. 스낵바는 앱 전체가 같이 써서 상세 위에 뜬다(#15).
      if (recovered && (ModalRoute.isCurrentOf(context) ?? true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              spacing: 12,
              children: [
                Icon(Icons.wifi, size: 20),
                Expanded(child: Text('다시 연결됐어요. 최신 글을 불러왔어요.')),
              ],
            ),
          ),
        );
      }
      if (showTop) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              requestId == _requestId &&
              _scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
        });
      }
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        if (!isRefresh) _failed = true;
      });
      if (isRefresh) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('새로고침하지 못했습니다. 다시 시도해 주세요.')),
        );
      }
    }
  }

  // 오프라인이면 같은 새로고침을 일정 시간 뒤 다시 보내 서버 연결 복구를 확인한다(#15).
  // 새로고침은 읽던 목록과 위치를 유지하고, 새 글은 칩으로만 알린다.
  void _scheduleOfflineRetry() {
    _offlineRetry?.cancel();
    _offlineRetry = Timer(offlineRetryInterval, () {
      if (mounted) _loadPosts(isRefresh: true);
    });
  }

  // 새 첫 페이지와 겹치는 기존 뒷부분은 유지한다.
  // 연결점이 없으면 새 커서부터 읽어 중간 글을 건너뛰지 않는다.
  void _applyFirstPage(PostPage page, {bool keepTail = false}) {
    final ids = page.posts.map((post) => post.id).toSet();
    final pagedPosts = _posts.where(
      (post) => !_unpagedPostIds.contains(post.id),
    );
    final overlaps = pagedPosts.any((post) => ids.contains(post.id));
    final last = page.posts.lastOrNull;
    final tail = keepTail && overlaps && last != null && page.nextCursor != null
        ? pagedPosts
              .where(
                (post) =>
                    !ids.contains(post.id) &&
                    comparePostsNewestFirst(post, last) > 0,
              )
              .toList()
        : <Post>[];
    _posts = [...page.posts, ...tail];
    _unpagedPostIds.clear();
    if (tail.isEmpty) _nextCursor = page.nextCursor;
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 300) _loadMore();
  }

  Future<void> _loadMore() async {
    final repository = _repository;
    final cursor = _nextCursor;
    if (repository == null ||
        cursor == null ||
        _loading ||
        _refreshing ||
        _loadingMore ||
        _moreFailed) {
      return;
    }
    final requestId = _requestId;
    setState(() => _loadingMore = true);
    try {
      final page = await repository.getPostPage(after: cursor);
      if (!mounted || requestId != _requestId) return;
      if (page.fromCache) {
        // 캐시로 만든 다음 페이지는 읽은 적 없는 중간 글이 빠질 수 있어 붙이지 않는다(#15).
        // 커서는 그대로 두고, 첫 페이지처럼 오프라인 안내와 재확인으로 복구를 기다린다.
        setState(() {
          _loadingMore = false;
          _moreFailed = true;
          _offline = true;
        });
        _scheduleOfflineRetry();
        return;
      }
      final ids = _posts.map((post) => post.id).toSet();
      setState(() {
        _posts = [..._posts, ...page.posts.where((post) => ids.add(post.id))];
        _highlightedPostCount = _countHighlightedPosts();
        _nextCursor = page.nextCursor;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loadingMore = false;
        _moreFailed = true;
      });
    }
  }

  void _showNewPosts() {
    final page = _pendingPage;
    if (page == null) return;
    ++_requestId; // 이전 목록의 늦은 추가 조회는 새 목록에 적용하지 않는다.
    setState(() {
      _highlightBoundary = _posts.firstOrNull;
      _applyFirstPage(page, keepTail: true);
      _pendingPage = null;
      _highlightedPostCount = _countHighlightedPosts();
      _newPostCount = 0;
      _refreshing = false;
      _loadingMore = false;
      _moreFailed = false;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  int _countHighlightedPosts() {
    final boundary = _highlightBoundary;
    return boundary == null
        ? 0
        : _posts
              .takeWhile((post) => comparePostsNewestFirst(post, boundary) < 0)
              .length;
  }

  String get _newPostsLabel {
    final page = _pendingPage!;
    // 한 페이지가 모두 새 글이면 전체 개수를 단정하지 않는다.
    return page.nextCursor != null && _newPostCount == page.posts.length
        ? '새 글 $_newPostCount개 이상'
        : '새 글 $_newPostCount개';
  }

  Future<void> _openWrite() async {
    final viewModel = widget.createWriteViewModel();
    final post = await Navigator.of(context).push<Post>(
      MaterialPageRoute<Post>(
        fullscreenDialog: true,
        builder: (_) => WriteScreen(viewModel: viewModel),
      ),
    );
    if (!mounted) return;
    if (post == null) {
      // 시간 초과 뒤 실제 저장이 끝났을 수 있다. 일반 취소는 읽던 상태를 유지한다.
      if (viewModel.status == WriteStatus.timedOut) {
        await _loadPosts(isRefresh: true, revealNewPost: true);
      }
      return;
    }

    setState(() {
      _unpagedPostIds.add(post.id);
      _posts = [post, ..._posts.where((item) => item.id != post.id)];
      _pendingPage = null;
      _newPostCount = 0;
      _highlightedPostCount = 0;
      _highlightBoundary = null;
      _loading = false;
      _failed = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
    await _loadPosts(isRefresh: true);
  }

  void _openDetail(Post post, {bool focusComment = false}) {
    // 피드의 재연결 안내가 상세로 넘어가 상세 오프라인 안내와 겹치지 않게 닫는다(#15).
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: '/posts/${post.id}'),
        builder: (_) =>
            DetailScreen(postId: post.id, focusComment: focusComment),
      ),
    );
  }

  @override
  void dispose() {
    _offlineRetry?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      displacement: 36,
      onRefresh: () => _loadPosts(isRefresh: true),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('미니피드'),
          centerTitle: true,
          toolbarHeight: 64,
          backgroundColor: theme.colorScheme.surfaceContainer,
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              // 불러오지 못함 안내와 겹치지 않게, 캐시 글을 보여줄 때만 띄운다.
              if (_offline && !_failed)
                OfflineBanner(
                  message: '오프라인이에요. 이전에 불러온 글을 보여주고 있어요.',
                  onRetry: () => _loadPosts(isRefresh: true),
                ),
              Expanded(
                child: Stack(
                  children: [
                    _buildBody(DateTime.now()),
                    if (_pendingPage != null)
                      Positioned(
                        top: 12,
                        left: 16,
                        right: 16,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: FilledButton(
                            onPressed: _showNewPosts,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.fromLTRB(14, 8, 16, 8),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              elevation: 3,
                              shadowColor: theme.colorScheme.scrim.withValues(
                                alpha: 0.25,
                              ),
                              textStyle: theme.textTheme.labelLarge,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 6,
                              children: [
                                const Icon(Icons.arrow_upward, size: 18),
                                Text(_newPostsLabel),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: '글쓰기',
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          elevation: 0,
          onPressed: _loading ? null : _openWrite,
          child: const Icon(Icons.edit),
        ),
      ),
    );
  }

  Widget _buildBody(DateTime now) {
    if (_loading && _posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_failed || _posts.isEmpty) {
      return CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: _failed
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('게시글을 불러오지 못했습니다.'),
                        TextButton(
                          onPressed: _loadPosts,
                          child: const Text('다시 시도'),
                        ),
                      ],
                    )
                  : const Text('아직 게시글이 없습니다.'),
            ),
          ),
        ],
      );
    }
    final showDivider =
        _highlightedPostCount > 0 && _highlightedPostCount < _posts.length;
    return ListView.builder(
      key: const PageStorageKey('feed'),
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 88),
      itemCount:
          _posts.length + (showDivider ? 1 : 0) + (_nextCursor != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _posts.length + (showDivider ? 1 : 0)) return _buildMore();
        if (showDivider && index == _highlightedPostCount) {
          final theme = Theme.of(context);
          return Container(
            color: theme.colorScheme.surfaceContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '여기까지 새 글 · 이전에 보던 글',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        final postIndex = showDivider && index > _highlightedPostCount
            ? index - 1
            : index;
        final post = _posts[postIndex];
        return PostCard(
          key: ValueKey(post.id),
          post: post,
          now: now,
          highlighted: postIndex < _highlightedPostCount,
          onOpen: () => _openDetail(post),
          onComments: () => _openDetail(post, focusComment: true),
        );
      },
    );
  }

  Widget _buildMore() {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return TextButton(
      onPressed: () {
        _moreFailed = false;
        _loadMore();
      },
      child: Text(_moreFailed ? '다시 불러오기' : '더 불러오기'),
    );
  }
}
