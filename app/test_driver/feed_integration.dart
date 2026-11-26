import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final output = Platform.environment['MINIFEED_TEST_ARTIFACTS'];
  if (output == null || output.isEmpty) {
    throw StateError('MINIFEED_TEST_ARTIFACTS로 캡처 저장 폴더를 지정해 주세요.');
  }
  final directory = Directory(output);
  await directory.create(recursive: true);
  await integrationDriver(
    onScreenshot:
        (String name, List<int> image, [Map<String, Object?>? args]) async {
          await File('${directory.path}/$name.png').writeAsBytes(image);
          return image.isNotEmpty;
        },
    responseDataCallback: (data) async {
      // 스크린샷은 위 콜백으로 저장한다. Base64 응답 파일은 따로 만들지 않는다.
    },
  );
}
