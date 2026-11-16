import 'package:flutter/material.dart';

import '../models/author.dart';
import 'user_avatar.dart';

/// 작성자 아바타와 닉네임, 그 아래 한 줄 설명. 피드 카드(작성 시각)와 글쓰기(익명 안내)가 함께 쓴다.
class AuthorTile extends StatelessWidget {
  const AuthorTile({super.key, required this.author, required this.subtitle});

  final Author author;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    return Row(
      spacing: 12,
      children: [
        UserAvatar(author: author),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author.nickName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleMedium,
              ),
              Text(
                subtitle,
                style: text.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
