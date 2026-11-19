import 'package:flutter/foundation.dart';
import 'package:minifeed/models/author.dart';
import 'package:minifeed/models/post.dart';
import 'package:minifeed/viewmodels/write_view_model.dart';

import 'test_app.dart';

class FakeWriteViewModel extends ChangeNotifier implements WriteViewModel {
  FakeWriteViewModel() : _resultStatus = WriteStatus.failed;
  FakeWriteViewModel.timedOut() : _resultStatus = WriteStatus.timedOut;

  final WriteStatus _resultStatus;

  @override
  Author get author => testUser;

  @override
  WriteStatus get status => _status;
  WriteStatus _status = WriteStatus.idle;

  @override
  Future<Post?> submit(String validatedBody) async {
    _status = _resultStatus;
    notifyListeners();
    return null;
  }
}
