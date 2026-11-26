import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minifeed/ai/topic_model.dart';
import 'package:minifeed/ai/topic_tagger.dart';

import 'issue29_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('고정 문장의 벡터·점수·태그와 최초·반복 추론을 확인한다', (_) async {
    final dict = jsonDecode(
      await rootBundle.loadString('assets/ml/features.json'),
    ) as Map;
    final features = List<String>.from(dict['feats'] as List);
    final labels = List<String>.from(dict['labels'] as List);
    final ref = jsonDecode(referenceJson) as Map;
    final load = Stopwatch()..start();
    final model = await TopicModel.load();
    load.stop();
    addTearDown(model.close);
    debugPrint('[#29] load_us=${load.elapsedMicroseconds}');
    for (final c in ref['cases'] as List) {
      final input = buildTopicFeatures(c['body'] as String, features);
      final expected = List<double>.filled(features.length, 0);
      for (final i in c['activePositions'] as List) {
        expected[i as int] = 1;
      }
      expect(input.vector, expected);
      expect(
        extractTopicGrams(c['body'] as String),
        unorderedEquals(c['grams'] as List),
      );
      expect(input.matchedFeatureCount, (c['activePositions'] as List).length);
      final clock = Stopwatch()..start();
      final scores = model.score(input.vector);
      clock.stop();
      expect(scores, [
        for (final n in c['scores'] as List)
          closeTo(n as num, ref['scoreTolerance'] as num),
      ]);
      expect(
        selectTopicTags(
          matchedFeatureCount: input.matchedFeatureCount,
          labels: labels,
          scores: scores,
          threshold: dict['threshold'] as double,
        ),
        c['tags'],
      );
      if (identical(c, (ref['cases'] as List).first)) {
        final times = <int>[];
        for (var i = 0; i < 10; i++) {
          final warm = Stopwatch()..start();
          model.score(input.vector);
          warm.stop();
          times.add(warm.elapsedMicroseconds);
        }
        debugPrint(
          '[#29] zero-vector first_us=${clock.elapsedMicroseconds} repeat_us=$times',
        );
      }
    }
    debugPrint('[#29] fixed cases passed: ${(ref['cases'] as List).length}');
  });
}
