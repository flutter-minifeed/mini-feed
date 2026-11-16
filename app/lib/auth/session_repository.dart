import '../models/author.dart';
import '../models/user_profile.dart';

abstract interface class SessionRepository {
  /// 기존 익명 사용자·프로필을 재사용한다. 재시도는 같은 진행 중 요청을 공유한다.
  Future<UserProfile> signIn({void Function(Author)? onAuthorReady});
}

enum SessionFailure {
  offline,
  permissionDenied,
  configuration,
  invalidProfile,
  unknown,
}

class SessionException implements Exception {
  const SessionException(this.failure);

  final SessionFailure failure;
}
