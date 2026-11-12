import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minifeed/repository/repository_scope.dart';
import 'package:minifeed/screens/write_screen.dart';

import '../helpers/test_app.dart';

// 피드의 임시 '글쓰기 열기' 버튼은 #7에서 바뀌므로 글쓰기 화면을 바로 띄운다.
// 다음 커밋에서 addedBodies를 검사하려고 가짜 저장소 타입 그대로 돌려준다.
Future<FakePostRepository> pumpWriteScreen(WidgetTester tester) async {
  final postRepository = FakePostRepository();
  final commentRepository = FakeCommentRepository();
  await tester.pumpWidget(
    RepositoryScope(
      postRepository: postRepository,
      commentRepository: commentRepository,
      child: const MaterialApp(home: WriteScreen()),
    ),
  );

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
    expect(_counterColor(tester, '299/300'), isNot(_errorColor(tester)));
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
    expect(_counterColor(tester, '300/300'), _errorColor(tester));
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
    expect(find.text('300/300'), findsOneWidget);
  });
}

// 화면에서 '게시' 텍스트를 가진 TextButton을 찾는 조건
final _postButton = find.widgetWithText(TextButton, '게시');

/// '게시' 버튼이 눌리는 상태인지 확인한다.
bool _canPost(WidgetTester tester) {
  // 조건에 맞는 실제 버튼 위젯을 꺼낸다.
  final button = tester.widget<TextButton>(_postButton);

  // onPressed가 null이면 Flutter가 버튼을 비활성(회색)으로 그린다.
  return button.onPressed != null;
}

/// 카운터 글자(예: '300/300')의 색을 꺼낸다.
Color? _counterColor(WidgetTester tester, String counter) {
  final counterText = tester.widget<Text>(find.text(counter));

  // 기본색일 때는 style을 null로 뒀으므로 색도 null이 된다.
  return counterText.style?.color;
}

/// 글쓰기 화면이 쓰는 테마의 강조(error) 색을 꺼낸다.
Color _errorColor(WidgetTester tester) {
  // 화면 위젯이 놓인 위치(BuildContext)를 찾는다.
  final context = tester.element(find.byType(WriteScreen));

  return Theme.of(context).colorScheme.error;
}
