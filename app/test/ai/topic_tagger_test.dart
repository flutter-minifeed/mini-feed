import 'package:flutter_test/flutter_test.dart';
import 'package:minifeed/ai/topic_tagger.dart';

void main() {
  group('extractTopicGrams', () {
    test('영문을 소문자로 바꾸고 줄바꿈과 연속 공백을 한 칸으로 합친다', () {
      // given
      const body = '  A한\n  😀B  ';

      // when
      final grams = extractTopicGrams(body);

      // then
      expect(grams, {'a한', '한 ', ' 😀', '😀b'});
    });

    test('같은 조각이 반복되면 한 번만 반환한다', () {
      // when, then
      expect(extractTopicGrams('ㅋㅋㅋ'), {'ㅋㅋ'});
    });

    test('공백을 정리한 뒤 한 글자만 남으면 그 글자를 반환한다', () {
      // when, then
      expect(extractTopicGrams(' 😀 '), {'😀'});
    });

    test('공백만 있으면 빈 집합을 반환한다', () {
      // when, then
      expect(extractTopicGrams(' \t\n '), isEmpty);
    });
  });

  group('buildTopicFeatures', () {
    test('사전 순서대로 값을 채우고 반복된 조각은 한 번만 센다', () {
      // given
      const dictionary = ['나가', '다라', '가나', '마바'];
      const body = '가나가나별';

      // when
      final features = buildTopicFeatures(body, dictionary);

      // then
      expect(features.vector, [1.0, 0.0, 1.0, 0.0]);
      expect(features.matchedFeatureCount, 2);
    });

    test('본문의 조각이 사전에 하나도 없으면 모든 값과 개수가 0이다', () {
      // given
      const dictionary = ['가나', '나가'];

      // when
      final features = buildTopicFeatures('ㅋㅋㅋ', dictionary);

      // then
      expect(features.vector, [0.0, 0.0]);
      expect(features.matchedFeatureCount, 0);
    });
  });

  group('selectTopicTags', () {
    const labels = ['일상', '공부', '음식', '여행'];
    const cases = [
      (
        name: '일치한 특징이 없으면 점수가 높아도 추천을 비운다',
        matched: 0,
        scores: [0.9, 0.8, 0.7, 0.6],
        tags: <String>[],
      ),
      (
        name: '기준값에 도달한 후보가 없으면 추천을 비운다',
        matched: 1,
        scores: [0.2999, 0.2, 0.1, 0.0],
        tags: <String>[],
      ),
      (
        name: '기준값과 같은 후보 하나를 추천한다',
        matched: 1,
        scores: [0.2999, 0.3, 0.1, 0.0],
        tags: ['공부'],
      ),
      (
        name: '후보가 세 개면 높은 점수부터 모두 추천한다',
        matched: 1,
        scores: [0.3, 0.2999, 0.3001, 0.8],
        tags: ['여행', '음식', '일상'],
      ),
      (
        name: '후보 네 개 중 공동 3위는 원래 순서가 앞선 라벨을 고른다',
        matched: 1,
        scores: [0.3, 0.9, 0.8, 0.3],
        tags: ['공부', '음식', '일상'],
      ),
    ];

    for (final example in cases) {
      test(example.name, () {
        // given
        const threshold = 0.3;

        // when
        final tags = selectTopicTags(
          matchedFeatureCount: example.matched,
          labels: labels,
          scores: example.scores,
          threshold: threshold,
        );

        // then
        expect(tags, example.tags);
      });
    }
  });
}
