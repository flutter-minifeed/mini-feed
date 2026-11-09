import 'package:flutter/material.dart';

import '../models/comment.dart';
import '../models/post.dart';
import '../repository/repository_scope.dart';
import '../widgets/comment_input.dart';
import '../widgets/comment_tile.dart';

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
  });

  final String postId;
  final bool focusComment;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _commentController = TextEditingController();
  final _commentFocus = FocusNode();

  // 글·댓글을 불러오는 작업. 화면을 다시 그려도 새로 부르지 않게 한 번만 만든다.
  Future<_DetailData?>? _data;

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
    final post = await repositories.postRepository.getPostById(widget.postId);
    if (post == null) return null;
    final comments = await repositories.commentRepository.getComments(post.id);
    return (post: post, comments: comments);
  }

  void _sendComment(String body) {
    // TODO(#20): MP3에서 commentRepository로 등록하고, 성공하면 입력을 지운다.
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
          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    _PostSection(
                      post: data.post,
                      onCommentTap: _commentFocus.requestFocus,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        '댓글 ${data.comments.length}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    for (final comment in data.comments)
                      CommentTile(key: ValueKey(comment.id), comment: comment),
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
                  onSend: _sendComment,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// 상세 위쪽 게시글 영역. Figma PostCard 모양이다.
//
// PostCard는 피드 카드(#7)와 함께 쓰는 위젯이라 지금은 상세 안에 임시로 둔다.
// #7의 PostCard가 머지되면 그것으로 바꾼다.
class _PostSection extends StatelessWidget {
  const _PostSection({required this.post, required this.onCommentTap});

  final Post post;
  final VoidCallback onCommentTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TODO(#9): 아바타·상대 시간·더보기 버튼은 #7·#10 머지 후 붙인다.
          Text(post.author.nickName, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(post.body, style: textTheme.bodyLarge),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                _PostAction(
                  icon: Icons.favorite_border,
                  count: post.likeCount,
                  // TODO(#18): MP3에서 좋아요 상태를 서버에 반영한다.
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
                _PostAction(
                  icon: Icons.chat_bubble_outline,
                  count: post.commentCount,
                  onPressed: onCommentTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 좋아요·댓글 개수 버튼. Figma PostAction 모양이다(테두리 있는 알약형).
class _PostAction extends StatelessWidget {
  const _PostAction({
    required this.icon,
    required this.count,
    required this.onPressed,
  });

  final IconData icon;
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text('$count'),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.onSurfaceVariant,
        iconColor: colors.onSurfaceVariant,
        textStyle: Theme.of(context).textTheme.labelMedium,
        side: BorderSide(color: colors.outlineVariant),
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
