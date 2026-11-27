import '../../models/comment.dart';

/// 댓글 저장소 인터페이스. 상세 화면은 구현이 아니라 이 타입에만 의존한다.
///
/// MP1은 메모리 구현, MP2는 Firestore 구현으로 바꿔 끼운다.
/// 피드·글쓰기는 댓글을 쓰지 않아서 PostRepository와 나눴다.
abstract interface class CommentRepository {
  /// postId 게시글의 댓글을 오래된 순(작성 시각 오름차순)으로 돌려준다.
  /// 댓글이 없거나 게시글의 부재가 확인되면 빈 목록을 돌려준다.
  /// 조회 자체가 실패하면 오류를 전달한다. 상세 화면은 게시글을 먼저 읽는다.
  /// 서버에 연결할 수 없거나 제때 답하지 않으면 캐시를 쓰지 않고 `OfflineException`을 던진다(#15).
  Future<List<Comment>> getComments(String postId);

  // 댓글 작성은 MP3 #20에서 추가한다.
}
