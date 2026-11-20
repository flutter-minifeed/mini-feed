// Python의 \s는 유니코드 구분 문자와 아래 제어 문자를 공백으로 취급한다.
final _pythonWhitespace = RegExp(
  r'[\p{Z}\u0009-\u000D\u001C-\u001F\u0085]+',
  unicode: true,
);

Set<String> extractTopicGrams(String body) {
  final normalized = body
      .toLowerCase()
      .split(_pythonWhitespace)
      .where((word) => word.isNotEmpty)
      .join(' ');

  final codePoints = normalized.runes.toList();
  if (codePoints.length == 1) {
    return {normalized};
  }

  return {
    for (var i = 0; i < codePoints.length - 1; i++)
      String.fromCharCodes([codePoints[i], codePoints[i + 1]]),
  };
}

typedef TopicFeatures = ({List<double> vector, int matchedFeatureCount});

TopicFeatures buildTopicFeatures(String body, List<String> featureDictionary) {
  final grams = extractTopicGrams(body);
  final vector = List<double>.filled(featureDictionary.length, 0.0);
  var matchedFeatureCount = 0;

  for (var i = 0; i < featureDictionary.length; i++) {
    if (grams.contains(featureDictionary[i])) {
      vector[i] = 1.0;
      matchedFeatureCount++;
    }
  }

  return (vector: vector, matchedFeatureCount: matchedFeatureCount);
}

List<String> selectTopicTags({
  required int matchedFeatureCount,
  required List<String> labels,
  required List<double> scores,
  required double threshold,
}) {
  if (matchedFeatureCount == 0) {
    return [];
  }
  if (scores.length != labels.length) {
    throw ArgumentError('점수 개수와 라벨 개수가 일치해야 합니다.');
  }

  final labelPositions = [
    for (var i = 0; i < scores.length; i++)
      if (scores[i] >= threshold) i,
  ];

  labelPositions.sort((a, b) {
    final byScore = scores[b].compareTo(scores[a]);
    if (byScore != 0) return byScore;
    return a.compareTo(b);
  });

  return [for (final position in labelPositions.take(3)) labels[position]];
}
