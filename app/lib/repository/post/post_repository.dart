import '../../models/post.dart';

/// 게시글 저장소 인터페이스. 화면은 구현이 아니라 이 타입에만 의존한다.
///
/// MP1은 메모리 구현, MP2는 Firestore 구현으로 바꿔 끼운다.
abstract interface class PostRepository {
  /// 모든 게시글을 최신순(작성 시각 내림차순)으로 돌려준다.
  Future<List<Post>> getPosts();

  /// id가 같은 게시글을 돌려준다. 없는 id면 null을 돌려준다.
  Future<Post?> getPostById(String id);

  /// 현재 사용자 이름으로 새 글을 만들어 목록 맨 앞에 넣고, 만든 글을 돌려준다.
  /// 좋아요·댓글 수는 0으로 시작한다. 300자·공백 검사는 글쓰기 화면이 한다.
  Future<Post> addPost(String body);
}
