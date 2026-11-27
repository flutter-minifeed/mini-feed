@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:minifeed/repository/like/firestore_like_repository.dart';
import 'package:minifeed/repository/post/firestore_post_repository.dart';
import 'package:minifeed/repository/post/post_repository.dart';

import 'helpers/firestore_emulator.dart';

// 같은 글을 두 기기에서 보는 상황. 각자 익명 계정으로 로그인한다.
typedef _Device = ({
  FirestorePostRepository posts,
  FirestoreLikeRepository likes,
});

Future<_Device> _signIn(String name) async {
  final client = await openFirestoreEmulatorClient(name);
  final author = await signInToFirestoreEmulator(client.auth, client.firestore);
  return (
    posts: FirestorePostRepository(
      firestore: client.firestore,
      currentUser: author,
    ),
    likes: FirestoreLikeRepository(
      firestore: client.firestore,
      userId: author.id,
    ),
  );
}

void main() {
  registerFirestoreEmulatorPlugins();

  late _Device a;
  late _Device b;

  // seed-repository-fixtures.mjs가 likeCount 0인 fixture-01~45를 만든다.
  // 테스트끼리 서버 상태를 나누지 않도록 테스트마다 다른 글을 쓴다.
  setUpAll(() async {
    a = await _signIn('issue18-device-a');
    b = await _signIn('issue18-device-b');
  });

  test('좋아요를 누르면 개수가 1 늘고 다른 기기에서는 개수만 보인다', () async {
    // when
    final state = await a.likes.setLike('fixture-45', liked: true);

    // then
    expect(state, (liked: true, likeCount: 1));
    final mine = await a.posts.getPostById('fixture-45');
    final other = await b.posts.getPostById('fixture-45');
    expect((mine?.likedByMe, mine?.likeCount), (true, 1));
    expect((other?.likedByMe, other?.likeCount), (false, 1));
  });

  test('이미 누른 좋아요를 다시 보내면 개수가 바뀌지 않는다', () async {
    // given
    await a.likes.setLike('fixture-44', liked: true);

    // when
    final state = await a.likes.setLike('fixture-44', liked: true);

    // then
    expect(state, (liked: true, likeCount: 1));
    expect((await b.posts.getPostById('fixture-44'))?.likeCount, 1);
  });

  test('좋아요를 취소하면 개수가 돌아오고 다시 취소해도 0 아래로 내려가지 않는다', () async {
    // given
    await a.likes.setLike('fixture-43', liked: true);

    // when
    final cancelled = await a.likes.setLike('fixture-43', liked: false);
    final again = await a.likes.setLike('fixture-43', liked: false);

    // then
    expect(cancelled, (liked: false, likeCount: 0));
    expect(again, (liked: false, likeCount: 0));
    final post = await a.posts.getPostById('fixture-43');
    expect((post?.likedByMe, post?.likeCount), (false, 0));
  });

  test('두 기기가 동시에 좋아요를 누르면 둘 다 반영된다', () async {
    // when
    await Future.wait([
      a.likes.setLike('fixture-42', liked: true),
      b.likes.setLike('fixture-42', liked: true),
    ]);

    // then
    final mine = await a.posts.getPostById('fixture-42');
    final other = await b.posts.getPostById('fixture-42');
    expect((mine?.likedByMe, mine?.likeCount), (true, 2));
    expect((other?.likedByMe, other?.likeCount), (true, 2));
  });

  test('두 기기가 좋아요·취소를 빠르게 이어 보내면 마지막 상태대로 개수가 맞는다', () async {
    // given
    Future<void> toggle(_Device device, List<bool> states) async {
      for (final liked in states) {
        await device.likes.setLike('fixture-41', liked: liked);
      }
    }

    // when
    await Future.wait([
      toggle(a, [true, false, true]),
      toggle(b, [true, false, true, false]),
    ]);

    // then
    final mine = await a.posts.getPostById('fixture-41');
    final other = await b.posts.getPostById('fixture-41');
    expect((mine?.likedByMe, mine?.likeCount), (true, 1));
    expect((other?.likedByMe, other?.likeCount), (false, 1));
  });

  test('피드 페이지는 글마다 그 기기 사용자가 누른 좋아요만 표시한다', () async {
    // given
    await a.likes.setLike('fixture-40', liked: true);

    // when
    final mine = await a.posts.getPostPage();
    final other = await b.posts.getPostPage();

    // then
    bool likedIn(PostPage page, String id) =>
        page.posts.singleWhere((post) => post.id == id).likedByMe;
    expect(likedIn(mine, 'fixture-40'), isTrue);
    expect(likedIn(mine, 'fixture-39'), isFalse);
    expect(likedIn(other, 'fixture-40'), isFalse);
    // 페이지 조회와 단건 조회가 같은 글에 같은 선택 상태를 보여 준다.
    for (final post in mine.posts) {
      final single = await a.posts.getPostById(post.id);
      expect(post.likedByMe, single?.likedByMe, reason: post.id);
    }
  });

  test('없는 게시글에 좋아요를 보내면 null을 돌려준다', () async {
    // when
    final state = await a.likes.setLike('missing-post', liked: true);

    // then
    expect(state, isNull);
  });
}
