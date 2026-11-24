import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:minifeed/ai/topic_analysis_input.dart';
import 'package:minifeed/ai/topic_tagger.dart';

void main() {
  test('태그 앞의 #과 공백을 정리하고 같은 직접 태그의 첫 입력 순서를 유지한다', () {
    // given
    const tags = [' #제주여행 ', '게임', '제주여행', ' ## ', '#Game', 'game'];

    // when, then
    expect(
      buildTopicAnalysisInput('본문 #해시', manualTags: tags),
      '본문 #해시 제주여행 게임 game',
    );
  });

  test('마지막 직접 태그를 제거하면 본문만 있을 때의 입력으로 돌아간다', () {
    // given
    final tags = ['제주여행'];
    final combined = buildTopicAnalysisInput('게임', manualTags: tags);

    // when
    tags.clear();

    // then
    expect(combined, '게임 제주여행');
    expect(buildTopicAnalysisInput('게임', manualTags: tags), '게임');
  });

  final fixture = jsonDecode(
    File('test/fixtures/topic_input_cases.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final dictionary = jsonDecode(
    File('assets/ml/features.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  for (final example
      in (fixture['cases'] as List).cast<Map<String, dynamic>>()) {
    test(
      'Python 기준 입력·벡터·추천과 일치한다 (${example['body']}, ${example['manualTags']})',
      () {
        // given
        final manualTags = (example['manualTags'] as List).cast<String>();

        // when
        final input = buildTopicAnalysisInput(
          example['body'] as String,
          manualTags: manualTags,
        );
        final features = buildTopicFeatures(
          input,
          (dictionary['feats'] as List).cast<String>(),
        );
        final activePositions = [
          for (var i = 0; i < features.vector.length; i++)
            if (features.vector[i] == 1) i,
        ];

        // then
        expect(input, example['input']);
        expect(
          extractTopicGrams(input),
          unorderedEquals(example['grams'] as List),
        );
        expect(activePositions, example['activePositions']);
        expect(
          selectTopicTags(
            matchedFeatureCount: features.matchedFeatureCount,
            labels: (dictionary['labels'] as List).cast<String>(),
            scores: (example['scores'] as List).cast<double>(),
            threshold: (dictionary['threshold'] as num).toDouble(),
          ),
          example['tags'],
        );
      },
    );
  }
}
