import 'package:tflite_flutter/tflite_flutter.dart';

typedef TensorSpec = ({TensorType type, List<int> shape});

class TopicModel {
  TopicModel._(Interpreter interpreter)
    : _interpreter = interpreter,
      input = _specOf(interpreter.getInputTensor(0)),
      output = _specOf(interpreter.getOutputTensor(0));

  static const assetPath = 'assets/ml/best.tflite';

  final Interpreter _interpreter;

  // Tensor는 네이티브 메모리를 직접 읽어서 close() 뒤에는 shape가 깨진다. 로드할 때 값으로 복사해 둔다.
  final TensorSpec input;

  final TensorSpec output;

  static Future<TopicModel> load() async =>
      TopicModel._(await Interpreter.fromAsset(assetPath));

  static TensorSpec _specOf(Tensor tensor) =>
      (type: tensor.type, shape: List.unmodifiable(tensor.shape));

  List<double> score(List<double> features) {
    final scores = [List<double>.filled(output.shape.last, 0)];
    _interpreter.run([features], scores);
    return scores.first;
  }

  void close() => _interpreter.close();
}
