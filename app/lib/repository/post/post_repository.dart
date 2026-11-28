import 'package:flutter/foundation.dart';

import '../../models/author.dart';
import '../../models/post.dart';

/// 게시글 저장소 인터페이스. 화면은 구현이 아니라 이 타입에만 의존한다.
///
/// MP1은 메모리 구현, MP2는 Firestore 구현으로 바꿔 끼운다.
abstract interface class PostRepository {
  /// [addPost]로 만드는 글의 작성자. 글쓰기 화면이 작성자 줄을 그릴 때 쓴다.
  Author get currentUser;

  /// MP1 피드에서 사용한다. 모든 게시글을 최신순으로 돌려준다.
  Future<List<Post>> getPosts();

  /// [after]가 없으면 첫 페이지, 있으면 커서의 다음 글부터 최대 20개를 반환한다.
  /// 작성 시각 내림차순이며 시각이 같으면 문서 ID 내림차순으로 정렬한다.
  /// 서버에 연결할 수 없거나 제때 답하지 않으면 기기 캐시에 남은 글로 같은 순서의 페이지를 만들고
  /// [PostPage.fromCache]를 true로 둔다. 캐시가 비어 있으면 빈 페이지다(#15).
  Future<PostPage> getPostPage({PostCursor? after});

  /// id가 같은 게시글을 돌려준다. 없는 id면 null을 돌려준다.
  /// 서버에 연결할 수 없거나 제때 답하지 않으면 캐시에 남은 글을 돌려준다.
  /// 캐시에도 없으면 없는 글과 구분하도록 null 대신 `OfflineException`을 던진다(#15).
  Future<Post?> getPostById(String id);

  /// 현재 사용자의 검증된 본문을 저장한다. 두 초기 카운터는 0이다.
  /// [requestId]가 있으면 게시글 ID로 쓰고, 없으면 호출마다 새 ID를 만든다.
  /// 같은 ID·작성자·본문·태그이면 기존 글과 최초 작성 시각을 돌려준다.
  /// 같은 ID의 작성자, 본문 또는 태그이 다르면 [ArgumentError]로 거부한다.
  /// 서버가 시한 안에 답하지 않으면 `TimeoutException`을 던진다.
  /// 이 경우와 다른 저장 오류에서도 글이 이미 저장됐을 수 있으니,
  /// 같은 본문과 태그를 다시 보낼 때는 같은 [requestId]를 넘긴다.
  Future<Post> addPost(
    String body, {
    String? requestId,
    List<String> tags = const [],
  });
}

/// 페이지의 마지막 글 위치. 다음 조회에 받은 값을 그대로 넘긴다.
typedef PostCursor = ({DateTime createdAt, String postId});

class PostPage {
  PostPage(List<Post> posts, {this.fromCache = false})
    : posts = List.unmodifiable(posts),
      nextCursor = posts.length == pageSize
          ? (createdAt: posts.last.createdAt, postId: posts.last.id)
          : null;

  /// 이미 같은 순서로 정렬된 메모리 목록을 문서 커서 기준으로 잘라 낸다.
  factory PostPage.fromOrderedPosts(List<Post> posts, {PostCursor? after}) {
    final remaining = after == null
        ? posts
        : posts.skipWhile((post) => _compareToCursor(post, after) <= 0);
    return PostPage(remaining.take(pageSize).toList());
  }

  static const pageSize = 20;
  final List<Post> posts;

  /// 가득 찬 페이지는 커서가 있다. 정확히 20의 배수면 다음 빈 페이지에서 끝난다.
  final PostCursor? nextCursor;

  /// 서버에 연결하지 못해 기기 캐시에서 읽은 페이지면 true다.
  /// 화면은 이 값으로 오프라인 상태를 표시한다.
  final bool fromCache;
}

/// 게시 시각과 문서 ID가 모두 내림차순인 조회 순서.
int comparePostsNewestFirst(Post left, Post right) =>
    _compareToCursor(left, (createdAt: right.createdAt, postId: right.id));

int _compareToCursor(Post post, PostCursor cursor) {
  final byTime = cursor.createdAt.compareTo(post.createdAt);
  return byTime == 0 ? cursor.postId.compareTo(post.id) : byTime;
}

/// 같은 요청 ID로 이미 저장된 글을 재시도 결과로 돌려준다.
/// 작성자, 본문 또는 태그이 다르면 다른 요청이 ID를 재사용한 것이라 거부한다.
Post checkSameRequest(
  Post saved, {
  required Author author,
  required String body,
  required List<String> tags,
}) {
  if (saved.author.id != author.id ||
      saved.body != body ||
      !listEquals(saved.tags, tags)) {
    throw ArgumentError('같은 요청 ID로 다른 게시글을 저장할 수 없습니다.');
  }
  return saved;
}
