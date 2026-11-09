import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:minifeed/screens/detail_screen.dart';

import '../test_repositories.dart';

void main() {
  testWidgets('게시글 ID로 열면 같은 글의 닉네임·본문·개수와 댓글이 보인다', (tester) async {
    // when
    await _openDetail(tester);

    // then
    expect(find.text('졸린 판다'), findsOneWidget);
    expect(find.text('테스트 본문'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // 좋아요 수
    expect(find.text('댓글 1'), findsOneWidget);
    expect(find.text('낮잠 자는 물개'), findsOneWidget);
    expect(find.text('테스트 댓글'), findsOneWidget);
  });

  testWidgets('카드 본문으로 열면 댓글 입력창에 포커스가 가지 않는다', (tester) async {
    // when
    await _openDetail(tester);

    // then
    expect(_commentField(tester).focusNode!.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('댓글 아이콘으로 열면 댓글 입력창에 포커스가 가고 키보드가 열린다', (tester) async {
    // when
    await _openDetail(tester, focusComment: true);

    // then
    expect(_commentField(tester).focusNode!.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('키보드만 내린 뒤 댓글 버튼을 누르면 키보드가 다시 열린다', (tester) async {
    // given: 댓글 아이콘으로 열고 Android 뒤로가기로 키보드만 내린 상태
    await _openDetail(tester, focusComment: true);
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    expect(tester.testTextInput.isVisible, isFalse);

    // when
    await tester.tap(find.byIcon(Icons.chat_bubble_outline));
    await tester.pump();

    // then
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('없는 게시글 ID로 열면 안내 문구만 보인다', (tester) async {
    // when
    await _openDetail(tester, postId: 'post-none');

    // then
    expect(find.text('삭제되었거나 없는 게시글이에요.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('댓글을 공백만 입력하면 전송 버튼이 꺼져 있다', (tester) async {
    // given
    await _openDetail(tester);

    // when
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();

    // then
    expect(_sendButton(tester).onPressed, isNull);
  });

  testWidgets('댓글에 글자를 입력하면 전송 버튼이 켜진다', (tester) async {
    // given
    await _openDetail(tester);

    // when
    await tester.enterText(find.byType(TextField), '안녕');
    await tester.pump();

    // then
    expect(_sendButton(tester).onPressed, isNotNull);
  });

  testWidgets('iOS에서 한글 조합 중 201자가 되면 댓글을 보낼 수 없다', (tester) async {
    // given
    await _openDetail(tester);
    await tester.showKeyboard(find.byType(TextField));

    // when: 201번째 글자를 아직 조합 중인 상태
    // iOS는 조합이 끝날 때까지 maxLength를 넘는 입력을 허용한다.
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: '가' * 201,
        selection: const TextSelection.collapsed(offset: 201),
        composing: const TextRange(start: 200, end: 201),
      ),
    );
    await tester.pump();

    // then
    expect(_commentField(tester).controller!.text, hasLength(201));
    expect(_sendButton(tester).onPressed, isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}

// 테스트용 저장소 위에 상세 화면만 띄우고, 글을 다 불러올 때까지 기다린다.
Future<void> _openDetail(
  WidgetTester tester, {
  String postId = testPostId,
  bool focusComment = false,
}) async {
  await tester.pumpWidget(
    withTestRepositories(
      MaterialApp(
        home: DetailScreen(postId: postId, focusComment: focusComment),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

TextField _commentField(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField));

IconButton _sendButton(WidgetTester tester) =>
    tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send));
