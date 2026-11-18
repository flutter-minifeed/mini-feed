import 'package:flutter/material.dart';

import '../models/author.dart';
import '../service/auth/auth_service.dart';
import '../widgets/user_avatar.dart';

/// S4 익명 로그인·S20 첫 실행 오프라인. 시스템 바는 Flutter로 그리지 않는다.
class StartScreen extends StatelessWidget {
  const StartScreen({super.key, this.author, this.failure, this.onRetry});

  final Author? author;
  final SessionFailure? failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final offline = failure == SessionFailure.offline;
    final failed = failure != null;
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
      _ => ('앱을 시작하지 못했어요', '잠시 후 다시 시도해 주세요.'),
    };

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('미니피드', style: theme.textTheme.headlineMedium),
                            SizedBox(height: failed ? 72 : 56),
                            if (failed) ...[
                              Icon(
                                offline ? Icons.wifi_off : Icons.error_outline,
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
                                constraints: const BoxConstraints(
                                  maxWidth: 300,
                                ),
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
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    0,
                                    16,
                                    0,
                                  ),
                                ),
                              ),
                            ] else ...[
                              if (author != null) ...[
                                UserAvatar(
                                  author: author!,
                                  radius: 48,
                                  fontSize: 40,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  author!.nickName,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '이 기기의 익명 닉네임이에요. 바꿀 수 없어요.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
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
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 20,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '이메일·전화번호를 묻지 않아요.\n이 기기에서만 쓰는 익명 ID로 시작합니다.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
