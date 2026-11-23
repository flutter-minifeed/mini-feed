import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minifeed/ai/topic_scores.dart';

void main() {
  const labels = ['일상', '공부', '음식', '운동·건강', '취미', '여행', '연애·가족', '일·알바'];

  Widget panel(List<double> values) => MaterialApp(
    home: Scaffold(
      body: TopicScores(
        result: (
          scores: [
            for (final (i, label) in labels.indexed)
              (label: label, value: values[i]),
          ],
          candidates: const [],
          threshold: 0.3,
        ),
      ),
    ),
  );

  List<double> bars(WidgetTester tester) => [
    for (final bar in tester.widgetList<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    ))
      bar.value!,
  ];

  testWidgets('라벨 순서와 색을 유지하고 변경된 점수만 200ms 동안 함께 전환한다', (tester) async {
    // given
    final initial = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8];
    final updated = [0.9, 0.2, 0.1, 0.4, 0.5, 0.6, 0.7, 0.8];
    await tester.pumpWidget(panel(initial));
    await tester.pumpAndSettle();
    final colors = [
      for (final bar in tester.widgetList<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      ))
        bar.color,
    ];
    expect(colors.toSet(), hasLength(8));
    expect(
      tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .where(labels.contains),
      labels,
    );

    // when
    await tester.pumpWidget(panel(updated));
    await tester.pump(const Duration(milliseconds: 100));
    expect(bars(tester), [
      closeTo(0.5, 0.001),
      0.2,
      closeTo(0.2, 0.001),
      ...initial.skip(3),
    ]);
    await tester.pumpWidget(panel([...updated]));
    await tester.pump(const Duration(milliseconds: 100));

    // then
    expect(bars(tester), updated);
    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.binding.transientCallbackCount, 0);
    expect(
      tester
          .widgetList<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .map((bar) => bar.color),
      colors,
    );
    await tester.pumpWidget(panel([...updated]));
    expect(tester.binding.transientCallbackCount, 0);
  });
}
