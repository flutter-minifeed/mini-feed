import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:minifeed/models/author.dart';
import 'package:minifeed/repository/post/in_memory_post_repository.dart';

// 저장소는 실제 assets JSON을 읽으므로 화면 없는 단위 테스트(test)로 확인한다.
// testWidgets의 가짜 시간 안에서는 파일 읽기가 끝나지 않을 수 있다.
void main() {
  // 테스트에서 rootBundle로 assets를 읽으려면 Flutter 엔진을 먼저 준비해야 한다.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('게시한 태그의 순서와 원문을 보존하고 태그가 다른 재시도는 거부한다', () async {
    // given
    final repository = InMemoryPostRepository.fromJsonString(
      '[]',
      currentUser: const Author(id: 'a', nickName: '펭귄', colorIndex: 0),
    );
    final tags = ['Jeju', '여행'];

    // when
    final post = await repository.addPost('본문', requestId: '태그', tags: tags);
    tags.clear();

    // then
    expect((await repository.getPostById(post.id))!.tags, ['Jeju', '여행']);
    expect(() => post.tags.clear(), throwsUnsupportedError);
    await expectLater(
      repository.addPost('본문', requestId: post.id),
      throwsArgumentError,
    );
  });

  test('JSON을 불러오면 게시글 50개가 조회된다', () async {
    // when
    final posts = await (await _loadPosts()).getPosts();

    // then
    expect(posts, hasLength(50));
  });

  test('게시글은 JSON 순서와 상관없이 최신순으로 반환된다', () async {
    // given: 일부러 오래된 글을 먼저 넣은 JSON
    final repository = InMemoryPostRepository.fromJsonString('''[
        {"id":"p1","authorId":"u","nickName":"n","colorIndex":0,"body":"b","createdAt":"2026-01-01T00:00:00+09:00","likeCount":0,"commentCount":0,"likedByMe":false},
        {"id":"p2","authorId":"u","nickName":"n","colorIndex":0,"body":"b","createdAt":"2026-01-02T00:00:00+09:00","likeCount":0,"commentCount":0,"likedByMe":false}
      ]''', currentUser: _me);

    // when
    final posts = await repository.getPosts();

    // then
    expect(posts.map((post) => post.id).toList(), ['p2', 'p1']);
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

  test('새 글은 입력한 본문과 0개 카운트로 만들어진다', () async {
    // given: 추가 전 가장 최신 글
    final repository = await _loadPosts();
    final newestBefore = (await repository.getPosts()).first;

    // when
    final added = await repository.addPost('새 글 본문');

    // then
    expect(added.body, '새 글 본문');
    expect(added.createdAt.isAfter(newestBefore.createdAt), isTrue);
    expect(added.likeCount, 0);
    expect(added.commentCount, 0);
    expect(added.likedByMe, isFalse);
  });

  test('새 글에는 현재 사용자의 작성자 정보가 설정된다', () async {
    // given
    final repository = InMemoryPostRepository.fromJsonString(
      '[]',
      currentUser: _me,
    );

    // when
    final added = await repository.addPost('새 글');

    // then
    expect(added.author.id, _me.id);
    expect(added.author.nickName, _me.nickName);
    expect(added.author.colorIndex, _me.colorIndex);
  });

  test('새 글을 추가하면 피드 맨 앞에 오고 ID로도 조회된다', () async {
    // given
    final repository = await _loadPosts();

    // when
    final added = await repository.addPost('새 글 본문');

    // then
    final posts = await repository.getPosts();
    expect(posts, hasLength(51));
    expect(posts.first, same(added));
    expect(await repository.getPostById(added.id), same(added));
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

  test('조회한 목록을 직접 고치면 예외가 난다', () async {
    // given: 화면이 받은 목록
    final posts = await (await _loadPosts()).getPosts();

    // when, then
    expect(() => posts.removeAt(0), throwsUnsupportedError);
  });

  test('같은 요청 ID를 동시에 저장해도 최초 게시글 하나를 반환한다', () async {
    // given
    final repository = InMemoryPostRepository.fromJsonString(
      '[]',
      currentUser: _me,
    );

    // when
    final results = await Future.wait([
      repository.addPost('첫 글', requestId: 'request-1'),
      repository.addPost('첫 글', requestId: 'request-1'),
    ]);
    final posts = await repository.getPosts();

    // then
    expect(posts, hasLength(1));
    expect(results.last, same(results.first));
  });

  test('같은 요청 ID로 다른 본문을 저장하면 거부한다', () async {
    // given
    final repository = InMemoryPostRepository.fromJsonString(
      '[]',
      currentUser: _me,
    );
    await repository.addPost('첫 글', requestId: 'request-1');

    // when
    final result = repository.addPost('다른 글', requestId: 'request-1');

    // then
    await expectLater(result, throwsArgumentError);
  });

  test('조회한 목록을 고치려 해도 저장소 목록은 그대로다', () async {
    // given: 화면이 받은 목록
    final repository = await _loadPosts();
    final posts = await repository.getPosts();

    // when
    try {
      posts.removeAt(0);
    } on UnsupportedError {
      // 예외 자체는 앞 테스트에서 확인한다. 여기서는 저장소 상태만 본다.
    }

    // then
    expect(await repository.getPosts(), hasLength(50));
  });

  test('게시글 45개를 20개씩 조회하면 중복 없이 마지막 5개까지 읽는다', () async {
    // given
    final repository = _pagedRepository(45);

    // when
    final first = await repository.getPostPage();
    final second = await repository.getPostPage(after: first.nextCursor!);
    final third = await repository.getPostPage(after: second.nextCursor!);

    // then
    expect(first.posts, hasLength(20));
    expect(second.posts, hasLength(20));
    expect(third.posts, hasLength(5));
    expect(third.nextCursor, isNull);
    expect(
      [...first.posts, ...second.posts, ...third.posts].map((post) => post.id),
      List.generate(45, (index) => _fixtureId(44 - index)),
    );
  });

  test('페이지 경계의 작성 시각이 같으면 문서 ID로 조회 위치를 구분한다', () async {
    // given
    final repository = _pagedRepository(21, sameCreatedAt: true);

    // when
    final first = await repository.getPostPage();
    final second = await repository.getPostPage(after: first.nextCursor!);

    // then
    expect(
      first.posts.map((post) => post.id),
      List.generate(20, (index) => _fixtureId(20 - index)),
    );
    expect(second.posts.single.id, _fixtureId(0));
  });

  test('마지막 페이지가 가득 차면 다음 빈 페이지에서 조회를 끝낸다', () async {
    // given
    final repository = _pagedRepository(20);

    // when
    final first = await repository.getPostPage();
    final last = await repository.getPostPage(after: first.nextCursor!);

    // then
    expect(last.posts, isEmpty);
    expect(last.nextCursor, isNull);
  });

  test('같은 요청 ID로 동시에 게시하면 글 한 건과 최초 작성 시각을 반환한다', () async {
    // given
    final repository = _pagedRepository(0);
    const requestId = 'write-request-1';

    // when
    final results = await Future.wait([
      repository.addPost('같은 본문', requestId: requestId),
      repository.addPost('같은 본문', requestId: requestId),
    ]);

    // then
    expect((await repository.getPosts()).single.id, requestId);
    expect(results.first.id, requestId);
    expect(results.last.id, results.first.id);
    expect(results.last.createdAt, results.first.createdAt);
  });

  test('이미 쓴 요청 ID로 본문을 바꾸면 기존 글을 유지한다', () async {
    // given
    final repository = _pagedRepository(0);
    const requestId = 'write-request-1';
    final original = await repository.addPost('원래 본문', requestId: requestId);

    // when, then
    await expectLater(
      repository.addPost('바꾼 본문', requestId: requestId),
      throwsArgumentError,
    );
    expect((await repository.getPosts()).single, same(original));
  });

  test('다른 작성자의 게시글 ID를 게시 요청에 재사용할 수 없다', () async {
    // given
    final repository = _pagedRepository(1);

    // when, then
    await expectLater(
      repository.addPost('테스트 본문', requestId: _fixtureId(0)),
      throwsArgumentError,
    );
    expect((await repository.getPosts()).single.author.id, 'fixture-author');
  });

  test('요청 ID 없이 같은 본문을 각각 게시하면 새 글 두 건을 만든다', () async {
    // given
    final repository = _pagedRepository(0);

    // when
    final first = await repository.addPost('같은 본문');
    final second = await repository.addPost('같은 본문');

    // then
    expect(first.id, isNot(second.id));
    expect(await repository.getPosts(), hasLength(2));
  });
}

// main.dart와 같은 현재 사용자.
const _me = Author(id: 'user-me', nickName: '처음 온 펭귄', colorIndex: 4);

// 현재 사용자로 게시글 저장소를 불러온다.
Future<InMemoryPostRepository> _loadPosts() {
  return InMemoryPostRepository.load(currentUser: _me);
}

String _fixtureId(int index) => 'fixture-${index.toString().padLeft(2, '0')}';

InMemoryPostRepository _pagedRepository(
  int count, {
  bool sameCreatedAt = false,
}) {
  final start = DateTime.utc(2026);
  final fixtures = List.generate(count, (index) {
    return {
      'id': _fixtureId(index),
      'authorId': 'fixture-author',
      'nickName': '조용한 펭귄',
      'colorIndex': 0,
      'body': '테스트 본문',
      'createdAt': start
          .add(Duration(minutes: sameCreatedAt ? 0 : index))
          .toIso8601String(),
      'likeCount': 0,
      'commentCount': 0,
      'likedByMe': false,
    };
  });
  return InMemoryPostRepository.fromJsonString(
    jsonEncode(fixtures),
    currentUser: _me,
  );
}
