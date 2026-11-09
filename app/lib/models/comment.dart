import 'author.dart';

/// 댓글 한 건. Post처럼 저장 방식(JSON·Firestore)을 모른다.
///
/// 저장 형식에서 Comment로 바꾸는 일은 각 저장소 구현이 맡는다.
class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.author,
    required this.body,
    required this.createdAt,
  });

  final String id;

  /// 이 댓글이 달린 게시글의 id.
  final String postId;

  final Author author;
  final String body;

  /// 기기 시간대 기준 작성 시각.
  final DateTime createdAt;
}
