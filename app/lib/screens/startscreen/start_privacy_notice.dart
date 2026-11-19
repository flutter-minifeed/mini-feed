import 'package:flutter/material.dart';

class StartPrivacyNotice extends StatelessWidget {
  const StartPrivacyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            '이메일·전화번호를 묻지 않아요.\n이 기기에서만 쓰는 익명 ID로 시작합니다.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
