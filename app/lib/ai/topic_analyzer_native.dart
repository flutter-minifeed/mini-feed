import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:minifeed/ai/topic_analyzer.dart';
import 'package:minifeed/ai/topic_model.dart';
import 'package:minifeed/ai/topic_tagger.dart';

Future<TopicAnalyzer> loadTopicAnalyzer() async {
  final dictionary = await rootBundle.loadString('assets/ml/features.json');
  final bytes = await rootBundle.load(TopicModel.assetPath);
  final ready = ReceivePort();
  try {
    await Isolate.spawn(_runModel, (
      dictionary: dictionary,
      bytes: Uint8List.sublistView(bytes),
      ready: ready.sendPort,
    ));
    final reply = await ready.first;
    if (reply is! SendPort) throw StateError('주제 모델을 준비하지 못했어요.');
    return _LocalTopicAnalyzer(reply);
  } finally {
    ready.close();
  }
}

class _LocalTopicAnalyzer implements TopicAnalyzer {
  const _LocalTopicAnalyzer(this._requests);

  final SendPort _requests;

  @override
  Future<TopicAnalysis> analyze(String input) async {
    final reply = ReceivePort();
    try {
      _requests.send((input, reply.sendPort));
      final result = await reply.first;
      if (result is! TopicAnalysis) throw StateError('주제 점수를 계산하지 못했어요.');
      return result;
    } finally {
      reply.close();
    }
  }

  @override
  void close() => _requests.send(null);
}

// 모델을 생성한 isolate에서 순서대로 실행하고 마지막 추론이 끝난 뒤 해제한다.
Future<void> _runModel(
  ({String dictionary, Uint8List bytes, SendPort ready}) assets,
) async {
  final requests = ReceivePort();
  TopicModel? model;
  try {
    final dictionary = jsonDecode(assets.dictionary) as Map<String, dynamic>;
    final features = (dictionary['feats'] as List).cast<String>();
    final labels = (dictionary['labels'] as List).cast<String>();
    final threshold = (dictionary['threshold'] as num).toDouble();
    model = TopicModel.fromBuffer(assets.bytes);
    assets.ready.send(requests.sendPort);
    await for (final request in requests) {
      if (request == null) break;
      final (input, reply) = request as (String, SendPort);
      try {
        final encoded = buildTopicFeatures(input, features);
        final scores = model.score(encoded.vector);
        final candidates = selectTopicTags(
          matchedFeatureCount: encoded.matchedFeatureCount,
          labels: labels,
          scores: scores,
          threshold: threshold,
        );
        reply.send((
          scores: [
            for (var i = 0; i < labels.length; i++)
              (label: labels[i], value: scores[i]),
          ],
          candidates: candidates,
          threshold: threshold,
        ));
      } catch (_) {
        reply.send(null);
      }
    }
  } catch (_) {
    assets.ready.send(null);
  } finally {
    requests.close();
    model?.close();
  }
}
