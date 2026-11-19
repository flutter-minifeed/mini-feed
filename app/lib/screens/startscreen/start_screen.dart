import 'package:flutter/material.dart';

import '../../models/author.dart';
import '../../service/auth/auth_service.dart';
import 'start_failure.dart';
import 'start_loading.dart';
import 'start_privacy_notice.dart';

/// S4 익명 로그인·S20 첫 실행 오프라인. 시스템 바는 Flutter로 그리지 않는다.
class StartScreen extends StatelessWidget {
  const StartScreen({super.key, this.author, this.failure, this.onRetry});

  final Author? author;
  final SessionFailure? failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = this.failure;

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
                            Text(
                              '미니피드',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            SizedBox(height: failure != null ? 72 : 56),
                            if (failure != null)
                              StartFailure(failure: failure, onRetry: onRetry)
                            else
                              StartLoading(author: author),
                          ],
                        ),
                      ),
                    ),
                    const StartPrivacyNotice(),
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
