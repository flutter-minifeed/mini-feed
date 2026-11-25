import 'package:flutter_test/flutter_test.dart';

import 'package:minifeed/models/author.dart';
import 'package:minifeed/repository/comment/in_memory_comment_repository.dart';
import 'package:minifeed/repository/post/in_memory_post_repository.dart';

// 저장소는 실제 assets JSON을 읽으므로 화면 없는 단위 테스트(test)로 확인한다.
// testWidgets의 가짜 시간 안에서는 파일 읽기가 끝나지 않을 수 있다.
void main() {
  // 테스트에서 rootBundle로 assets를 읽으려면 Flutter 엔진을 먼저 준비해야 한다.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('게시글마다 댓글을 조회하면 댓글 수만큼 그 글의 댓글만 연결된다', () async {
    // given: 게시글 50개
    final posts = await (await InMemoryPostRepository.load(currentUser: _me))
        .getPosts();
    final repository = await InMemoryCommentRepository.load();

    // when
    final commentsByPost = {
      for (final post in posts) post: await repository.getComments(post.id),
    };

    // then
    for (final MapEntry(key: post, value: comments) in commentsByPost.entries) {
      expect(comments, hasLength(post.commentCount));
      expect(comments.every((comment) => comment.postId == post.id), isTrue);
    }
    final total = commentsByPost.values.fold(0, (sum, c) => sum + c.length);
    expect(total, 83);
  });

  test('댓글은 JSON 순서와 상관없이 오래된 순으로 반환된다', () async {
    // given: 일부러 최신 댓글을 먼저 넣은 JSON
    final repository = InMemoryCommentRepository.fromJsonString('''[
      {"id":"c2","postId":"p1","authorId":"u","nickName":"n","colorIndex":0,"body":"b","createdAt":"2026-01-02T00:00:00+09:00"},
      {"id":"c1","postId":"p1","authorId":"u","nickName":"n","colorIndex":0,"body":"b","createdAt":"2026-01-01T00:00:00+09:00"}
    ]''');

    // when
    final comments = await repository.getComments('p1');

    // then
    expect(comments.map((comment) => comment.id).toList(), ['c1', 'c2']);
  });

  test('없는 게시글의 댓글을 조회하면 빈 목록이 반환된다', () async {
    // given
    final repository = await InMemoryCommentRepository.load();

    // when
    final comments = await repository.getComments('post-none');

    // then
    expect(comments, isEmpty);
  });

  test('댓글을 등록하면 오래된 순 목록 끝에 붙고 그 글의 댓글 수가 반환된다', () async {
    // given: p1에 댓글 1개
    final repository = InMemoryCommentRepository.fromJsonString(_oneComment);

    // when
    final added = await repository.addComment(
      'p1',
      '새 댓글',
      author: _me,
      requestId: 'request-1',
    );

    // then
    expect(added?.commentCount, 2);
    expect(added?.comment.author.id, _me.id);
    final comments = await repository.getComments('p1');
    expect(
      comments.map((comment) => comment.id).toList(),
      ['c1', 'request-1'],
    );
  });

  test('같은 요청 ID로 다시 등록하면 기존 댓글을 돌려주고 개수를 늘리지 않는다', () async {
    // given
    final repository = InMemoryCommentRepository.fromJsonString(_oneComment);
    final first = await repository.addComment(
      'p1',
      '새 댓글',
      author: _me,
      requestId: 'request-1',
    );

    // when
    final retried = await repository.addComment(
      'p1',
      '새 댓글',
      author: _me,
      requestId: 'request-1',
    );

    // then
    expect(retried?.commentCount, 2);
    expect(retried?.comment.createdAt, first?.comment.createdAt);
    expect(await repository.getComments('p1'), hasLength(2));
  });

  test('같은 요청 ID로 다른 본문을 등록하면 거부되고 목록이 바뀌지 않는다', () async {
    // given
    final repository = InMemoryCommentRepository.fromJsonString(_oneComment);
    await repository.addComment(
      'p1',
      '새 댓글',
      author: _me,
      requestId: 'request-1',
    );

    // when
    final request = repository.addComment(
      'p1',
      '다른 댓글',
      author: _me,
      requestId: 'request-1',
    );

    // then
    await expectLater(request, throwsArgumentError);
    final comments = await repository.getComments('p1');
    expect(comments.map((comment) => comment.body).toList(), ['b', '새 댓글']);
  });
}

const _oneComment = '''[
  {"id":"c1","postId":"p1","authorId":"u","nickName":"n","colorIndex":0,"body":"b","createdAt":"2026-01-01T00:00:00+09:00"}
]''';

// main.dart와 같은 현재 사용자. 댓글 수 확인에 쓸 게시글을 불러올 때 쓴다.
const _me = Author(id: 'user-me', nickName: '처음 온 펭귄', colorIndex: 4);
