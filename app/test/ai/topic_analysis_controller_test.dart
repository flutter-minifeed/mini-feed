import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:minifeed/ai/topic_analysis_controller.dart';
import 'package:minifeed/ai/topic_analyzer.dart';

const _result = (
  candidates: ['일상'],
  scores: [(label: '일상', value: 0.7)],
  threshold: 0.3,
);

class _Analyzer implements TopicAnalyzer {
  final inputs = <String>[];
  final replies = <Completer<TopicAnalysis>>[];
  var closes = 0;

  @override
  Future<TopicAnalysis> analyze(String input) {
    inputs.add(input);
    replies.add(Completer<TopicAnalysis>());
    return replies.last.future;
  }

  @override
  void close() => closes++;
}

void main() {
  late _Analyzer model;
  late TopicAnalysisController controller;
  late int loads;

  setUp(() {
    model = _Analyzer();
    loads = 0;
    controller = TopicAnalysisController(
      loadAnalyzer: () async {
        loads++;
        return model;
      },
    );
  });

  testWidgets('수정한 본문을 마지막 분석 입력으로 되돌리면 같은 결과를 재사용한다', (tester) async {
    // given
    controller.updateInput('여행', keyboardVisible: false);
    await tester.pump();
    model.replies.single.complete(_result);
    await tester.pump();

    // when
    controller.updateInput('여행지', keyboardVisible: true);
    expect(controller.result, isNull);
    controller.updateInput('여행', keyboardVisible: true);
    controller.updateInput('여행', keyboardVisible: false);
    await tester.pump();

    // then
    expect(model.inputs, ['여행']);
    expect(controller.result, _result);
    controller.dispose();
  });

  testWidgets('입력 중에는 대기하고 키보드를 다시 닫아도 같은 입력은 한 번만 분석한다', (tester) async {
    // given
    controller.updateInput('오늘', keyboardVisible: true);
    await tester.pump();
    expect(loads, 0);

    // when
    controller.updateInput('오늘', keyboardVisible: false);
    await tester.pump();
    model.replies.single.complete(_result);
    await tester.pump();
    controller.updateInput('오늘', keyboardVisible: true);
    controller.updateInput('오늘', keyboardVisible: false);
    await tester.pump();

    // then
    expect(model.inputs, ['오늘']);
    expect(controller.result, _result);
    controller.dispose();
    expect(model.closes, 1);
  });

  testWidgets('분석 중 수정하면 같은 모델로 새 입력을 분석하고 뒤늦은 이전 결과를 버린다', (tester) async {
    // given
    controller.updateInput('처음', keyboardVisible: false);
    await tester.pump();
    controller.updateInput('수정', keyboardVisible: true);
    expect(controller.result, isNull);
    expect(controller.status, TopicAnalysisStatus.idle);

    // when
    controller.updateInput('수정', keyboardVisible: false);
    await tester.pump();
    model.replies.last.complete(_result);
    await tester.pump();
    model.replies.first.completeError(StateError('이전 요청 실패'));
    await tester.pump();

    // then
    expect(loads, 1);
    expect(model.inputs, ['처음', '수정']);
    expect(controller.status, TopicAnalysisStatus.ready);
    expect(controller.result, _result);
    controller.updateInput('  ', keyboardVisible: false);
    expect(controller.result, isNull);
    expect(controller.status, TopicAnalysisStatus.idle);
    controller.dispose();
  });

  testWidgets('5초가 지나면 늦은 결과를 무시하고 닫힌 상태의 입력 변경도 분석한다', (tester) async {
    // given
    controller.updateInput('게임', keyboardVisible: false);
    await tester.pump();

    // when
    await tester.pump(const Duration(seconds: 5));
    model.replies.first.complete(_result);
    await tester.pump();

    // then
    expect(controller.status, TopicAnalysisStatus.timedOut);
    expect(controller.result, isNull);
    controller.updateInput('게임 여행', keyboardVisible: false);
    await tester.pump();
    expect(model.inputs, ['게임', '게임 여행']);
    model.replies.last.completeError(StateError('추론 실패'));
    await tester.pump();
    expect(controller.status, TopicAnalysisStatus.failed);
    controller.dispose();
  });

  testWidgets('모델 준비 실패 후 입력을 바꾸면 다시 로드하고 화면 종료 뒤 결과를 버린다', (tester) async {
    // given
    var attempts = 0;
    final retry = TopicAnalysisController(
      loadAnalyzer: () async {
        if (++attempts == 1) throw StateError('로드 실패');
        return model;
      },
    );
    retry.updateInput('처음', keyboardVisible: false);
    await tester.pump();
    expect(retry.status, TopicAnalysisStatus.failed);

    // when
    retry.updateInput('다음', keyboardVisible: false);
    await tester.pump();
    retry.dispose();
    model.replies.single.complete(_result);
    await tester.pump(const Duration(seconds: 6));

    // then
    expect(model.inputs, ['다음']);
    expect(model.closes, 1);
    expect(retry.result, isNull);
    controller.dispose();
  });

  testWidgets('화면을 닫은 뒤 로드가 끝나면 추론 없이 모델을 한 번 해제한다', (tester) async {
    // given
    final loading = Completer<TopicAnalyzer>();
    final pending = TopicAnalysisController(loadAnalyzer: () => loading.future);
    pending.updateInput('게임', keyboardVisible: false);

    // when
    pending.dispose();
    loading.complete(model);
    await tester.pump(const Duration(seconds: 6));

    // then
    expect(model.inputs, isEmpty);
    expect(model.closes, 1);
    controller.dispose();
  });
}
