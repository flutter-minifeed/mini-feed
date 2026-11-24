import 'topic_tagger.dart';

/// 게시용 원문은 보존하고 분석에 사용할 본문과 직접 입력 태그만 결합한다.
String buildTopicAnalysisInput(
  String body, {
  required Iterable<String> manualTags,
}) {
  final normalizedBody = normalizeTopicText(body);
  final tags = <String>{};
  for (final rawTag in manualTags) {
    final normalized = normalizeTopicText(rawTag);
    final tag = normalized.replaceFirst(RegExp(r'^#+ *'), '');
    if (tag.isNotEmpty) tags.add(tag);
  }
  return [if (normalizedBody.isNotEmpty) normalizedBody, ...tags].join(' ');
}
