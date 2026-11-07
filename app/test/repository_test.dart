import 'package:flutter_test/flutter_test.dart';

import 'package:minifeed/models/post.dart';
import 'package:minifeed/repository/comment/in_memory_comment_repository.dart';
import 'package:minifeed/repository/post/in_memory_post_repository.dart';

// 저장소는 실제 assets JSON을 읽으므로 화면 없는 단위 테스트(test)로 확인한다.
// testWidgets의 가짜 시간 안에서는 파일 읽기가 끝나지 않을 수 있다.
void main() {
  // 테스트에서 rootBundle로 assets를 읽으려면 Flutter 엔진을 먼저 준비해야 한다.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('JSON을 불러오면 게시글 50개가 최신순으로 조회된다', () async {
    // when
    final posts = await (await _loadPosts()).getPosts();

    // then
    expect(posts, hasLength(50));
    expect(_isNewestFirst(posts), isTrue);
  });

  test('게시글 ID로 조회하면 목록에 있는 같은 글이 반환된다', () async {
    // given: 목록에서 고른 글 하나
    final repository = await _loadPosts();
    final target = (await repository.getPosts())[10];

    // when
    final found = await repository.getPostById(target.id);

    // then
    expect(found, same(target));
  });

  test('없는 게시글 ID로 조회하면 null이 반환된다', () async {
    // given
    final repository = await _loadPosts();

    // when
    final found = await repository.getPostById('post-none');

    // then
    expect(found, isNull);
  });

  test('게시글마다 댓글을 조회하면 댓글 수만큼 오래된 순으로 연결된다', () async {
    // given: 게시글 50개
    final posts = await (await _loadPosts()).getPosts();
    final repository = await InMemoryCommentRepository.load();

    // when
    final commentsByPost = {
      for (final post in posts) post: await repository.getComments(post.id),
    };

    // then
    for (final MapEntry(key: post, value: comments) in commentsByPost.entries) {
      expect(comments, hasLength(post.commentCount));
      expect(comments.every((comment) => comment.postId == post.id), isTrue);
      expect(_isOldestFirst(comments.map((c) => c.createdAt)), isTrue);
    }
    final total = commentsByPost.values.fold(0, (sum, c) => sum + c.length);
    expect(total, 83);
  });

  test('없는 게시글의 댓글을 조회하면 빈 목록이 반환된다', () async {
    // given
    final repository = await InMemoryCommentRepository.load();

    // when
    final comments = await repository.getComments('post-none');

    // then
    expect(comments, isEmpty);
  });

  test('새 글을 추가하면 피드 맨 앞에 오고 다시 조회해도 유지된다', () async {
    // given
    final repository = await _loadPosts();

    // when
    final added = await repository.addPost('새 글 본문');

    // then: 현재 사용자 정보와 0개 카운트로 만들어진다.
    expect(added.authorId, 'user-me');
    expect(added.nickName, '처음 온 펭귄');
    expect(added.colorIndex, 4);
    expect(added.likeCount, 0);
    expect(added.commentCount, 0);
    expect(added.likedByMe, isFalse);

    // then: 목록 첫 항목·ID 조회 결과가 같은 글이고, 다시 조회해도 남아 있다.
    final posts = await repository.getPosts();
    expect(posts, hasLength(51));
    expect(posts.first, same(added));
    expect(await repository.getPostById(added.id), same(added));
    expect((await repository.getPosts()).first, same(added));
  });

  test('새 글을 여러 번 추가하면 기존 글과 겹치지 않는 ID가 붙는다', () async {
    // given
    final repository = await _loadPosts();

    // when
    await repository.addPost('첫 번째');
    await repository.addPost('두 번째');

    // then
    final ids = (await repository.getPosts()).map((post) => post.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('조회한 목록을 직접 고치면 예외가 나고 저장소는 그대로다', () async {
    // given: 화면이 받은 목록
    final repository = await _loadPosts();
    final posts = await repository.getPosts();

    // when, then
    expect(() => posts.removeAt(0), throwsUnsupportedError);
    expect(await repository.getPosts(), hasLength(50));
  });
}

// main.dart와 같은 현재 사용자로 게시글 저장소를 불러온다.
Future<InMemoryPostRepository> _loadPosts() {
  return InMemoryPostRepository.load(
    authorId: 'user-me',
    nickName: '처음 온 펭귄',
    colorIndex: 4,
  );
}

bool _isNewestFirst(List<Post> posts) {
  return _isOldestFirst(posts.reversed.map((post) => post.createdAt));
}

// 앞 시각이 뒤 시각보다 늦지 않으면 오래된 순이다.
bool _isOldestFirst(Iterable<DateTime> times) {
  final list = times.toList();
  for (var i = 0; i + 1 < list.length; i++) {
    if (list[i].isAfter(list[i + 1])) return false;
  }
  return true;
}
