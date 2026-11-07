import '../models/comment.dart';

// 댓글 저장소 인터페이스. 상세 화면은 구현이 아니라 이 타입에만 의존한다.
// MP1은 메모리 구현, MP2는 Firestore 구현으로 바꿔 끼운다.
// 피드·글쓰기는 댓글을 쓰지 않아서 PostRepository와 나눴다.
abstract interface class CommentRepository {
  /// postId 게시글의 댓글을 오래된 순(작성 시각 오름차순)으로 돌려준다.
  /// 댓글이 없거나 없는 게시글이면 빈 목록을 돌려준다.
  /// (글이 없는지는 상세 화면이 getPostById로 먼저 확인한다)
  Future<List<Comment>> getComments(String postId);

  // 댓글 작성은 MP3 #20에서 추가한다.
}
