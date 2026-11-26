import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:minifeed/main.dart';
import 'package:minifeed/models/author.dart';
import 'package:minifeed/models/comment.dart';
import 'package:minifeed/models/post.dart';
import 'package:minifeed/repository/offline_exception.dart';
import 'package:minifeed/repository/post/post_repository.dart';
import 'package:minifeed/repository/repository_scope.dart';
import 'package:minifeed/screens/detail_screen.dart';
import 'package:minifeed/viewmodels/write_view_model.dart';
import 'package:minifeed/widgets/offline_banner.dart';

import '../helpers/test_app.dart';

const _feedOffline = '오프라인이에요. 이전에 불러온 글을 보여주고 있어요.';
const _detailOffline = '오프라인이에요. 저장된 글만 보여주고 있어요.';
const _commentsOffline = '오프라인이라 댓글을 불러올 수 없어요. 연결되면 자동으로 다시 불러와요.';
const _reconnected = '다시 연결됐어요. 최신 글을 불러왔어요.';

/// 연결을 끊으면 그때까지 읽은 글만 캐시 페이지로 돌려주는 저장소.
/// Firestore 저장소가 연결 불가일 때 캐시로 다시 읽는 동작(#77 저장소)을 흉내 낸다.
class _OfflinePostRepository extends FakePostRepository {
  List<Post>? _cache;
  int pageRequests = 0;

  bool get offline => _cache != null;

  /// [nothingRead]면 한 번도 읽지 않은 첫 실행처럼 빈 캐시로 끊는다.
  void goOffline({bool nothingRead = false}) =>
      _cache = nothingRead ? const [] : [...posts];

  void goOnline() => _cache = null;

  @override
  Future<PostPage> getPostPage({PostCursor? after}) async {
    pageRequests++;
    final cache = _cache;
    if (cache == null) return super.getPostPage(after: after);
    final ordered = [...cache]..sort(comparePostsNewestFirst);
    final page = PostPage.fromOrderedPosts(ordered, after: after);
    return PostPage(page.posts, fromCache: true);
  }
}

/// 기기 캐시에 없는 글을 오프라인에서 열 때처럼 글 조회부터 실패하는 저장소.
class _UncachedPostRepository extends FakePostRepository {
  bool offline = true;

  @override
  Future<Post?> getPostById(String id) async {
    if (offline) throw const OfflineException();
    return super.getPostById(id);
  }
}

class _OfflineCommentRepository extends FakeCommentRepository {
  bool offline = false;

  @override
  Future<List<Comment>> getComments(String postId) async {
    if (offline) throw const OfflineException();
    return super.getComments(postId);
  }
}

Post _post(String id, String body, DateTime createdAt, {int comments = 0}) =>
    Post(
      id: id,
      author: const Author(id: 'user-1', nickName: '졸린 판다', colorIndex: 2),
      body: body,
      createdAt: createdAt,
      likeCount: 3,
      commentCount: comments,
      likedByMe: false,
    );

Future<void> _pumpFeed(
  WidgetTester tester,
  _OfflinePostRepository posts,
) async {
  await tester.pumpWidget(
    RepositoryScope(
      postRepository: posts,
      commentRepository: FakeCommentRepository(),
      child: MyApp(
        createWriteViewModel: () => WriteViewModelImpl(repository: posts),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _refresh(WidgetTester tester) async {
  tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show();
  await tester.pumpAndSettle();
}

double _feedOffset(WidgetTester tester) =>
    tester.widget<ListView>(find.byType(ListView)).controller!.offset;

void main() {
  final now = DateTime.now();

  testWidgets('피드를 읽은 뒤 연결을 끊고 새로고침하면 캐시 글과 오프라인 안내를 보여준다', (tester) async {
    // given
    final posts = _OfflinePostRepository()
      ..posts.add(_post('p1', '읽어 둔 글', now));
    await _pumpFeed(tester, posts);
    posts.goOffline();

    // when
    await _refresh(tester);

    // then
    expect(find.text(_feedOffline), findsOneWidget);
    expect(find.text('읽어 둔 글'), findsOneWidget);
    expect(find.text('새로고침하지 못했습니다. 다시 시도해 주세요.'), findsNothing);
  });

  testWidgets('오프라인이면 일정 시간 뒤 다시 조회하고 연결되면 안내와 새 글 칩을 띄우되 읽던 위치는 그대로다', (tester) async {
    // given: 25개를 읽고 아래로 내려간 뒤 연결이 끊긴 상태
    final posts = _OfflinePostRepository();
    for (var i = 0; i < 25; i++) {
      final createdAt = now.subtract(Duration(minutes: i + 1));
      posts.posts.add(_post('p$i', '글 $i', createdAt));
    }
    await _pumpFeed(tester, posts);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    final offset = _feedOffset(tester);
    posts.goOffline();
    await _refresh(tester);
    expect(find.text(_feedOffline), findsOneWidget);

    // when: 다른 기기에서 새 글이 올라오고 연결이 돌아온다
    posts.posts.add(_post('new', '새로 올라온 글', now));
    posts.goOnline();
    await tester.pump(offlineRetryInterval);
    await tester.pumpAndSettle();

    // then
    expect(find.text(_feedOffline), findsNothing);
    expect(find.text(_reconnected), findsOneWidget);
    expect(find.text('새 글 1개'), findsOneWidget);
    expect(_feedOffset(tester), offset);
  });

  testWidgets('오프라인 안내의 다시 시도를 누르면 기다리지 않고 바로 다시 조회한다', (tester) async {
    // given
    final posts = _OfflinePostRepository()
      ..posts.add(_post('p1', '읽어 둔 글', now));
    await _pumpFeed(tester, posts);
    posts.goOffline();
    await _refresh(tester);
    final before = posts.pageRequests;

    // when
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    // then
    expect(posts.pageRequests, before + 1);
  });

  testWidgets('첫 실행부터 캐시 없이 오프라인이면 강제 종료 없이 불러오지 못함 안내 후 연결되면 글을 보여준다', (tester) async {
    // given
    final posts = _OfflinePostRepository()
      ..posts.add(_post('p1', '서버에 있던 글', now))
      ..goOffline(nothingRead: true);

    // when
    await _pumpFeed(tester, posts);

    // then: 빈 피드로 오해하지 않게 불러오지 못함을 안내한다
    expect(tester.takeException(), isNull);
    expect(find.text('게시글을 불러오지 못했습니다.'), findsOneWidget);
    expect(find.text('아직 게시글이 없습니다.'), findsNothing);
    expect(find.text(_feedOffline), findsNothing);

    // when: 연결이 돌아온다
    posts.goOnline();
    await tester.pump(offlineRetryInterval);
    await tester.pumpAndSettle();

    // then
    expect(find.text('서버에 있던 글'), findsOneWidget);
    expect(find.text(_reconnected), findsOneWidget);
  });

  testWidgets('피드를 닫으면 오프라인 재조회를 멈춘다', (tester) async {
    // given
    final posts = _OfflinePostRepository()
      ..posts.add(_post('p1', '읽어 둔 글', now));
    await _pumpFeed(tester, posts);
    posts.goOffline();
    await _refresh(tester);
    final before = posts.pageRequests;

    // when
    await tester.pumpWidget(const SizedBox());
    await tester.pump(offlineRetryInterval * 2);

    // then
    expect(posts.pageRequests, before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('다음 페이지를 읽다 연결이 끊기면 캐시 글을 붙이지 않고 오프라인 안내 후 연결되면 이어 읽는다', (tester) async {
    // given: 첫 페이지 20개를 읽은 상태
    final posts = _OfflinePostRepository();
    for (var i = 0; i < 25; i++) {
      final createdAt = now.subtract(Duration(minutes: i + 1));
      posts.posts.add(_post('p$i', '글 $i', createdAt));
    }
    await _pumpFeed(tester, posts);
    posts.goOffline();

    // when: 끝까지 내려 다음 페이지를 요청한다
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pumpAndSettle();

    // then: 끝난 목록처럼 보이지 않고, 오프라인 안내와 다시 불러오기를 보여준다
    expect(find.text(_feedOffline), findsOneWidget);
    expect(find.text('다시 불러오기'), findsOneWidget);
    expect(find.text('글 20'), findsNothing);

    // when: 연결이 돌아온다
    posts.goOnline();
    await tester.pump(offlineRetryInterval);
    await tester.pumpAndSettle();
    // 조금 올렸다가 다시 끝까지 내려 다음 페이지를 다시 요청한다
    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pumpAndSettle();

    // then
    expect(find.text(_feedOffline), findsNothing);
    expect(find.text('글 20', skipOffstage: false), findsOneWidget);
  });

  testWidgets('재연결 안내가 떠 있을 때 상세로 들어가면 안내를 닫는다', (tester) async {
    // given: 오프라인이었다가 연결돼 피드에 재연결 안내가 떠 있다
    final posts = _OfflinePostRepository()
      ..posts.add(_post('p1', '읽어 둔 글', now));
    await _pumpFeed(tester, posts);
    posts.goOffline();
    await _refresh(tester);
    posts.goOnline();
    await tester.pump(offlineRetryInterval);
    await tester.pumpAndSettle();
    expect(find.text(_reconnected), findsOneWidget);

    // when
    await tester.tap(find.text('읽어 둔 글'));
    await tester.pumpAndSettle();

    // then
    expect(find.byType(DetailScreen), findsOneWidget);
    expect(find.text(_reconnected), findsNothing);
  });

  testWidgets('상세를 연 동안 피드가 다시 연결돼도 상세 위에 피드 안내를 띄우지 않는다', (tester) async {
    // given: 피드가 오프라인인 채로 상세를 연다
    final posts = _OfflinePostRepository()
      ..posts.add(_post('p1', '읽어 둔 글', now));
    await _pumpFeed(tester, posts);
    posts.goOffline();
    await _refresh(tester);
    await tester.tap(find.text('읽어 둔 글'));
    await tester.pumpAndSettle();
    final before = posts.pageRequests;

    // when: 피드의 재확인 시간이 지나 연결이 돌아온 것을 피드가 알아챈다
    posts.goOnline();
    await tester.pump(offlineRetryInterval);
    await tester.pumpAndSettle();

    // then: 피드는 뒤에서 다시 읽었지만 상세 위에 안내를 띄우지 않는다
    expect(posts.pageRequests, greaterThan(before));
    expect(find.byType(DetailScreen), findsOneWidget);
    expect(find.text(_reconnected), findsNothing);
  });

  testWidgets('오프라인 상세는 저장된 글과 댓글 조회 불가 안내를 보여주고 댓글 입력을 막는다', (tester) async {
    // when
    final comments = await _openDetail(tester, offline: true);

    // then
    expect(comments.offline, isTrue);
    expect(find.text(_detailOffline), findsOneWidget);
    expect(find.text('테스트 본문'), findsOneWidget);
    expect(find.text('댓글 4'), findsOneWidget); // 저장된 글의 댓글 수
    expect(find.text(_commentsOffline), findsOneWidget);
    expect(find.text('저장된 적 없는 댓글'), findsNothing);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.enabled, isFalse);
    expect(field.decoration?.hintText, '연결되면 댓글을 쓸 수 있어요');
  });

  testWidgets('오프라인 상세는 연결되면 댓글을 자동으로 다시 불러오고 입력을 연다', (tester) async {
    // given
    final comments = await _openDetail(tester, offline: true);

    // when
    comments.offline = false;
    await tester.pump(offlineRetryInterval);
    await tester.pumpAndSettle();

    // then
    expect(find.text(_detailOffline), findsNothing);
    expect(find.text(_commentsOffline), findsNothing);
    expect(find.text('저장된 적 없는 댓글'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
  });

  testWidgets('캐시에도 없는 글을 오프라인에서 열면 오프라인 안내 후 연결되면 자동으로 불러온다', (tester) async {
    // given
    final posts = _UncachedPostRepository()
      ..posts.add(_post('post-1', '캐시에 없던 글', now));
    await tester.pumpWidget(
      RepositoryScope(
        postRepository: posts,
        commentRepository: FakeCommentRepository(),
        child: const MaterialApp(home: DetailScreen(postId: 'post-1')),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('오프라인이라 게시글을 불러올 수 없어요. 연결되면 자동으로 다시 불러와요.'),
      findsOneWidget,
    );

    // when
    posts.offline = false;
    await tester.pump(offlineRetryInterval);
    await tester.pumpAndSettle();

    // then
    expect(find.text('캐시에 없던 글'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
  });
}

Future<_OfflineCommentRepository> _openDetail(
  WidgetTester tester, {
  required bool offline,
}) async {
  final now = DateTime.now();
  final posts = FakePostRepository()
    ..posts.add(
      _post(
        'post-1',
        '테스트 본문',
        now.subtract(const Duration(minutes: 12)),
        comments: 4,
      ),
    );
  final comments = _OfflineCommentRepository()
    ..offline = offline
    ..comments.add(
      Comment(
        id: 'comment-1',
        postId: 'post-1',
        author: const Author(id: 'user-2', nickName: '낮잠 자는 물개', colorIndex: 3),
        body: '저장된 적 없는 댓글',
        createdAt: now.subtract(const Duration(minutes: 10)),
      ),
    );
  await tester.pumpWidget(
    RepositoryScope(
      postRepository: posts,
      commentRepository: comments,
      child: const MaterialApp(home: DetailScreen(postId: 'post-1')),
    ),
  );
  await tester.pumpAndSettle();
  return comments;
}
