import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:minifeed/main.dart';

void main() {
  testWidgets('앱을 켜면 피드 화면이 보인다', (tester) async {
    // when
    await tester.pumpWidget(const MyApp());

    // then
    expect(find.text('미니피드'), findsOneWidget);
  });

  testWidgets('상세 화면에서 화살표를 누르면 피드로 돌아온다', (tester) async {
    // given: 피드에서 상세로 들어간 상태
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('상세 열기'));
    await tester.pumpAndSettle();
    expect(find.text('상세'), findsOneWidget);

    // when
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // then
    expect(find.text('미니피드'), findsOneWidget);
  });

  testWidgets('글쓰기 화면에서 X를 누르면 피드로 돌아온다', (tester) async {
    // given: 피드에서 글쓰기로 들어간 상태
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('글쓰기 열기'));
    await tester.pumpAndSettle();
    expect(find.text('글쓰기'), findsOneWidget);

    // when
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    // then
    expect(find.text('미니피드'), findsOneWidget);
  });
}
