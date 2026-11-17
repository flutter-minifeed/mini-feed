import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/author.dart';
import '../models/post.dart';
import '../repository/post/post_repository.dart';

enum WriteStatus { idle, saving, succeeded, failed, timedOut }

abstract interface class WriteViewModel implements Listenable {
  Author get author;
  WriteStatus get status;
  Future<Post?> submit(String body);
  void dispose();
}

class WriteViewModelImpl extends ChangeNotifier implements WriteViewModel {
  WriteViewModelImpl({required this._repository});

  final PostRepository _repository;
  WriteStatus _status = WriteStatus.idle;
  String? _submittedBody;
  String? _requestId;
  int _attempt = 0;
  bool _disposed = false;
  Timer? _timer;
  Completer<Post?>? _pendingResult;

  @override
  Author get author => _repository.currentUser;

  @override
  WriteStatus get status => _status;

  /// 화면에서 공백·길이를 검사한 본문을 받는다. 성공 이외에는 null을 반환한다.
  @override
  Future<Post?> submit(String body) {
    if (_disposed ||
        _status == WriteStatus.saving ||
        _status == WriteStatus.succeeded) {
      return Future.value();
    }

    if (_requestId == null || body != _submittedBody) {
      _requestId = _newRequestId();
      _submittedBody = body;
    }

    final attempt = ++_attempt;
    final result = Completer<Post?>();
    _pendingResult = result;
    _status = WriteStatus.saving;
    _timer = Timer(const Duration(seconds: 10), () {
      _finish(attempt, WriteStatus.timedOut);
    });
    // 등록된 리스너에 상태 변경을 알려 화면이 새 상태로 다시 그려지게 한다.
    notifyListeners();

    Future.sync(() => _repository.addPost(body, requestId: _requestId)).then(
      (post) => _finish(attempt, WriteStatus.succeeded, post),
      onError: (Object error, StackTrace stack) {
        _finish(
          attempt,
          error is TimeoutException ? WriteStatus.timedOut : WriteStatus.failed,
        );
      },
    );
    return result.future;
  }

  void _finish(int attempt, WriteStatus status, [Post? post]) {
    // 시간 초과·재시도·화면 해제 뒤 도착한 응답은 현재 화면에 적용하지 않는다.
    if (_disposed || attempt != _attempt || _status != WriteStatus.saving) {
      return;
    }
    _timer?.cancel();
    _status = status;
    _pendingResult?.complete(post);
    _pendingResult = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _pendingResult?.complete();
    _pendingResult = null;
    super.dispose();
  }
}

// 화면을 다시 열거나 기기가 달라도 요청 ID가 충돌하지 않도록 128비트 난수를 쓴다.
String _newRequestId() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}
