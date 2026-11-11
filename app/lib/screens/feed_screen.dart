import 'package:flutter/material.dart';

import '../models/post.dart';
import '../repository/post/post_repository.dart';
import '../repository/repository_scope.dart';
import '../widgets/post_card.dart';
import 'detail_screen.dart';
import 'write_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _scrollController = ScrollController();
  PostRepository? _repository;
  List<Post> _posts = const [];
  bool _loading = true;
  bool _failed = false;
  int _requestId = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = RepositoryScope.of(context).postRepository;
    if (repository != _repository) {
      _repository = repository;
      _posts = const [];
      _loadPosts();
    }
  }

  Future<void> _loadPosts({bool revealNewPost = false}) async {
    final requestId = ++_requestId;
    final repository = _repository!;
    setState(() {
      _loading = true;
      _failed = false;
    });

    try {
      final posts = await repository.getPosts();
      if (!mounted || requestId != _requestId) return;

      final showTop =
          revealNewPost &&
          posts.isNotEmpty &&
          (_posts.isEmpty || posts.first.id != _posts.first.id);
      setState(() {
        _posts = posts;
        _loading = false;
      });
      if (showTop) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
        });
      }
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _openWrite() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const WriteScreen(),
      ),
    );
    if (mounted) await _loadPosts(revealNewPost: true);
  }

  void _openDetail(Post post, {bool focusComment = false}) {
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('미니피드'),
        centerTitle: true,
        toolbarHeight: 64,
        backgroundColor: theme.colorScheme.surfaceContainer,
      ),
      body: SafeArea(top: false, child: _buildBody(DateTime.now())),
      floatingActionButton: FloatingActionButton(
        tooltip: '글쓰기',
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        elevation: 0,
        onPressed: _loading ? null : _openWrite,
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildBody(DateTime now) {
    if (_loading && _posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('게시글을 불러오지 못했습니다.'),
            TextButton(onPressed: _loadPosts, child: const Text('다시 시도')),
          ],
        ),
      );
    }
    if (_posts.isEmpty) {
      return const Center(child: Text('아직 게시글이 없습니다.'));
    }
    return ListView.builder(
      key: const PageStorageKey('feed'),
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return PostCard(
          key: ValueKey(post.id),
          post: post,
          now: now,
          onOpen: () => _openDetail(post),
          onComments: () => _openDetail(post, focusComment: true),
        );
      },
    );
  }
}
