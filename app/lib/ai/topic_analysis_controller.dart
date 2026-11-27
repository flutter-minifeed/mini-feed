import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:minifeed/ai/topic_analyzer.dart';

enum TopicAnalysisStatus { idle, analyzing, ready, failed, timedOut }

class TopicAnalysisController extends ChangeNotifier {
  TopicAnalysisController({this.loadAnalyzer = TopicAnalyzer.load});

  final Future<TopicAnalyzer> Function() loadAnalyzer;
  Future<TopicAnalyzer>? _loading;
  TopicAnalyzer? _analyzer;
  Timer? _deadline;
  int _revision = 0;
  String _input = '';
  bool _disposed = false;

  TopicAnalysisStatus _status = TopicAnalysisStatus.idle;
  TopicAnalysisStatus get status => _status;
  String? _completedInput;
  TopicAnalysis? _lastResult;
  TopicAnalysis? get lastResult => _lastResult;
  TopicAnalysis? get result =>
      _status == TopicAnalysisStatus.ready ? _lastResult : null;

  /// 호출자는 분석할 문자열을 완성해 전달한다. 키보드가 닫혀 있으면 변경 즉시 분석한다.
  void updateInput(String input, {required bool keyboardVisible}) {
    if (_disposed) return;
    final changed = input != _input;
    if (changed) {
      _input = input;
      _revision++;
      _deadline?.cancel();
      _status = TopicAnalysisStatus.idle;
    }
    if (_status == TopicAnalysisStatus.idle &&
        !keyboardVisible &&
        input.trim().isNotEmpty) {
      if (input == _completedInput) {
        _status = TopicAnalysisStatus.ready;
        notifyListeners();
        return;
      }
      _status = TopicAnalysisStatus.analyzing;
      final revision = _revision;
      _deadline = Timer(const Duration(seconds: 5), () {
        _revision++;
        _status = TopicAnalysisStatus.timedOut;
        notifyListeners();
      });
      unawaited(_analyze(input, revision));
      notifyListeners();
    } else if (changed) {
      notifyListeners();
    }
  }

  Future<TopicAnalyzer> _load() async {
    try {
      final analyzer = await Future.sync(loadAnalyzer);
      if (_disposed) {
        analyzer.close();
      } else {
        _analyzer = analyzer;
      }
      return analyzer;
    } catch (_) {
      _loading = null;
      rethrow;
    }
  }

  Future<void> _analyze(String input, int revision) async {
    try {
      final analyzer = await (_loading ??= _load());
      if (_revision != revision) return;
      final result = await analyzer.analyze(input);
      if (_revision != revision) return;
      _lastResult = result;
      _completedInput = input;
      _status = TopicAnalysisStatus.ready;
    } catch (_) {
      if (_revision != revision) return;
      _status = TopicAnalysisStatus.failed;
    }
    _deadline?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    _deadline?.cancel();
    _analyzer?.close();
    super.dispose();
  }
}
