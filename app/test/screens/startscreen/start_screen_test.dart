import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minifeed/models/author.dart';
import 'package:minifeed/screens/startscreen/start_screen.dart';
import 'package:minifeed/service/auth/auth_service.dart';
import 'package:minifeed/theme/app_theme.dart';
import 'package:minifeed/widgets/user_avatar.dart';

const _author = Author(id: 'test-user', nickName: '밤산책 고양이', colorIndex: 4);
const _privacyText = '이메일·전화번호를 묻지 않아요.\n이 기기에서만 쓰는 익명 ID로 시작합니다.';

Widget _screen({
  Author? author,
  SessionFailure? failure,
  VoidCallback? onRetry,
  double textScale = 1,
}) => MaterialApp(
  theme: appTheme,
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: StartScreen(author: author, failure: failure, onRetry: onRetry),
  ),
);

void main() {
  for (final (state, author, failure) in [
    ('로딩', null, null),
    ('프로필 로딩', _author, null),
    ('오프라인', null, SessionFailure.offline),
  ]) {
    testWidgets('$state 시작 화면이 화면 너비의 중앙에 배치된다', (tester) async {
      // given
      const size = Size(412, 892);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // when
      await tester.pumpWidget(_screen(author: author, failure: failure));

      // then
      final indicator = failure == null
          ? find.byType(CircularProgressIndicator)
          : find.byIcon(Icons.wifi_off);
      final elements = [
        find.text('미니피드'),
        indicator,
        find.byIcon(Icons.lock_outline),
        if (author != null) ...[
          find.byType(UserAvatar),
          find.text(author.nickName),
        ],
      ];
      for (final element in elements) {
        expect(tester.getCenter(element).dx, closeTo(size.width / 2, 0.01));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('작은 화면과 큰 글자에서도 $state 내용과 하단 안내를 볼 수 있다', (tester) async {
      // given
      const size = Size(320, 480);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final elements = [
        find.text('미니피드'),
        if (author != null) ...[
          find.byType(UserAvatar),
          find.text(author.nickName),
          find.text('이 기기의 익명 닉네임이에요. 바꿀 수 없어요.'),
        ],
        if (failure == null)
          find.byType(CircularProgressIndicator)
        else ...[
          find.text('네트워크에 연결되어 있지 않아요'),
          find.text('처음 시작할 때는 익명 계정을 만들기 위해 연결이 필요해요. 연결한 뒤 다시 시도해 주세요.'),
          find.text('다시 시도'),
        ],
        find.text(_privacyText),
      ];
      final bounds = <Rect>[];
      final reachable = <bool>[];

      // when
      await tester.pumpWidget(
        _screen(author: author, failure: failure, onRetry: () {}, textScale: 2),
      );
      for (final element in elements) {
        await Scrollable.ensureVisible(tester.element(element), alignment: 0.5);
        await tester.pump();
        bounds.add(tester.getRect(element));
        reachable.add(element.hitTestable().evaluate().isNotEmpty);
      }

      // then
      expect(tester.takeException(), isNull);
      expect(reachable, everyElement(isTrue));
      for (final rect in bounds) {
        expect(rect.left, greaterThanOrEqualTo(-0.01));
        expect(rect.top, greaterThanOrEqualTo(-0.01));
        expect(rect.right, lessThanOrEqualTo(size.width + 0.01));
        expect(rect.bottom, lessThanOrEqualTo(size.height + 0.01));
      }
    });
  }

  for (final (failure, title, message) in [
    (
      SessionFailure.offline,
      '네트워크에 연결되어 있지 않아요',
      '처음 시작할 때는 익명 계정을 만들기 위해 연결이 필요해요. 연결한 뒤 다시 시도해 주세요.',
    ),
    (
      SessionFailure.permissionDenied,
      '프로필을 불러올 수 없어요',
      '잠시 후 다시 시도해 주세요. 문제가 계속되면 앱 관리자에게 알려 주세요.',
    ),
    (
      SessionFailure.configuration,
      '앱을 시작할 수 없어요',
      '앱 연결 설정을 확인한 뒤 다시 시도해 주세요.',
    ),
    (
      SessionFailure.invalidProfile,
      '프로필을 확인할 수 없어요',
      '저장된 정보를 확인할 수 없어요. 문제가 계속되면 앱 관리자에게 알려 주세요.',
    ),
    (SessionFailure.unknown, '앱을 시작하지 못했어요', '잠시 후 다시 시도해 주세요.'),
  ]) {
    testWidgets('${failure.name}에 맞는 오류 안내가 프로필 대신 표시된다', (tester) async {
      // given
      final icon = failure == SessionFailure.offline
          ? Icons.wifi_off
          : Icons.error_outline;

      // when
      await tester.pumpWidget(
        _screen(author: _author, failure: failure, onRetry: () {}),
      );

      // then
      expect(find.text(title), findsOneWidget);
      expect(find.text(message), findsOneWidget);
      expect(find.byIcon(icon), findsOneWidget);
      expect(find.byType(UserAvatar), findsNothing);
      expect(find.text(_author.nickName), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  }

  testWidgets('재시도 버튼을 누르면 전달받은 콜백을 한 번 호출한다', (tester) async {
    // given
    var retries = 0;
    await tester.pumpWidget(
      _screen(failure: SessionFailure.offline, onRetry: () => retries++),
    );

    // when
    await tester.tap(find.text('다시 시도'));
    await tester.pump();

    // then
    expect(retries, 1);
  });

  testWidgets('재시도 콜백이 없으면 버튼이 비활성화된다', (tester) async {
    // given / when
    await tester.pumpWidget(_screen(failure: SessionFailure.offline));

    // then
    expect(tester.widget<TextButton>(find.byType(TextButton)).enabled, isFalse);
  });
}
