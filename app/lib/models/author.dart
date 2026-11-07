/// 게시글·댓글 작성자. 화면과 저장소가 함께 쓰며 저장 방식(JSON·Firestore)을 모른다.
///
/// JSON의 authorId·nickName·colorIndex는 각 저장소 구현이 이 객체로 묶는다.
class Author {
  const Author({
    required this.id,
    required this.nickName,
    required this.colorIndex,
  });

  final String id;
  final String nickName;

  /// 사용자 색 순번 0~7. Figma의 user/1~8에 대응한다.
  final int colorIndex;
}
