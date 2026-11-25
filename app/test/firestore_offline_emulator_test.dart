@TestOn('browser')
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:minifeed/repository/comment/firestore_comment_repository.dart';
import 'package:minifeed/repository/like/firestore_like_repository.dart';
import 'package:minifeed/repository/offline_exception.dart';
import 'package:minifeed/repository/post/firestore_post_repository.dart';
import 'package:minifeed/repository/post/post_repository.dart';

import 'helpers/firestore_emulator.dart';

// 한 기기의 저장소 묶음. firestore로 이 기기만 연결을 끊고 다시 잇는다.
typedef _Device = ({
  FirebaseFirestore firestore,
  FirestorePostRepository posts,
  FirestoreCommentRepository comments,
  FirestoreLikeRepository likes,
});

// Android 앱은 기본으로 기기 저장소에 캐시를 남긴다. 웹 테스트 기본값은 한 번 읽은 문서를
// 바로 지우는 메모리 캐시라서, 앱과 같은 조건이 되도록 캐시 유지를 켠다.
Future<_Device> _signIn(String name) async {
  final client = await openFirestoreEmulatorClient(name, persistent: true);
  final author = await signInToFirestoreEmulator(client.auth, client.firestore);
  return (
    firestore: client.firestore,
    posts: FirestorePostRepository(
      firestore: client.firestore,
      currentUser: author,
    ),
    comments: FirestoreCommentRepository(firestore: client.firestore),
    likes: FirestoreLikeRepository(
      firestore: client.firestore,
      userId: author.id,
    ),
  );
}

bool _likedIn(PostPage page, String id) =>
    page.posts.singleWhere((post) => post.id == id).likedByMe;

void main() {
  registerFirestoreEmulatorPlugins();

  late _Device reader;
  late _Device writer;

  // seed-repository-fixtures.mjs가 같은 시각의 fixture-01~45를 만든다.
  // 첫 페이지는 fixture-45~26이고, fixture-45에는 댓글 2개가 있다.
  setUpAll(() async {
    reader = await _signIn('issue15-reader');
    writer = await _signIn('issue15-writer');
  });

  // 실패한 테스트가 연결을 끊은 채로 남아 다음 테스트를 오염시키지 않게 한다.
  tearDown(() => reader.firestore.enableNetwork());

  test('연결을 끊으면 이미 읽은 첫 페이지를 캐시에서 같은 순서와 좋아요로 돌려준다', () async {
    // given
    await reader.likes.setLike('fixture-44', liked: true);
    final online = await reader.posts.getPostPage();
    await reader.firestore.disableNetwork();

    // when
    final offline = await reader.posts.getPostPage();

    // then
    expect(online.fromCache, isFalse);
    expect(offline.fromCache, isTrue);
    expect(
      offline.posts.map((post) => post.id),
      online.posts.map((post) => post.id),
    );
    expect(_likedIn(offline, 'fixture-44'), isTrue);
    expect(_likedIn(offline, 'fixture-43'), isFalse);
  });

  test('연결을 끊으면 캐시에 있는 글 상세는 본문을 돌려주고 읽은 적 없는 글은 오프라인으로 알린다', () async {
    // given: 첫 페이지만 읽어 fixture-45는 캐시에 있고 fixture-01은 없다.
    final online = await reader.posts.getPostPage();
    final cached = online.posts.singleWhere((post) => post.id == 'fixture-45');
    await reader.firestore.disableNetwork();

    // when
    final post = await reader.posts.getPostById('fixture-45');
    final unread = reader.posts.getPostById('fixture-01');

    // then
    expect(post?.body, cached.body);
    await expectLater(unread, throwsA(isA<OfflineException>()));
  });

  test('연결을 끊으면 전에 읽은 댓글이 있어도 댓글 조회는 오프라인으로 알린다', () async {
    // given
    expect(await reader.comments.getComments('fixture-45'), hasLength(2));
    await reader.firestore.disableNetwork();

    // when
    final request = reader.comments.getComments('fixture-45');

    // then
    await expectLater(request, throwsA(isA<OfflineException>()));
  });

  test('다시 연결하면 서버에서 읽고 끊긴 동안 다른 기기가 쓴 글이 보인다', () async {
    // given
    await reader.posts.getPostPage();
    await reader.firestore.disableNetwork();
    final written = await writer.posts.addPost(
      '연결이 끊긴 동안 쓴 글',
      requestId: 'issue15-while-offline',
    );
    final offline = await reader.posts.getPostPage();

    // when
    await reader.firestore.enableNetwork();
    final online = await reader.posts.getPostPage();

    // then
    expect(offline.posts.map((post) => post.id), isNot(contains(written.id)));
    expect((online.fromCache, online.posts.first.id), (false, written.id));
  });

  test('한 번도 읽지 않은 상태로 연결을 끊으면 빈 페이지를 캐시 표시와 함께 돌려준다', () async {
    // given: 처음 실행한 기기처럼 아무것도 읽지 않은 클라이언트
    final fresh = await _signIn('issue15-fresh');
    addTearDown(fresh.firestore.enableNetwork);
    await fresh.firestore.disableNetwork();

    // when
    final page = await fresh.posts.getPostPage();

    // then
    expect(page.fromCache, isTrue);
    expect(page.posts, isEmpty);
    expect(page.nextCursor, isNull);
  });
}
