@TestOn('browser')
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:minifeed/models/author.dart';
import 'package:minifeed/repository/comment/firestore_comment_repository.dart';
import 'package:minifeed/repository/post/firestore_post_repository.dart';

import 'helpers/firestore_emulator.dart';

// 같은 글을 두 기기에서 보는 상황. 각자 익명 계정과 프로필로 로그인한다.
typedef _Device = ({
  Author author,
  FirestorePostRepository posts,
  FirestoreCommentRepository comments,
});

Future<_Device> _signIn(String name) async {
  final client = await openFirestoreEmulatorClient(name);
  final author = await signInToFirestoreEmulator(client.auth, client.firestore);
  return (
    author: author,
    posts: FirestorePostRepository(
      firestore: client.firestore,
      currentUser: author,
    ),
    comments: FirestoreCommentRepository(firestore: client.firestore),
  );
}

void main() {
  registerFirestoreEmulatorPlugins();

  late _Device a;
  late _Device b;

  // seed-repository-fixtures.mjs가 fixture-45에 댓글 2개, 나머지 글에는 0개를 만든다.
  // 테스트끼리 서버 상태를 나누지 않도록 테스트마다 다른 글을 쓴다.
  setUpAll(() async {
    a = await _signIn('issue20-device-a');
    b = await _signIn('issue20-device-b');
  });

  test('댓글을 등록하면 기존 댓글 뒤에 붙고 다른 기기에서도 목록과 개수가 맞는다', () async {
    // when
    final added = await a.comments.addComment(
      'fixture-45',
      '첫 기기 댓글',
      author: a.author,
      requestId: 'issue20-first',
    );

    // then
    expect(added?.commentCount, 3);
    expect(added?.comment.author.id, a.author.id);
    final comments = await b.comments.getComments('fixture-45');
    expect(comments.map((comment) => comment.id).last, 'issue20-first');
    expect(comments, hasLength(3));
    expect((await b.posts.getPostById('fixture-45'))?.commentCount, 3);
  });

  test('같은 요청 ID로 다시 보내면 같은 댓글을 돌려주고 개수를 늘리지 않는다', () async {
    // given
    final first = await a.comments.addComment(
      'fixture-38',
      '한 번만 저장될 댓글',
      author: a.author,
      requestId: 'issue20-retry',
    );

    // when
    final retried = await a.comments.addComment(
      'fixture-38',
      '한 번만 저장될 댓글',
      author: a.author,
      requestId: 'issue20-retry',
    );

    // then
    expect(retried?.commentCount, 1);
    expect(retried?.comment.createdAt, first?.comment.createdAt);
    expect(await b.comments.getComments('fixture-38'), hasLength(1));
  });

  test('같은 요청 ID로 다른 본문을 보내면 거부되고 개수가 그대로다', () async {
    // given
    await a.comments.addComment(
      'fixture-37',
      '처음 본문',
      author: a.author,
      requestId: 'issue20-reused',
    );

    // when
    final request = a.comments.addComment(
      'fixture-37',
      '바뀐 본문',
      author: a.author,
      requestId: 'issue20-reused',
    );

    // then
    await expectLater(request, throwsArgumentError);
    expect((await b.posts.getPostById('fixture-37'))?.commentCount, 1);
  });

  test('두 기기가 동시에 댓글을 등록하면 둘 다 저장되고 개수가 2가 된다', () async {
    // when
    await Future.wait([
      a.comments.addComment(
        'fixture-36',
        'A 기기 댓글',
        author: a.author,
        requestId: 'issue20-concurrent-a',
      ),
      b.comments.addComment(
        'fixture-36',
        'B 기기 댓글',
        author: b.author,
        requestId: 'issue20-concurrent-b',
      ),
    ]);

    // then
    final comments = await a.comments.getComments('fixture-36');
    expect(
      comments.map((comment) => comment.id),
      unorderedEquals(['issue20-concurrent-a', 'issue20-concurrent-b']),
    );
    expect((await b.posts.getPostById('fixture-36'))?.commentCount, 2);
  });

  test('서버가 201자 댓글을 거부하면 오류가 전달되고 목록과 개수가 그대로다', () async {
    // when
    final request = a.comments.addComment(
      'fixture-35',
      '가' * 201,
      author: a.author,
      requestId: 'issue20-too-long',
    );

    // then
    await expectLater(
      request,
      throwsA(
        isA<FirebaseException>().having(
          (error) => error.code,
          'code',
          'permission-denied',
        ),
      ),
    );
    expect(await b.comments.getComments('fixture-35'), isEmpty);
    expect((await b.posts.getPostById('fixture-35'))?.commentCount, 0);
  });

  test('없는 게시글에 댓글을 보내면 null을 돌려준다', () async {
    // when
    final added = await a.comments.addComment(
      'missing-post',
      '갈 곳 없는 댓글',
      author: a.author,
      requestId: 'issue20-missing',
    );

    // then
    expect(added, isNull);
  });
}
