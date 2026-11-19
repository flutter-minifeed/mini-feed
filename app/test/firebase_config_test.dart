import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minifeed/firebase_config.dart';

void main() {
  const hasSettings =
      bool.hasEnvironment('FIREBASE_API_KEY') &&
      bool.hasEnvironment('FIREBASE_APP_ID') &&
      bool.hasEnvironment('FIREBASE_MESSAGING_SENDER_ID') &&
      bool.hasEnvironment('FIREBASE_PROJECT_ID');

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('설정 없이 실행하면 준비 방법을 안내한다', () {
    expect(
      firebaseOptionsFromEnvironment,
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          '설정 안내',
          contains('--dart-define-from-file=../.env'),
        ),
      ),
    );
  }, skip: hasSettings);

  test('환경 파일을 전달하면 네이티브 연결 전에 설정을 구성할 수 있다', () {
    final options = firebaseOptionsFromEnvironment();
    expect(options.apiKey, isNotEmpty);
    expect(options.appId, isNotEmpty);
    expect(options.messagingSenderId, isNotEmpty);
    expect(options.projectId, isNotEmpty);
  }, skip: !hasSettings);

  test('미설정 플랫폼에서 Android 설정을 사용하지 않는다', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(firebaseOptionsFromEnvironment, throwsUnsupportedError);
  });
}
