@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:minifeed/repository/post/firestore_post_repository.dart';

import 'helpers/firestore_emulator.dart';

void main() {
  registerFirestoreEmulatorPlugins();

  late FirestorePostRepository posts;

  setUpAll(() async {
    final client = await openFirestoreEmulatorClient('issue47-paging');
    final author = await signInToFirestoreEmulator(
      client.auth,
      client.firestore,
    );
    posts = FirestorePostRepository(
      firestore: client.firestore,
      currentUser: author,
    );
  });

  test('같은 시각의 게시글 45개를 20·20·5개로 빠짐없이 읽는다', () async {
    // given: 페이지 테스트 전에 새로 구성한 동일 시각의 글 45개
    // when
    final first = await posts.getPostPage();
    final second = await posts.getPostPage(after: first.nextCursor!);
    final third = await posts.getPostPage(after: second.nextCursor!);

    // then
    expect(first.posts, hasLength(20));
    expect(second.posts, hasLength(20));
    expect(third.posts, hasLength(5));
    expect(third.nextCursor, isNull);
    expect(
      [...first.posts, ...second.posts, ...third.posts].map((post) => post.id),
      List.generate(
        45,
        (index) => 'fixture-${(45 - index).toString().padLeft(2, '0')}',
      ),
    );
  });
}
