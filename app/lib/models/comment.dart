// 댓글 한 건. Post처럼 저장 방식(JSON·Firestore)을 모른다.
// 저장 형식에서 Comment로 바꾸는 일은 각 저장소 구현이 맡는다.
class Comment {
  // const 생성자: 모든 필드가 final이라 만든 뒤에는 값이 바뀌지 않는다.
  const Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.nickName,
    required this.colorIndex,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String postId; // 이 댓글이 달린 게시글의 id
  final String authorId;
  final String nickName;
  final int colorIndex; // 사용자 색 user/1~8 중 하나 (0~7)
  final String body;
  final DateTime createdAt; // 기기 시간대 기준 시각
}
