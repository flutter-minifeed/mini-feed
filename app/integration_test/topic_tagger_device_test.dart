import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minifeed/ai/topic_analyzer.dart';
import 'package:minifeed/ai/topic_model.dart';
import 'package:minifeed/ai/topic_tagger.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('실기기의 특징 벡터와 모델 점수, 추천 태그가 Python 기준과 일치한다', _compareWithPython);
  testWidgets('작성 화면용 모델을 재사용해도 Python 기준의 8개 점수와 후보가 나온다', (tester) async {
    // given
    final fixture = _readPythonFixture();
    final dictionary = await _loadDictionary();
    final clock = Stopwatch()..start();
    final analyzer = await TopicAnalyzer.load();
    addTearDown(analyzer.close);

    for (final example in fixture.cases) {
      // when
      final result = await analyzer.analyze(example['body'] as String);
      debugPrint('기기 내 주제 분석 ${clock.elapsedMilliseconds}ms');

      // then
      expect(result.scores.map((score) => score.label), dictionary.labels);
      expect(result.scores.map((score) => score.value), [
        for (final score in (example['scores'] as List).cast<num>())
          closeTo(score, fixture.scoreTolerance),
      ]);
      expect(result.candidates, example['tags']);
      clock.reset();
    }
  });
}

Future<void> _compareWithPython(WidgetTester _) async {
  // given
  final fixture = _readPythonFixture();
  final dictionary = await _loadDictionary();
  final model = await TopicModel.load();
  addTearDown(model.close);

  // when, then
  for (final example in fixture.cases) {
    _expectPythonResult(example, model, dictionary, fixture.scoreTolerance);
  }
}

void _expectPythonResult(
  Map<String, dynamic> example,
  TopicModel model,
  _TopicDictionary dictionary,
  double tolerance,
) {
  // given
  final body = example['body'] as String;
  final activePositions = (example['activePositions'] as List).cast<int>();
  final expectedVector = _expectedVector(
    dictionary.features.length,
    activePositions,
  );
  final expectedScores = (example['scores'] as List).cast<num>();

  // when
  final grams = extractTopicGrams(body);
  final features = buildTopicFeatures(body, dictionary.features);
  final scores = model.score(features.vector);
  final tags = selectTopicTags(
    matchedFeatureCount: features.matchedFeatureCount,
    labels: dictionary.labels,
    scores: scores,
    threshold: dictionary.threshold,
  );

  // then
  expect(grams, unorderedEquals(example['grams'] as List), reason: body);
  expect(features.matchedFeatureCount, activePositions.length, reason: body);
  expect(features.vector, expectedVector, reason: body);
  expect(scores, [
    for (final score in expectedScores) closeTo(score, tolerance),
  ], reason: '$body 점수 비교 · 라벨 순서 ${dictionary.labels.join(', ')}');
  expect(tags, example['tags'], reason: body);
}

List<double> _expectedVector(int length, List<int> activePositions) {
  final vector = List<double>.filled(length, 0.0);
  for (final position in activePositions) {
    vector[position] = 1.0;
  }
  return vector;
}

({List<Map<String, dynamic>> cases, double scoreTolerance})
_readPythonFixture() {
  const encodedFixture = String.fromEnvironment('TOPIC_TAGGER_CASES');
  expect(encodedFixture, isNotEmpty, reason: '실행할 때 기준 JSON을 전달해 주세요.');

  final fixture = jsonDecode(
    utf8.decode(base64Decode(encodedFixture)),
  ) as Map<String, dynamic>;
  return (
    cases: (fixture['cases'] as List).cast<Map<String, dynamic>>(),
    scoreTolerance: (fixture['scoreTolerance'] as num).toDouble(),
  );
}

typedef _TopicDictionary = ({
  List<String> features,
  List<String> labels,
  double threshold,
});

Future<_TopicDictionary> _loadDictionary() async {
  final dictionary = jsonDecode(
    await rootBundle.loadString('assets/ml/features.json'),
  ) as Map<String, dynamic>;
  return (
    features: (dictionary['feats'] as List).cast<String>(),
    labels: (dictionary['labels'] as List).cast<String>(),
    threshold: (dictionary['threshold'] as num).toDouble(),
  );
}
