import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minifeed/ai/topic_model.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('빈 특징 벡터를 넣으면 사전 라벨 8개에 대응하는 점수가 나온다', (tester) async {
    // given
    final dictionary = jsonDecode(
      await rootBundle.loadString('assets/ml/features.json'),
    ) as Map<String, dynamic>;
    final feats = dictionary['feats'] as List<dynamic>;
    final labels = (dictionary['labels'] as List<dynamic>).cast<String>();
    final model = await TopicModel.load();
    debugPrint('[#26] input ${model.input.type} ${model.input.shape}');
    debugPrint('[#26] output ${model.output.type} ${model.output.shape}');
    debugPrint('[#26] feats ${feats.length}, labels $labels');

    // when
    final scores = model.score(List.filled(feats.length, 0));
    model.close();
    debugPrint(
      '[#26] scores ${[for (var i = 0; i < labels.length; i++) '${labels[i]}=${scores[i].toStringAsFixed(4)}']}',
    );
    debugPrint('[#26] closed');

    // then
    expect(model.input.type, TensorType.float32);
    expect(model.input.shape, [1, feats.length]);
    expect(model.output.type, TensorType.float32);
    expect(model.output.shape, [1, labels.length]);
    expect(scores, hasLength(8));
    // ml/README.md: 사전에 있는 조각이 없으면 편향값만으로 음식 0.42가 나온다.
    expect(scores[labels.indexOf('음식')], closeTo(0.42, 0.01));
  });
}
