import 'package:flutter/material.dart';

import '../models/comment.dart';

/// 상세 화면의 댓글 한 줄. Figma CommentTile(Mine=No)과 이름을 맞춘다(R10).
///
/// 아바타와 상대 시간은 피드 카드와 함께 쓰는 부분이라 #7·#10이 머지된 뒤
/// 다음 PR에서 붙인다. 지금은 닉네임과 본문만 표시한다.
class CommentTile extends StatelessWidget {
  const CommentTile({super.key, required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TODO(#9): 아바타(왼쪽)와 상대 시간(닉네임 오른쪽)을 붙인다.
          Text(
            comment.author.nickName,
            style: textTheme.titleSmall?.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: 2),
          Text(
            comment.body,
            style: textTheme.bodyMedium?.copyWith(color: colors.onSurface),
          ),
        ],
      ),
    );
  }
}
