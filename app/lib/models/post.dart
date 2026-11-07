// 게시글 한 건. 화면과 저장소가 함께 쓰는 데이터라 저장 방식(JSON·Firestore)을 모른다.
// 저장 형식에서 Post로 바꾸는 일은 각 저장소 구현이 맡는다.
class Post {
  // const 생성자: 모든 필드가 final이라 만든 뒤에는 값이 바뀌지 않는다.
  // required: 이름 붙인 인자를 빠뜨리면 컴파일 오류가 난다.
  const Post({
    required this.id,
    required this.authorId,
    required this.nickName,
    required this.colorIndex,
    required this.body,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
  });

  final String id;
  final String authorId;
  final String nickName;
  final int colorIndex; // 사용자 색 user/1~8 중 하나 (0~7)
  final String body;
  final DateTime createdAt; // 기기 시간대 기준 시각
  final int likeCount;
  final int commentCount;
  final bool likedByMe; // 현재 사용자가 좋아요를 눌렀는지. 서버 공용 필드가 아니다.
}
