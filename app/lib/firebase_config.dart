import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// 루트 .env를 --dart-define-from-file로 전달한다. 실제 값은 소스에 두지 않는다.
FirebaseOptions firebaseOptionsFromEnvironment() {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    throw UnsupportedError('현재 Firebase 연결은 Android만 지원합니다.');
  }

  const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_APP_ID');
  const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

  final missingKeys = <String>[
    if (apiKey.trim().isEmpty) 'FIREBASE_API_KEY',
    if (appId.trim().isEmpty) 'FIREBASE_APP_ID',
    if (senderId.trim().isEmpty) 'FIREBASE_MESSAGING_SENDER_ID',
    if (projectId.trim().isEmpty) 'FIREBASE_PROJECT_ID',
  ];
  if (missingKeys.isNotEmpty) {
    throw StateError(
      'Firebase 설정 누락: ${missingKeys.join(', ')}. '
      '루트 .env를 준비하고 app/에서 '
      '--dart-define-from-file=../.env 옵션을 전달하세요.',
    );
  }

  return FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: senderId,
    projectId: projectId,
    storageBucket: storageBucket.isEmpty ? null : storageBucket,
  );
}
