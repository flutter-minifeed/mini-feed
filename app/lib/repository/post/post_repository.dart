import '../../models/author.dart';
import '../../models/post.dart';

/// 게시글 저장소 인터페이스. 화면은 구현이 아니라 이 타입에만 의존한다.
///
/// MP1은 메모리 구현, MP2는 Firestore 구현으로 바꿔 끼운다.
abstract interface class PostRepository {
  /// [addPost]로 만드는 글의 작성자. 글쓰기 화면이 작성자 줄을 그릴 때 쓴다.
  Author get currentUser;

  /// 모든 게시글을 최신순(작성 시각 내림차순)으로 돌려준다.
  Future<List<Post>> getPosts();

  /// id가 같은 게시글을 돌려준다. 없는 id면 null을 돌려준다.
  Future<Post?> getPostById(String id);

  /// 현재 사용자 이름으로 새 글을 만들어 목록 맨 앞에 넣고, 만든 글을 돌려준다.
  /// 좋아요·댓글 수는 0으로 시작한다. 300자·공백 검사는 글쓰기 화면이 한다.
  ///
  /// #14가 가정하는 #47 연결 계약: 같은 requestId·본문은 동시 재시도에도
  /// 하나의 글과 최초 작성 시각을 반환한다. 같은 ID로 다른 본문은 거부한다.
  /// null은 기존 호출부 호환용이며, 호출할 때마다 새 글을 만든다.
  Future<Post> addPost(String body, {String? requestId});
}
