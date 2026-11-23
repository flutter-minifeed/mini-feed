@TestOn('browser')
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:minifeed/models/author.dart';
import 'package:minifeed/repository/comment/firestore_comment_repository.dart';
import 'package:minifeed/repository/post/firestore_post_repository.dart';

import 'helpers/firestore_emulator.dart';

const _server = GetOptions(source: Source.server);
const _fixturePost = 'fixture-45';
const _family = '👨‍👩‍👧‍👦';

void main() {
  registerFirestoreEmulatorPlugins();

  late FirebaseFirestore db;
  late Author author;
  late FirestorePostRepository posts;
  late FirestoreCommentRepository comments;
  late FirebaseFirestore signedOut;

  setUpAll(() async {
    final writer = await openFirestoreEmulatorClient('issue47-writer');
    db = writer.firestore;
    author = await signInToFirestoreEmulator(writer.auth, db);
    posts = FirestorePostRepository(firestore: db, currentUser: author);
    comments = FirestoreCommentRepository(firestore: db);
    signedOut = (await openFirestoreEmulatorClient('issue47-signed-out'))
        .firestore;
  });

  test('게시글 ID 조회는 문서 내용을 같은 모델로 반환한다', () async {
    // when
    final post = await posts.getPostById(_fixturePost);

    // then
    expect(post?.id, _fixturePost);
    expect(post?.body, '게시글 45');
    expect(post?.tags, isEmpty);
    expect(post?.author.nickName, '테스트 펭귄');
  });

  test('없는 게시글을 ID로 조회하면 null이 반환된다', () async {
    // when
    final post = await posts.getPostById('missing-post');

    // then
    expect(post, isNull);
  });

  test('댓글이 있는 글에서는 해당 글의 댓글만 오래된 순으로 읽는다', () async {
    // when
    final result = await comments.getComments(_fixturePost);

    // then
    expect(result.map((comment) => comment.id), ['early', 'late']);
    expect(result.map((comment) => comment.body), ['먼저 쓴 댓글', '나중에 쓴 댓글']);
    expect(result.every((comment) => comment.postId == _fixturePost), isTrue);
  });

  test('댓글 0개인 기존 글은 읽을 수 있고 댓글 조회는 빈 목록이다', () async {
    // given
    final post = await posts.getPostById('fixture-44');
    expect(post, isNotNull);

    // when
    final result = await comments.getComments(post!.id);

    // then
    expect(result, isEmpty);
  });

  test('게시글이 없는 것으로 확인되면 댓글 조회는 빈 목록이다', () async {
    // when
    final result = await comments.getComments('missing-post');

    // then
    expect(result, isEmpty);
  });

  test('로그인하지 않은 사용자의 댓글 조회는 권한 오류를 전달한다', () async {
    // given
    final repository = FirestoreCommentRepository(firestore: signedOut);

    // when, then
    await expectLater(
      repository.getComments(_fixturePost),
      _firestoreError('permission-denied'),
    );
  });

  test('게시글 생성은 규칙의 필드만 서버에 저장하고 피드 첫 글을 반환한다', () async {
    // when
    final post = await posts.addPost(
      '새로 쓴 글\n둘째 줄',
      requestId: 'new-post',
      tags: const ['제주', '운동·건강'],
    );

    // then
    final data = (await db.collection('posts').doc(post.id).get(_server))
        .data()!;
    expect(data, {
      'authorId': author.id,
      'nickName': author.nickName,
      'colorIndex': author.colorIndex,
      'body': post.body,
      'tags': ['제주', '운동·건강'],
      'createdAt': isA<Timestamp>(),
      'likeCount': 0,
      'commentCount': 0,
    });
    expect((data['createdAt'] as Timestamp).toDate(), post.createdAt);
    expect(post.likedByMe, isFalse);
    expect((await posts.getPosts()).first.tags, ['제주', '운동·건강']);
    expect((await posts.getPostById(post.id))!.tags, post.tags);
    await expectLater(
      posts.addPost(post.body, requestId: post.id, tags: ['다른태그']),
      throwsArgumentError,
    );
  });

  test('같은 요청을 동시에 재시도해도 하나의 문서와 최초 작성 시각을 받는다', () async {
    // given
    const body = '동시 재시도용 본문';
    const requestId = 'concurrent-post';

    // when
    final results = await Future.wait([
      posts.addPost(body, requestId: requestId),
      posts.addPost(body, requestId: requestId),
    ]);

    // then
    expect(results.map((post) => post.id), [requestId, requestId]);
    expect(results.last.createdAt, results.first.createdAt);
    final saved = await db
        .collection('posts')
        .where('body', isEqualTo: body)
        .get(_server);
    expect(saved.docs.single.id, requestId);
  });

  test('같은 요청 ID로 본문을 바꿔도 기존 글과 최초 시각이 유지된다', () async {
    // given
    final original = await posts.addPost('원래 글', requestId: 'conflicting-body');

    // when, then
    await expectLater(
      posts.addPost('다른 글', requestId: original.id),
      throwsArgumentError,
    );
    final saved = await posts.getPostById(original.id);
    expect(saved?.body, original.body);
    expect(saved?.createdAt, original.createdAt);
  });

  test('다른 사용자가 쓴 글의 ID는 같은 본문이라도 재사용할 수 없다', () async {
    // given
    final second = await openFirestoreEmulatorClient('issue47-reader');
    final otherAuthor = await signInToFirestoreEmulator(
      second.auth,
      second.firestore,
    );
    final repository = FirestorePostRepository(
      firestore: second.firestore,
      currentUser: otherAuthor,
    );
    final original = await posts.addPost('다른 계정의 글', requestId: 'other-owner');

    // when, then
    await expectLater(
      repository.addPost(original.body, requestId: original.id),
      throwsArgumentError,
    );
  });

  test('게시글 작성자의 닉네임이 프로필과 다르면 규칙에서 저장을 거부한다', () async {
    // given
    final mismatched = FirestorePostRepository(
      firestore: db,
      currentUser: Author(
        id: author.id,
        nickName: '가짜 바다',
        colorIndex: author.colorIndex,
      ),
    );

    // when, then
    await expectLater(
      mismatched.addPost('새 글', requestId: 'invalid-profile-post'),
      _firestoreError('permission-denied'),
    );
  });

  test('저장소에서 보낸 가족 이모지 300개는 규칙을 통과한다', () async {
    // when
    final post = await posts.addPost(_family * 300, requestId: 'emoji-300');

    // then
    expect(post.body, _family * 300);
  });

  test('저장소에서 보낸 가족 이모지 301개는 규칙이 거부한다', () async {
    // when, then
    await expectLater(
      posts.addPost(_family * 301, requestId: 'emoji-301'),
      _firestoreError('permission-denied'),
    );
  });

  test('서버에 연결할 수 없으면 댓글 0개 결과와 구분한다', () async {
    // given
    await db.disableNetwork();

    try {
      // when, then
      await expectLater(
        comments.getComments(_fixturePost),
        _firestoreError('unavailable'),
      );
    } finally {
      await db.enableNetwork();
    }
  });
}

Matcher _firestoreError(String code) => throwsA(
  isA<FirebaseException>().having((error) => error.code, 'code', code),
);
