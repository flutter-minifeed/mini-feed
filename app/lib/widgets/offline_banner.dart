import 'package:flutter/material.dart';

/// 오프라인일 때 화면이 서버 연결을 다시 확인하는 간격(#15).
///
/// 연결 상태 패키지 대신 같은 조회를 다시 보내 실제로 서버에 닿는지로 복구를 판단한다.
const offlineRetryInterval = Duration(seconds: 10);

/// 앱바 아래에 붙는 오프라인 안내. Figma OfflineBanner(M1·M14)와 이름을 맞춘다.
///
/// 무엇을 보여주는지 알리는 [message]와, 바로 다시 연결을 확인하는 다시 시도 버튼을 둔다.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      color: colors.surfaceContainerHigh,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Icon(Icons.wifi_off, size: 20, color: colors.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(child: Text(message, style: textTheme.bodySmall)),
            ],
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('다시 시도'),
            style: TextButton.styleFrom(foregroundColor: colors.onSurface),
          ),
        ],
      ),
    );
  }
}
