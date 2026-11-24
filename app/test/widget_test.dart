import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:minifeed/main.dart';
import 'package:minifeed/models/author.dart';
import 'package:minifeed/models/post.dart';
import 'package:minifeed/repository/comment/in_memory_comment_repository.dart';
import 'package:minifeed/repository/post/in_memory_post_repository.dart';
import 'package:minifeed/repository/post/post_repository.dart';
import 'package:minifeed/repository/repository_scope.dart';
import 'package:minifeed/screens/detail_screen.dart';
import 'package:minifeed/widgets/post_card.dart';
import 'package:minifeed/viewmodels/write_view_model.dart';

import 'helpers/test_app.dart';

void main() {
  testWidgets('앱을 켜면 저장소의 게시글과 작성자, 상대 시간이 보인다', (tester) async {
    // given
    final repository = _repository();

    // when
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    // then
    expect(find.text('미니피드'), findsOneWidget);
    expect(find.text('게시글 0 본문'), findsOneWidget);
    expect(find.text('테스트 펭귄'), findsWidgets);
    expect(find.text('5분 전'), findsOneWidget);
    final card = tester.widget<PostCard>(find.byType(PostCard).first);
    expect(card.post.likeCount, 3);
    expect(card.post.commentCount, 2);
  });

  testWidgets('본문을 누르면 게시글 ID와 일반 진입을 상세로 전달한다', (tester) async {
    // given
    await tester.pumpWidget(_app(_repository()));
    await tester.pumpAndSettle();

    // when
    await tester.tap(find.byKey(const ValueKey('body-post-0')));
    await tester.pumpAndSettle();

    // then
    final detail = tester.widget<DetailScreen>(find.byType(DetailScreen));
    expect(detail.postId, 'post-0');
    expect(detail.focusComment, isFalse);
    expect(find.text('게시글'), findsOneWidget);
    expect(find.text('게시글 0 본문'), findsOneWidget);
    final input = tester.widget<TextField>(find.byType(TextField));
    expect(input.focusNode!.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('댓글을 누르면 해당 게시글의 댓글 진입을 상세로 전달한다', (tester) async {
    // given
    await tester.pumpWidget(_app(_repository()));
    await tester.pumpAndSettle();

    // when
    await tester.tap(find.byKey(const ValueKey('comments-post-0')));
    await tester.pumpAndSettle();

    // then
    final detail = tester.widget<DetailScreen>(find.byType(DetailScreen));
    expect(detail.postId, 'post-0');
    expect(detail.focusComment, isTrue);
    expect(find.text('게시글'), findsOneWidget);
    expect(find.text('게시글 0 본문'), findsOneWidget);
    final input = tester.widget<TextField>(find.byType(TextField));
    expect(input.focusNode!.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('상세 화면에서 화살표를 누르면 피드로 돌아온다', (tester) async {
    // given
    await pumpApp(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('글쓰기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '게시글 0 본문');
    await tester.pump();
    await tester.tap(find.text('게시'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('게시글 0 본문'));
    await tester.pumpAndSettle();

    expect(find.byType(DetailScreen), findsOneWidget);

    // when
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // then
    expect(find.text('미니피드'), findsOneWidget);
    expect(find.text('게시글 0 본문'), findsOneWidget);
  });

  testWidgets('글쓰기에서 새 글이 저장된 뒤 돌아오면 맨 위에 표시된다', (tester) async {
    // given: 아래로 스크롤한 피드에서 글쓰기 진입
    final repository = _repository();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('글쓰기'));
    await tester.pumpAndSettle();

    // when: 글쓰기 화면의 실제 게시 결과로 돌아온다.
    await tester.enterText(find.byType(TextField), '방금 작성한 글');
    await tester.pump();
    await tester.tap(find.text('게시'));
    await tester.pumpAndSettle();

    // then
    expect(find.text('방금 작성한 글'), findsOneWidget);
    final card = tester.widget<PostCard>(find.byType(PostCard).first);
    expect(card.post.body, '방금 작성한 글');
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scroll.position.pixels, 0);
    expect(find.text('방금 전'), findsOneWidget);
  });

  testWidgets('글을 추가하지 않고 글쓰기를 닫으면 스크롤 위치가 유지된다', (tester) async {
    // given
    await tester.pumpWidget(_app(_repository()));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
    final previousOffset = scroll.position.pixels;
    await tester.tap(find.byTooltip('글쓰기'));
    await tester.pumpAndSettle();

    // when
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    // then
    expect(scroll.position.pixels, previousOffset);
  });

  testWidgets('시간 초과 뒤 늦게 저장된 글은 글쓰기를 버리고 닫아도 피드에 보인다', (tester) async {
    // given
    final repository = await pumpApp(tester);
    await tester.pumpAndSettle();
    final lateSave = Completer<void>();
    repository.blockAddUntil = lateSave;
    await tester.tap(find.byTooltip('글쓰기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '늦게 저장된 글');
    await tester.pump();
    await tester.tap(find.text('게시'));
    await tester.pump(const Duration(seconds: 10));
    lateSave.complete();
    await tester.pumpAndSettle();

    // when
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('버리기'));
    await tester.pumpAndSettle();

    // then
    final card = tester.widget<PostCard>(find.byType(PostCard).first);
    expect(card.post.body, '늦게 저장된 글');
  });

  testWidgets('목록 조회에 실패한 상태에서 게시하면 오류 대신 새 글이 보인다', (tester) async {
    // given
    final repository = _ReadOverrideRepository(
      _repository(),
      () async => throw StateError('목록 조회 실패'),
    );
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    final errorShownBeforePost = find
        .text('게시글을 불러오지 못했습니다.')
        .evaluate()
        .isNotEmpty;
    await tester.tap(find.byTooltip('글쓰기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '방금 저장한 글');
    await tester.pump();

    // when
    await tester.tap(find.text('게시'));
    await tester.pumpAndSettle();

    // then
    expect(errorShownBeforePost, isTrue);
    expect(find.text('게시글을 불러오지 못했습니다.'), findsNothing);
    final card = tester.widget<PostCard>(find.byType(PostCard).first);
    expect(card.post.body, '방금 저장한 글');
  });

  testWidgets('피드를 스크롤하면 마지막 게시글도 표시된다', (tester) async {
    // given
    await tester.pumpWidget(_app(_repository()));
    await tester.pumpAndSettle();

    // when
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('body-post-11')),
      500,
    );

    // then
    expect(find.text('게시글 11 본문'), findsOneWidget);
  });

  testWidgets('게시글이 없으면 빈 목록 안내가 표시된다', (tester) async {
    // given
    final repository = _repository(count: 0);

    // when
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    // then
    expect(find.text('아직 게시글이 없습니다.'), findsOneWidget);
  });

  testWidgets('조회 실패 후 다시 시도하면 게시글이 표시된다', (tester) async {
    // given: 첫 조회만 실패하는 저장소
    final original = _repository();
    var firstRead = true;
    final repository = _ReadOverrideRepository(original, () async {
      if (firstRead) {
        firstRead = false;
        throw StateError('테스트용 조회 실패');
      }
      return original.getPosts();
    });
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    expect(find.text('게시글을 불러오지 못했습니다.'), findsOneWidget);

    // when
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    // then
    expect(find.text('게시글 0 본문'), findsOneWidget);
    expect(find.text('게시글을 불러오지 못했습니다.'), findsNothing);
  });

  testWidgets('피드를 당기면 기존 글을 유지하고 조회가 끝난 뒤 새 글이 표시된다', (tester) async {
    // given
    final original = _repository();
    final pending = Completer<List<Post>>();
    var reads = 0;
    final repository = _ReadOverrideRepository(original, () {
      reads++;
      return reads == 1 ? original.getPosts() : pending.future;
    });
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await original.addPost('새로고침으로 가져온 글');

    // when
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // then
    expect(reads, 2);
    expect(find.text('게시글 0 본문'), findsOneWidget);
    expect(find.text('새로고침으로 가져온 글'), findsNothing);
    expect(find.byType(RefreshProgressIndicator), findsOneWidget);
    // 응답 대기 중 다시 당겨도 조회를 중복 실행하지 않는다.
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pump();
    expect(reads, 2);
    pending.complete(await original.getPosts());
    await tester.pumpAndSettle();
    expect(find.text('새 글 1개'), findsOneWidget);
    await tester.tap(find.text('새 글 1개'));
    await tester.pumpAndSettle();
    expect(find.text('새로고침으로 가져온 글'), findsOneWidget);
    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });

  testWidgets('화면보다 짧은 피드도 당기면 새 글을 가져온다', (tester) async {
    // given
    final repository = _repository(count: 1);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await repository.addPost('짧은 피드에 추가한 글');

    // when
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pumpAndSettle();

    // then
    expect(find.text('새 글 1개'), findsOneWidget);
    await tester.tap(find.text('새 글 1개'));
    await tester.pumpAndSettle();
    expect(find.text('짧은 피드에 추가한 글'), findsOneWidget);
    expect(find.text('게시글 0 본문'), findsOneWidget);
  });

  testWidgets('빈 피드를 당기면 새로 추가된 글이 표시된다', (tester) async {
    // given
    final repository = _repository(count: 0);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    expect(find.text('아직 게시글이 없습니다.'), findsOneWidget);
    await repository.addPost('빈 피드에서 가져온 글');

    // when
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
    await tester.pumpAndSettle();

    // then
    expect(find.text('빈 피드에서 가져온 글'), findsOneWidget);
    expect(find.text('아직 게시글이 없습니다.'), findsNothing);
  });

  testWidgets('새로고침이 실패하면 기존 글과 안내가 보이고 다시 당기면 갱신된다', (tester) async {
    // given
    final original = _repository();
    var reads = 0;
    final repository = _ReadOverrideRepository(original, () async {
      reads++;
      if (reads == 2) throw StateError('테스트용 새로고침 실패');
      return original.getPosts();
    });
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await original.addPost('재시도 후 가져온 글');

    // when
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pumpAndSettle();

    // then
    expect(find.text('게시글 0 본문'), findsOneWidget);
    expect(find.text('새로고침하지 못했습니다. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('재시도 후 가져온 글'), findsNothing);
    expect(find.text('게시글을 불러오지 못했습니다.'), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(reads, 3);
    await tester.tap(find.text('새 글 1개'));
    await tester.pumpAndSettle();
    expect(find.text('재시도 후 가져온 글'), findsOneWidget);
  });

  testWidgets('첫 조회가 실패해도 화면을 당기면 다시 조회한다', (tester) async {
    // given
    final original = _repository();
    var reads = 0;
    final repository = _ReadOverrideRepository(original, () async {
      reads++;
      if (reads == 1) throw StateError('테스트용 첫 조회 실패');
      return original.getPosts();
    });
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    expect(find.text('게시글을 불러오지 못했습니다.'), findsOneWidget);

    // when
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
    await tester.pumpAndSettle();

    // then
    expect(reads, 2);
    expect(find.text('게시글 0 본문'), findsOneWidget);
    expect(find.text('게시글을 불러오지 못했습니다.'), findsNothing);
  });

  testWidgets('새로고침 중 화면이 닫혀도 늦은 응답이 오류를 만들지 않는다', (tester) async {
    // given
    final original = _repository();
    final pending = Completer<List<Post>>();
    var reads = 0;
    final repository = _ReadOverrideRepository(original, () {
      reads++;
      return reads == 1 ? original.getPosts() : pending.future;
    });
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(reads, 2);

    // when
    await tester.pumpWidget(const SizedBox());
    pending.completeError(StateError('화면 종료 뒤 도착한 조회 실패'));
    await tester.pumpAndSettle();

    // then
    expect(tester.takeException(), isNull);
  });

  testWidgets('새 글 알림은 읽던 위치를 유지하고 누르면 새 글과 구분선이 보인다', (tester) async {
    // given
    final original = _repository();
    final pending = Completer<List<Post>>();
    var reads = 0;
    final repository = _ReadOverrideRepository(original, () {
      reads++;
      return reads == 1 ? original.getPosts() : pending.future;
    });
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await original.addPost('알림으로 가져온 글');
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump(const Duration(seconds: 1));
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
    final previousOffset = scroll.position.pixels;
    expect(previousOffset, greaterThan(0));

    // when
    pending.complete(await original.getPosts());
    await tester.pumpAndSettle();

    // then
    expect(find.text('새 글 1개'), findsOneWidget);
    expect(find.text('알림으로 가져온 글'), findsNothing);
    expect(scroll.position.pixels, previousOffset);
    await tester.tap(find.text('새 글 1개'));
    await tester.pumpAndSettle();
    expect(scroll.position.pixels, 0);
    expect(find.text('알림으로 가져온 글'), findsOneWidget);
    expect(find.text('새 글 1개'), findsNothing);
    expect(find.text('여기까지 새 글 · 이전에 보던 글'), findsOneWidget);
    final card = tester.widget<PostCard>(find.byType(PostCard).first);
    expect(card.highlighted, isTrue);
  });

  testWidgets('같은 새 글을 다시 조회해도 알림 개수가 중복되지 않는다', (tester) async {
    // given
    final repository = _repository();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await repository.addPost('새 글 하나');
    await repository.addPost('새 글 둘');

    // when
    for (var i = 0; i < 2; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, 400));
      await tester.pumpAndSettle();
    }

    // then
    expect(find.text('새 글 2개'), findsOneWidget);
    expect(find.text('새 글 하나'), findsNothing);
    await tester.tap(find.text('새 글 2개'));
    await tester.pumpAndSettle();
    final cards = tester.widgetList<PostCard>(find.byType(PostCard)).toList();
    expect(cards.take(2).map((card) => card.post.body), ['새 글 둘', '새 글 하나']);
    expect(cards.take(2).every((card) => card.highlighted), isTrue);
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(find.text('새 글 2개'), findsNothing);
    expect(find.text('여기까지 새 글 · 이전에 보던 글'), findsNothing);
  });

  testWidgets('글 게시 후 먼저 끝난 조회를 늦은 새로고침 응답이 덮어쓰지 않는다', (tester) async {
    // given
    final original = _repository();
    final pending = Completer<List<Post>>();
    final oldPosts = await original.getPosts();
    var reads = 0;
    final repository = _ReadOverrideRepository(original, () {
      reads++;
      return reads == 2 ? pending.future : original.getPosts();
    });
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byTooltip('글쓰기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '늦은 응답보다 최신 글');
    await tester.pump();
    await tester.tap(find.text('게시'));
    await tester.pump(const Duration(seconds: 1));
    expect(reads, 3);
    final saved = (await original.getPosts()).singleWhere(
      (post) => post.body == '늦은 응답보다 최신 글',
    );
    expect(find.byKey(ValueKey('body-${saved.id}')), findsOneWidget);

    // when
    pending.complete(oldPosts);
    await tester.pumpAndSettle();

    // then
    expect(find.text('늦은 응답보다 최신 글'), findsOneWidget);
    expect(find.text('새 글 1개'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('조회 중 화면이 닫혀도 늦은 응답이 오류를 만들지 않는다', (tester) async {
    // given
    final pending = Completer<List<Post>>();
    final repository = _ReadOverrideRepository(
      _repository(),
      () => pending.future,
    );
    await tester.pumpWidget(_app(repository));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const SizedBox());

    // when
    pending.complete(const []);
    await tester.pumpAndSettle();

    // then
    expect(tester.takeException(), isNull);
  });
}

const _me = Author(id: 'user-me', nickName: '테스트 펭귄', colorIndex: 4);

InMemoryPostRepository _repository({int count = 12}) {
  final now = DateTime.now();
  final json = List.generate(
    count,
    (index) => {
      'id': 'post-$index',
      'authorId': _me.id,
      'nickName': _me.nickName,
      'colorIndex': _me.colorIndex,
      'body': '게시글 $index 본문',
      'createdAt': now.subtract(Duration(minutes: index + 5)).toIso8601String(),
      'likeCount': 3,
      'commentCount': 2,
      'likedByMe': false,
    },
  );
  return InMemoryPostRepository.fromJsonString(
    jsonEncode(json),
    currentUser: _me,
  );
}

Widget _app(PostRepository repository) {
  return RepositoryScope(
    postRepository: repository,
    commentRepository: InMemoryCommentRepository.fromJsonString('[]'),
    child: MyApp(
      createWriteViewModel: () => WriteViewModelImpl(repository: repository),
    ),
  );
}

/// 조회의 실패·지연만 바꾸고 나머지는 실제 메모리 저장소에 위임한다.
class _ReadOverrideRepository implements PostRepository {
  _ReadOverrideRepository(this.original, this.read);

  final PostRepository original;
  final Future<List<Post>> Function() read;

  @override
  Author get currentUser => original.currentUser;

  @override
  Future<List<Post>> getPosts() => read();

  @override
  Future<PostPage> getPostPage({PostCursor? after}) async =>
      PostPage.fromOrderedPosts(await read(), after: after);

  @override
  Future<Post?> getPostById(String id) => original.getPostById(id);

  @override
  Future<Post> addPost(String body, {String? requestId}) =>
      original.addPost(body, requestId: requestId);
}
