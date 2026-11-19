import 'author.dart';

/// 인증된 작성자와 최초 프로필 생성 시각. 저장 형식 변환은 저장소에서 한다.
class UserProfile {
  const UserProfile({required this.author, required this.createdAt});

  final Author author;
  final DateTime createdAt;
}
