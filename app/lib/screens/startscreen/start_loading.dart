import 'package:flutter/material.dart';

import '../../models/author.dart';
import '../../widgets/user_avatar.dart';

class StartLoading extends StatelessWidget {
  const StartLoading({super.key, this.author});

  final Author? author;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final author = this.author;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (author != null) ...[
          UserAvatar(author: author, radius: 48, fontSize: 40),
          const SizedBox(height: 16),
          Text(
            author.nickName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            '이 기기의 익명 닉네임이에요. 바꿀 수 없어요.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 48),
        ],
        const RepaintBoundary(
          child: SizedBox.square(
            dimension: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              semanticsLabel: '익명 계정 준비 중',
            ),
          ),
        ),
      ],
    );
  }
}
