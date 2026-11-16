import 'package:flutter/material.dart';

import '../models/post.dart';
import '../utils/relative_time.dart';
import 'author_tile.dart';

/// 피드의 게시글 한 건. 본문과 댓글은 서로 다른 상세 진입을 전달한다.
///
/// 상세 화면도 같은 카드를 쓰며, 이미 상세라서 [onOpen]을 넘기지 않는다.
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.now,
    this.onOpen,
    required this.onComments,
  });

  final Post post;
  final DateTime now;

  /// 본문을 눌렀을 때 할 일. null이면 본문을 눌러도 반응하지 않는다.
  final VoidCallback? onOpen;
  final VoidCallback onComments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    return Ink(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              spacing: 12,
              children: [
                Expanded(
                  child: AuthorTile(
                    author: post.author,
                    subtitle: relativeTime(post.createdAt, now: now),
                  ),
                ),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.more_horiz,
                    color: colors.onSurfaceVariant,
                    semanticLabel: '더보기',
                  ),
                ),
              ],
            ),
            InkWell(
              key: ValueKey('body-${post.id}'),
              onTap: onOpen,
              child: SizedBox(
                width: double.infinity,
                child: Text(post.body, style: text.bodyLarge),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                spacing: 8,
                children: [
                  Semantics(
                    label: '좋아요 ${post.likeCount}개',
                    child: ExcludeSemantics(
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: ShapeDecoration(
                          color: post.likedByMe
                              ? colors.surfaceContainerHigh
                              : colors.surface,
                          shape: StadiumBorder(
                            side: BorderSide(color: colors.outlineVariant),
                          ),
                        ),
                        child: Row(
                          spacing: 6,
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 20,
                              color: colors.onSurfaceVariant,
                            ),
                            Text(
                              '${post.likeCount}',
                              style: text.labelMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    key: ValueKey('comments-${post.id}'),
                    onPressed: onComments,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.onSurfaceVariant,
                      side: BorderSide(color: colors.outlineVariant),
                      shape: const StadiumBorder(),
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: text.labelMedium,
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    label: Text('${post.commentCount}'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
