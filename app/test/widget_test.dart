import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:minifeed/main.dart';

void main() {
  testWidgets('앱이 피드 화면으로 시작한다', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('미니피드'), findsOneWidget);
  });

  testWidgets('상세는 뒤로가기 화살표, 글쓰기는 X로 닫힌다', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('상세 열기'));
    await tester.pumpAndSettle();
    expect(find.text('상세'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('미니피드'), findsOneWidget);

    await tester.tap(find.text('글쓰기 열기'));
    await tester.pumpAndSettle();
    expect(find.text('글쓰기'), findsOneWidget);
    expect(find.byType(CloseButton), findsOneWidget);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.text('미니피드'), findsOneWidget);
  });
}
