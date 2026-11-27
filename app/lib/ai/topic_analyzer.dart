import 'topic_analyzer_unsupported.dart'
    if (dart.library.io) 'topic_analyzer_native.dart';

typedef TopicScore = ({String label, double value});
typedef TopicAnalysis = ({
  List<TopicScore> scores,
  List<String> candidates,
  double threshold,
});

abstract interface class TopicAnalyzer {
  Future<TopicAnalysis> analyze(String input);
  void close();

  static Future<TopicAnalyzer> load() => loadTopicAnalyzer();
}
