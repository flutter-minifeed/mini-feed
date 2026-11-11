import 'package:flutter/widgets.dart';

import 'package:minifeed/models/author.dart';
import 'package:minifeed/repository/comment/in_memory_comment_repository.dart';
import 'package:minifeed/repository/post/in_memory_post_repository.dart';
import 'package:minifeed/repository/repository_scope.dart';

/// 화면 테스트에서 [child]를 테스트용 저장소로 감싼다. main.dart와 같은 구조다.
///
/// assets JSON 대신 짧은 JSON 문자열을 쓴다.
/// testWidgets의 가짜 시간 안에서는 파일 읽기가 끝나지 않을 수 있기 때문이다.
Widget withTestRepositories(Widget child) {
  return RepositoryScope(
    postRepository: InMemoryPostRepository.fromJsonString(
      _postsJson,
      currentUser: _me,
    ),
    commentRepository: InMemoryCommentRepository.fromJsonString(_commentsJson),
    child: child,
  );
}

/// 테스트용 게시글 id. 피드 임시 버튼이 여는 글과 같고, 댓글 1개가 달려 있다.
const testPostId = 'post-01';

const _me = Author(id: 'user-me', nickName: '처음 온 펭귄', colorIndex: 4);

const _postsJson = '''[
  {"id":"post-01","authorId":"user-01","nickName":"졸린 판다","colorIndex":2,"body":"테스트 본문","createdAt":"2026-11-09T12:00:00+09:00","likeCount":3,"commentCount":1,"likedByMe":false}
]''';

const _commentsJson = '''[
  {"id":"post-01-c1","postId":"post-01","authorId":"user-02","nickName":"낮잠 자는 물개","colorIndex":3,"body":"테스트 댓글","createdAt":"2026-11-09T12:10:00+09:00"}
]''';
