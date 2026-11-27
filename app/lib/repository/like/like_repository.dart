/// 좋아요 저장소 인터페이스. 하트를 누르는 화면은 구현이 아니라 이 타입에만 의존한다.
///
/// 글을 읽을 때의 개수와 내 선택(likedByMe)은 PostRepository가 함께 돌려주고,
/// 이 저장소는 좋아요 상태를 바꾸는 일만 맡는다.
/// 글쓰기처럼 좋아요를 쓰지 않는 화면이 이 기능에 의존하지 않도록 PostRepository와 나눴다.
abstract interface class LikeRepository {
  /// 현재 사용자의 [postId] 좋아요를 [liked] 상태로 맞추고 서버가 확정한 상태를 돌려준다.
  ///
  /// 이미 같은 상태면 아무것도 쓰지 않고 현재 개수를 돌려준다.
  /// 그래서 같은 요청을 다시 보내도 개수는 한 번만 바뀐다.
  /// 게시글이 없으면 null을 돌려준다.
  ///
  /// 한 게시글의 요청은 앞 요청이 끝난 뒤 보낸다. 동시에 보내면 나중에 저장된 요청이 최종 상태가 된다.
  /// 서버에 연결할 수 없으면 `OfflineException`을 던진다(#15 계약, #19에서 사용). 다른 저장 실패는 오류를 그대로 전달한다.
  Future<LikeState?> setLike(String postId, {required bool liked});
}

/// 서버에 확정된 좋아요 상태. 화면은 먼저 바꿔 둔 하트와 개수를 이 값으로 맞춘다.
typedef LikeState = ({bool liked, int likeCount});
