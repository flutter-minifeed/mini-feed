import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minifeed/repository/repository_scope.dart';
import 'package:minifeed/screens/write_screen.dart';

import '../helpers/test_app.dart';

// 빈 화면 위에 글쓰기 화면을 fullscreenDialog로 엽니다. 피드에서 여는 방식과 같아서 X 버튼도 똑같이 생깁니다.
Future<FakePostRepository> pumpWriteScreen(WidgetTester tester) async {
  final postRepository = FakePostRepository();
  final commentRepository = FakeCommentRepository();
  // 피드처럼 빈 화면 위에 글쓰기를 띄워야 게시 후 닫히는지 확인할 수 있다.
  // navigatorKey: 테스트 코드에서 context 없이 앱의 Navigator를 꺼내 쓰기 위한 열쇠.
  final navigatorKey = GlobalKey<NavigatorState>();

  await tester.pumpWidget(
    RepositoryScope(
      postRepository: postRepository,
      commentRepository: commentRepository,
      child: MaterialApp(navigatorKey: navigatorKey, home: const Scaffold()),
    ),
  );

  // 빈 화면(home) 위에 글쓰기 화면을 한 장 쌓는다. 피드의 '글쓰기 열기'와 같은 방식이다.
  // currentState: navigatorKey가 연결된 Navigator. pumpWidget 뒤라 null이 아니어서 !를 붙인다.
  navigatorKey.currentState!.push(
    MaterialPageRoute<void>(
      // 아래에서 위로 올라오는 전체 화면 창으로 열고, AppBar 왼쪽에 X 버튼이 생긴다.
      fullscreenDialog: true,
      builder: (_) => const WriteScreen(),
    ),
  );
  // 화면 전환 애니메이션이 끝날 때까지 그려야 글쓰기 화면을 찾을 수 있다.
  await tester.pumpAndSettle();

  return postRepository;
}

void main() {
  testWidgets('본문이 비어 있으면 게시할 수 없다', (tester) async {
    // when
    await pumpWriteScreen(tester);

    // then
    expect(_canPost(tester), isFalse);
  });

  testWidgets('공백 및 줄바꿈만 입력하면 게시할 수 없습니다', (tester) async {
    // given
    await pumpWriteScreen(tester);

    // when
    await tester.enterText(find.byType(TextField), '  \n\n  ');
    await tester.pump();

    // then
    expect(_canPost(tester), isFalse);
  });

  testWidgets('한글 299자에서는 카운터가 기본색이어야 한다', (tester) async {
    // given
    await pumpWriteScreen(tester);

    // when
    await tester.enterText(find.byType(TextField), '가' * 299);
    await tester.pump();

    // then
    expect(_counterColor(tester, '299 / 300'), isNot(_errorColor(tester)));
  });

  testWidgets('글자를 입력하면 게시가 가능합니다', (tester) async {
    // given
    await pumpWriteScreen(tester);

    // when
    await tester.enterText(find.byType(TextField), '  안녕\n');
    await tester.pump();

    // then
    expect(_canPost(tester), isTrue);
  });

  testWidgets('한글 300자가 되면 카운터가 강조된다', (tester) async {
    // given
    await pumpWriteScreen(tester);

    // when
    await tester.enterText(find.byType(TextField), '가' * 300);
    await tester.pump();

    // then
    expect(_counterColor(tester, '300 / 300'), _errorColor(tester));
  });

  testWidgets('한글 301자를 붙여넣으면 300자까지만 남는다', (tester) async {
    // given
    await pumpWriteScreen(tester);

    // when
    await tester.enterText(find.byType(TextField), '가' * 301);
    await tester.pump();

    // then
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '가' * 300);
    expect(find.text('300 / 300'), findsOneWidget);
  });

  testWidgets('iOS에서 한글 조합 중 301자가 되면 게시할 수 없다', (tester) async {
    // given
    await pumpWriteScreen(tester);
    await tester.showKeyboard(find.byType(TextField));

    // when: 301번째 글자를 아직 조합 중인 상태
    // iOS는 조합이 끝날 때까지 maxLength를 넘는 입력을 허용한다.
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: '가' * 301,
        selection: const TextSelection.collapsed(offset: 301),
        composing: const TextRange(start: 300, end: 301),
      ),
    );
    await tester.pump();

    // then
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, hasLength(301));
    expect(_canPost(tester), isFalse);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('게시하면 앞뒤 공백만 지운 본문이 저장되고 화면이 닫힌다', (tester) async {
    // given
    final repository = await pumpWriteScreen(tester);
    await tester.enterText(find.byType(TextField), '  첫 줄\n\n둘째 줄  ');
    await tester.pump();

    // when
    await tester.tap(_postButton);
    await tester.pumpAndSettle();

    // then
    expect(repository.addedBodies, ['첫 줄\n\n둘째 줄']);
    expect(find.byType(WriteScreen), findsNothing);
  });

  testWidgets('게시 중에는 다시 눌러도 한 번만 저장한다', (tester) async {
    // given: 저장이 끝나지 않고 멈춰 있는 상태
    final repository = await pumpWriteScreen(tester);
    repository.addGate = Completer<void>();
    await tester.enterText(find.byType(TextField), '안녕');
    await tester.pump();

    // when
    await tester.tap(_postButton);
    await tester.pump();
    await tester.tap(_postButton);
    await tester.pump();

    // then
    expect(repository.addedBodies, hasLength(1));
    expect(_canPost(tester), isFalse);
    expect(find.text('게시 중…'), findsOneWidget);

    // 저장이 끝나면 화면이 닫힌다.
    repository.addGate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(WriteScreen), findsNothing);
  });

  testWidgets('게시 중에는 X를 눌러도 닫히지 않는다', (tester) async {
    // given: 저장이 끝나지 않고 멈춰 있는 상태
    final repository = await pumpWriteScreen(tester);
    repository.addGate = Completer<void>();
    await tester.enterText(find.byType(TextField), '안녕');
    await tester.pump();
    await tester.tap(_postButton);
    await tester.pump();

    // when
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    // then
    expect(find.byType(WriteScreen), findsOneWidget);

    repository.addGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('공백만 있는 본문은 X를 누르면 확인 없이 닫힌다', (tester) async {
    // given
    await pumpWriteScreen(tester);
    await tester.enterText(find.byType(TextField), '  \n ');
    await tester.pump();

    // when
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    // then
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(WriteScreen), findsNothing);
  });

  testWidgets('본문이 있으면 X를 눌렀을 때 계속 쓰기를 고르면 입력이 남는다', (tester) async {
    // given
    await pumpWriteScreen(tester);
    await tester.enterText(find.byType(TextField), '쓰던 글');
    await tester.pump();

    // when
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('계속 쓰기'));
    await tester.pumpAndSettle();

    // then
    expect(find.byType(WriteScreen), findsOneWidget);
    expect(find.text('쓰던 글'), findsOneWidget);
  });

  testWidgets('본문이 있으면 X를 눌렀을 때 버리기를 고르면 닫힌다', (tester) async {
    // given
    final repository = await pumpWriteScreen(tester);
    await tester.enterText(find.byType(TextField), '쓰던 글');
    await tester.pump();

    // when
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('버리기'));
    await tester.pumpAndSettle();

    // then
    expect(find.byType(WriteScreen), findsNothing);
    expect(repository.addedBodies, isEmpty);
  });

  testWidgets('본문이 있으면 Android 뒤로가기도 확인 창을 띄운다', (tester) async {
    // given
    await pumpWriteScreen(tester);
    await tester.enterText(find.byType(TextField), '쓰던 글');
    await tester.pump();

    // when: 시스템 뒤로가기 신호를 보낸다.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    // then
    expect(find.text('작성 중인 글을 버릴까요?'), findsOneWidget);
    expect(find.byType(WriteScreen), findsOneWidget);
  });
}

// 상단 바의 게시 버튼을 찾는 조건. FilledButton.icon은 FilledButton의 하위 클래스라
// byType(정확한 타입 비교)으로는 찾지 못해 is로 찾는다.
final _postButton = find.byWidgetPredicate((widget) => widget is FilledButton);

/// '게시' 버튼이 눌리는 상태인지 확인한다.
bool _canPost(WidgetTester tester) {
  // 조건에 맞는 실제 버튼 위젯을 꺼낸다.
  final button = tester.widget<FilledButton>(_postButton);

  // onPressed가 null이면 Flutter가 버튼을 비활성(회색)으로 그린다.
  return button.onPressed != null;
}

/// 카운터 글자(예: '300 / 300')의 색을 꺼낸다.
Color? _counterColor(WidgetTester tester, String counter) {
  final counterText = tester.widget<Text>(find.text(counter));

  return counterText.style?.color;
}

/// 글쓰기 화면이 쓰는 테마의 강조(error) 색을 꺼낸다.
Color _errorColor(WidgetTester tester) {
  // 화면 위젯이 놓인 위치(BuildContext)를 찾는다.
  final context = tester.element(find.byType(WriteScreen));

  return Theme.of(context).colorScheme.error;
}
