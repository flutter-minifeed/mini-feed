import 'package:flutter/material.dart';

import '../models/comment.dart';
import '../utils/relative_time.dart';
import 'user_avatar.dart';

/// 상세 화면의 댓글 한 줄. Figma CommentTile(Mine=No)과 이름을 맞춘다(R10).
class CommentTile extends StatelessWidget {
  const CommentTile({super.key, required this.comment, required this.now});

  final Comment comment;

  /// 상대 시간의 기준 시각. 피드 카드처럼 화면이 정해서 넘긴다.
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          UserAvatar(author: comment.author, radius: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  spacing: 8,
                  children: [
                    Flexible(
                      child: Text(
                        comment.author.nickName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall,
                      ),
                    ),
                    Text(
                      relativeTime(comment.createdAt, now: now),
                      style: text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Text(comment.body, style: text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
