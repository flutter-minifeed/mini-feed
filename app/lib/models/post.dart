import 'author.dart';

/// 게시글 한 건. 화면과 저장소가 함께 쓰는 데이터라 저장 방식(JSON·Firestore)을 모른다.
///
/// 저장 형식에서 Post로 바꾸는 일은 각 저장소 구현이 맡는다.
class Post {
  const Post({
    required this.id,
    required this.author,
    required this.body,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
  });

  final String id;
  final Author author;
  final String body;

  /// 기기 시간대 기준 작성 시각.
  final DateTime createdAt;

  final int likeCount;
  final int commentCount;

  /// 현재 사용자가 좋아요를 눌렀는지. 서버 공용 게시글 필드로 저장하지 않는다.
  final bool likedByMe;
}
