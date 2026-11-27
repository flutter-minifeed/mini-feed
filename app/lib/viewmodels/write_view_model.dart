import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/author.dart';
import '../models/post.dart';
import '../repository/post/post_repository.dart';

const _saveTimeout = Duration(seconds: 10);

enum WriteStatus { idle, saving, succeeded, failed, timedOut, tooLarge }

abstract interface class WriteViewModel implements Listenable {
  Author get author;
  WriteStatus get status;
  Future<Post?> submit(String validatedBody, {List<String> tags = const []});
  void dispose();
}

class WriteViewModelImpl extends ChangeNotifier implements WriteViewModel {
  WriteViewModelImpl({required this._repository});

  final PostRepository _repository;
  WriteStatus _status = WriteStatus.idle;
  String? _submittedBody;
  List<String> _submittedTags = const [];
  String? _requestId;
  int _attempt = 0;
  bool _disposed = false;
  Timer? _timer;
  Completer<Post?>? _pendingResult;

  @override
  Author get author => _repository.currentUser;

  @override
  WriteStatus get status => _status;

  @override
  Future<Post?> submit(String validatedBody, {List<String> tags = const []}) {
    if (_disposed ||
        _status == WriteStatus.saving ||
        _status == WriteStatus.succeeded) {
      return Future.value();
    }

    if (_requestId == null ||
        validatedBody != _submittedBody ||
        !listEquals(_submittedTags, tags)) {
      _requestId = _newRequestId();
      _submittedBody = validatedBody;
      _submittedTags = List.unmodifiable(tags);
    }

    final attempt = ++_attempt;
    final result = Completer<Post?>();
    _pendingResult = result;
    _status = WriteStatus.saving;
    _timer = Timer(_saveTimeout, () {
      _finish(attempt, WriteStatus.timedOut);
    });
    notifyListeners();

    Future.sync(
      () => _repository.addPost(
        validatedBody,
        requestId: _requestId,
        tags: _submittedTags,
      ),
    ).then(
      (post) => _finish(attempt, WriteStatus.succeeded, post),
      onError: (Object error, StackTrace stack) {
        _finish(attempt, switch (error) {
          TimeoutException() => WriteStatus.timedOut,
          PostTooLargeException() => WriteStatus.tooLarge,
          _ => WriteStatus.failed,
        });
      },
    );
    return result.future;
  }

  bool _isStillWaitingFor(int attempt) =>
      !_disposed && attempt == _attempt && _status == WriteStatus.saving;

  void _finish(int attempt, WriteStatus status, [Post? post]) {
    if (!_isStillWaitingFor(attempt)) return;
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
