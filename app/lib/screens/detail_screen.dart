import 'package:flutter/material.dart';

import '../models/comment.dart';
import '../models/post.dart';
import '../repository/repository_scope.dart';
import '../widgets/comment_input.dart';
import '../widgets/comment_tile.dart';
import '../widgets/post_actions.dart';
import '../widgets/post_card.dart';

// 상세 화면이 한 번에 불러오는 글과 댓글 목록.
typedef _DetailData = ({Post post, List<Comment> comments});

/// 게시글 상세 화면 (#9).
///
/// 피드 카드 본문을 누르면 [postId]만 넘겨 열고,
/// 댓글 아이콘을 누르면 [focusComment]를 true로 넘겨 댓글 입력창에 바로 포커스를 준다.
class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.postId,
    this.focusComment = false,
    this.onRemoved,
  });

  final String postId;
  final bool focusComment;
  final VoidCallback? onRemoved;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _commentController = TextEditingController();
  final _commentFocus = FocusNode();

  // 글·댓글을 불러오는 작업. 화면을 다시 그려도 새로 부르지 않게 한 번만 만든다.
  Future<_DetailData?>? _data;
  bool _actionPending = false;

  @override
  void initState() {
    super.initState();
    // 입력창은 글을 다 불러온 뒤에 화면에 붙는다. 아직 붙지 않은 FocusNode에
    // 포커스를 요청하면 Flutter가 기억해 뒀다가, 붙는 순간 포커스를 주고 키보드를 연다.
    if (widget.focusComment) _commentFocus.requestFocus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // RepositoryScope.of는 initState에서 부를 수 없어서, 여기서 처음 한 번만 부른다.
    _data ??= _load(RepositoryScope.of(context));
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  Future<_DetailData?> _load(RepositoryScope repositories) async {
    // 댓글을 읽는 동안 삭제된 글의 본문을 다시 표시하지 않도록 글을 마지막에 확인한다.
    final comments = await repositories.commentRepository.getComments(
      widget.postId,
    );
    final post = await repositories.postRepository.getPostById(widget.postId);
    if (post != null) {
      return (post: post, comments: comments);
    }
    if (mounted &&
        widget.onRemoved != null &&
        ModalRoute.of(context)?.isCurrent == true) {
      await _noticeAndLeave();
    }
    return null;
  }

  // 상세 안의 댓글 버튼. 입력창을 직접 누른 것과 같게 처리한다(#49 글쓰기와 같은 방식).
  // 포커스가 없으면 포커스를 주고, Android 뒤로가기로 키보드만 내린 상태(포커스는 남음)면
  // 키보드를 다시 올린다.
  void _focusCommentInput() {
    _commentFocus.context
        ?.findAncestorStateOfType<EditableTextState>()
        ?.requestKeyboard();
  }

  void _leaveDeletedPost() {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    widget.onRemoved?.call();
    Navigator.of(context).pop();
  }

  Future<void> _noticeAndLeave() async {
    await showDeletedPostNotice(context);
    _leaveDeletedPost();
  }

  Future<void> _openMenu(Post post) async {
    if (_actionPending) return;
    _actionPending = true;
    final repository = RepositoryScope.of(context).postRepository;
    try {
      final removed = await handlePostMenu(
        context,
        own: post.author.id == repository.currentUser.id,
        deletePost: () => repository.deletePost(post.id),
      );
      if (removed) _leaveDeletedPost();
    } finally {
      _actionPending = false;
    }
  }

  Future<void> _checkBeforeInteraction() async {
    if (_actionPending) return;
    _actionPending = true;
    try {
      final post = await RepositoryScope.of(context).postRepository
          .getPostById(widget.postId);
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      if (post == null) {
        await _noticeAndLeave();
        return;
      }
      // 좋아요 토글과 댓글 등록은 각각 담당 이슈에서 이 확인 뒤에 연결한다.
    } catch (_) {
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('글을 확인하지 못했어요. 다시 시도해 주세요.')),
      );
    } finally {
      _actionPending = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('게시글')),
      body: FutureBuilder<_DetailData?>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _Message('게시글을 불러오지 못했어요.');
          }
          final data = snapshot.data;
          if (data == null) {
            return const _Message('삭제되었거나 없는 게시글이에요.');
          }
          // 글과 댓글의 상대 시간을 같은 시각 기준으로 센다.
          final now = DateTime.now();
          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    PostCard(
                      post: data.post,
                      now: now,
                      onMore: () => _openMenu(data.post),
                      onLike: _checkBeforeInteraction,
                      onComments: _focusCommentInput,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        '댓글 ${data.comments.length}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    for (final comment in data.comments)
                      CommentTile(
                        key: ValueKey(comment.id),
                        comment: comment,
                        now: now,
                      ),
                  ],
                ),
              ),
              // 키보드가 올라오면 Scaffold가 body 높이를 줄여서 입력창이 키보드 바로 위에 온다.
              // 키보드가 없을 때는 SafeArea가 시스템 내비게이션 바만큼 띄운다.
              SafeArea(
                top: false,
                child: CommentInput(
                  controller: _commentController,
                  focusNode: _commentFocus,
                  onSend: (_) => _checkBeforeInteraction(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// 글을 불러오지 못했거나 없을 때 가운데에 띄우는 안내 문구.
class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
