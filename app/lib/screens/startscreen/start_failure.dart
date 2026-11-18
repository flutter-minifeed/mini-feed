import 'package:flutter/material.dart';

import '../../service/auth/auth_service.dart';

class StartFailure extends StatelessWidget {
  const StartFailure({super.key, required this.failure, this.onRetry});

  final SessionFailure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (title, message) = switch (failure) {
      SessionFailure.offline => (
        '네트워크에 연결되어 있지 않아요',
        '처음 시작할 때는 익명 계정을 만들기 위해 연결이 필요해요. 연결한 뒤 다시 시도해 주세요.',
      ),
      SessionFailure.permissionDenied => (
        '프로필을 불러올 수 없어요',
        '잠시 후 다시 시도해 주세요. 문제가 계속되면 앱 관리자에게 알려 주세요.',
      ),
      SessionFailure.configuration => (
        '앱을 시작할 수 없어요',
        '앱 연결 설정을 확인한 뒤 다시 시도해 주세요.',
      ),
      SessionFailure.invalidProfile => (
        '프로필을 확인할 수 없어요',
        '저장된 정보를 확인할 수 없어요. 문제가 계속되면 앱 관리자에게 알려 주세요.',
      ),
      SessionFailure.unknown => ('앱을 시작하지 못했어요', '잠시 후 다시 시도해 주세요.'),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          failure == SessionFailure.offline
              ? Icons.wifi_off
              : Icons.error_outline,
          size: 48,
          color: colors.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('다시 시도'),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
          ),
        ),
      ],
    );
  }
}
