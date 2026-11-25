import '../../models/author.dart';
import '../../models/comment.dart';

/// 댓글 저장소 인터페이스. 상세 화면은 구현이 아니라 이 타입에만 의존한다.
///
/// MP1은 메모리 구현, MP2는 Firestore 구현으로 바꿔 끼운다.
/// 피드·글쓰기는 댓글을 쓰지 않아서 PostRepository와 나눴다.
abstract interface class CommentRepository {
  /// postId 게시글의 댓글을 오래된 순(작성 시각 오름차순)으로 돌려준다.
  /// 댓글이 없거나 게시글의 부재가 확인되면 빈 목록을 돌려준다.
  /// 조회 자체가 실패하면 오류를 전달한다. 상세 화면은 게시글을 먼저 읽는다.
  /// 서버에 연결할 수 없으면 캐시를 쓰지 않고 `OfflineException`을 던진다(#15).
  Future<List<Comment>> getComments(String postId);

  /// [author] 이름으로 [postId] 게시글에 검증된 [body] 댓글을 저장한다.
  /// 저장된 댓글과 서버가 확정한 게시글의 댓글 수를 돌려준다.
  /// 게시글 목록을 확인할 수 있는 구현은 게시글이 없으면 null을 돌려준다.
  /// 메모리 구현(MP1)은 게시글 목록을 모르므로 항상 저장한다.
  ///
  /// [requestId]를 댓글 ID로 쓴다. 같은 ID·작성자·본문이면 기존 댓글을 돌려주고 개수를 다시 올리지 않는다.
  /// 같은 ID의 작성자나 본문이 다르면 [ArgumentError]로 거부한다.
  /// 서버가 시한 안에 답하지 않으면 `TimeoutException`을,
  /// 서버에 연결할 수 없으면 `OfflineException`을 던진다(#15).
  /// 이 경우와 다른 저장 오류에서도 댓글이 이미 저장됐을 수 있으니,
  /// 같은 본문을 다시 보낼 때는 같은 [requestId]를 넘긴다.
  Future<AddedComment?> addComment(
    String postId,
    String body, {
    required Author author,
    required String requestId,
  });
}

/// 저장된 댓글과 그 시점에 서버가 확정한 게시글의 댓글 수.
typedef AddedComment = ({Comment comment, int commentCount});

/// 같은 요청 ID로 이미 저장된 댓글을 재시도 결과로 돌려준다.
/// 작성자나 본문이 다르면 다른 요청이 ID를 재사용한 것이라 거부한다.
Comment checkSameComment(
  Comment saved, {
  required Author author,
  required String body,
}) {
  if (saved.author.id != author.id || saved.body != body) {
    throw ArgumentError('같은 요청 ID로 다른 댓글을 저장할 수 없습니다.');
  }
  return saved;
}
