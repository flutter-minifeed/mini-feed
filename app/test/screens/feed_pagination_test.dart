import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minifeed/main.dart';
import 'package:minifeed/viewmodels/write_view_model.dart';
import 'package:minifeed/widgets/post_card.dart';
import 'package:minifeed/models/author.dart';
import 'package:minifeed/models/post.dart';
import 'package:minifeed/repository/comment/in_memory_comment_repository.dart';
import 'package:minifeed/repository/post/in_memory_post_repository.dart';
import 'package:minifeed/repository/post/post_repository.dart';
import 'package:minifeed/repository/repository_scope.dart';

void main() {
  testWidgets('45개 글은 20·20·5개로 빠짐과 중복 없이 표시된다', (tester) async {
    // given
    final repository = _repository(45);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    expect(repository.batches.single, hasLength(20));

    // when
    await _scrollToOldest(tester);

    // then
    expect(repository.batches.map((page) => page.length), [20, 20, 5]);
    final ids = repository.batches.expand((page) => page).toList();
    expect(ids, _expectedIds(45));
    expect(ids.toSet(), hasLength(45));
    expect(find.text('더 불러오기'), findsNothing);
  });

  testWidgets('정확히 40개면 다음 빈 페이지에서 조회를 끝낸다', (tester) async {
    // given
    final repository = _repository(40);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    // when
    await _scrollToOldest(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    // then
    expect(repository.batches.map((page) => page.length), [20, 20, 0]);
    expect(find.text('더 불러오기'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('다음 페이지 실패는 기존 글을 유지하고 같은 커서로 재시도한다', (tester) async {
    // given
    final repository = _repository(45);
    var fail = true;
    repository.readPage = (after) {
      if (after != null && fail) {
        fail = false;
        return Future.error(StateError('추가 조회 실패'));
      }
      return repository.original.getPostPage(after: after);
    };
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('다시 불러오기'), 500, maxScrolls: 50);
    final failedCursor = repository.requests.last;

    // when
    await tester.tap(find.text('다시 불러오기'));
    await tester.pumpAndSettle();

    // then
    expect(repository.requests[2], failedCursor);
    expect(repository.batches.take(2).map((page) => page.length), [20, 20]);
    _controller(tester).jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('게시글 44'), findsOneWidget);
  });

  testWidgets('페이지 조회 중 화면을 닫으면 늦은 실패가 화면 오류를 만들지 않는다', (tester) async {
    // given
    final repository = _repository(45);
    final pending = Completer<PostPage>();
    repository.readPage = (after) =>
        after == null ? repository.original.getPostPage() : pending.future;
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    final controller = _controller(tester);
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(repository.requests, hasLength(2));

    // when
    await tester.pumpWidget(const SizedBox());
    pending.completeError(StateError('화면이 닫힌 뒤 도착한 실패'));
    await tester.pumpAndSettle();

    // then
    expect(tester.takeException(), isNull);
  });

  testWidgets('새로고침 전에 시작한 추가 조회가 새 목록에 섞이지 않는다', (tester) async {
    // given
    final repository = _repository(45);
    final first = await repository.original.getPostPage();
    final oldPage = await repository.original.getPostPage(
      after: first.nextCursor,
    );
    final pending = Completer<PostPage>();
    repository.readPage = (after) =>
        after == null ? repository.original.getPostPage() : pending.future;
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    final controller = _controller(tester);
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(repository.requests, hasLength(2));
    await repository.original.addPost('새로고침한 최신 글');

    // when
    await _refresh(tester);
    pending.complete(oldPage);
    await tester.pumpAndSettle();
    await tester.tap(find.text('새 글 1개'));
    await tester.pumpAndSettle();

    // then: 새 첫 20개 + 연결된 기존 꼬리 1개 + 구분선 + 페이지 버튼
    expect(find.text('새로고침한 최신 글'), findsOneWidget);
    expect(
      tester
          .widget<ListView>(find.byType(ListView))
          .childrenDelegate
          .estimatedChildCount,
      23,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('이미 읽은 45개를 새로고침해도 목록과 읽던 위치가 유지된다', (tester) async {
    // given
    final repository = _repository(45);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await _scrollToOldest(tester);
    final controller = _controller(tester);
    controller.jumpTo(controller.position.maxScrollExtent / 2);
    await tester.pumpAndSettle();
    final offset = controller.offset;

    // when
    await _refresh(tester);

    // then
    expect(
      tester
          .widget<ListView>(find.byType(ListView))
          .childrenDelegate
          .estimatedChildCount,
      45,
    );
    expect(controller.offset, closeTo(offset, 0.01));
    expect(repository.requests.where((cursor) => cursor == null), hasLength(2));
  });

  testWidgets('새 글이 21개면 다음 페이지의 새 글까지 강조하고 경계를 표시한다', (tester) async {
    // given
    final repository = _repository(45);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    final added = <Post>[];
    for (var i = 0; i < 21; i++) {
      added.add(await repository.addPost('새 글 $i'));
    }

    // when
    await _refresh(tester);
    expect(find.text('새 글 20개 이상'), findsOneWidget);
    await tester.tap(find.text('새 글 20개 이상'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(ValueKey(added.first.id)),
      500,
      maxScrolls: 60,
    );
    await tester.pumpAndSettle();

    // then
    final lastNew = tester.widget<PostCard>(
      find.byKey(ValueKey(added.first.id)),
    );
    expect(lastNew.highlighted, isTrue);
    expect(find.text('여기까지 새 글 · 이전에 보던 글'), findsOneWidget);
  });

  testWidgets('새 글을 적용하고 여러 페이지를 읽은 뒤 취소해도 목록과 위치가 유지된다', (tester) async {
    // given
    final repository = _repository(45);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await repository.addPost('새로 적용한 글');
    await _refresh(tester);
    await tester.tap(find.text('새 글 1개'));
    await tester.pumpAndSettle();
    await _scrollToOldest(tester);
    final controller = _controller(tester);
    final before = controller.offset;
    final readsBefore = repository.requests.length;
    await tester.tap(find.byTooltip('글쓰기'));
    await tester.pumpAndSettle();

    // when
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    // then
    expect(
      tester
          .widget<ListView>(find.byType(ListView))
          .childrenDelegate
          .estimatedChildCount,
      47, // 46개 글과 새 글 구분선
    );
    expect(repository.requests, hasLength(readsBefore));
    expect(controller.offset, closeTo(before, 0.01));
    expect(find.text('게시글 0'), findsOneWidget);
  });

  testWidgets('기존 목록과 겹치지 않는 첫 페이지는 게시 후에도 중간 글을 건너뛰지 않는다', (tester) async {
    // given: 기존 세 글은 한 페이지여서 다음 커서가 없다.
    final repository = _repository(3);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('글쓰기'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 23; i++) {
      await repository.addPost('다른 기기에서 쓴 글 $i');
    }

    // when
    await tester.enterText(find.byType(TextField), '내가 방금 쓴 글');
    await tester.pump();
    await tester.tap(find.text('게시'));
    await tester.pumpAndSettle();
    expect(find.text('내가 방금 쓴 글'), findsOneWidget);
    await _scrollToOldest(tester);

    // then: 게시 뒤 서버에서 읽은 모든 페이지가 실제 저장 순서와 일치한다.
    final expected = (await repository.getPosts()).map((post) => post.id);
    expect(
      repository.batches.skip(1).expand((page) => page),
      orderedEquals(expected),
    );
  });

  testWidgets('새로고침 도중 새 글 알림을 눌러도 다음 페이지를 읽는다', (tester) async {
    // given: 알림을 띄운 뒤 두 번째 새로고침의 응답만 지연한다.
    final repository = _repository(45);
    final oldPage = await repository.original.getPostPage();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await repository.addPost('알림으로 적용한 새 글');
    await _refresh(tester);
    final pending = Completer<PostPage>();
    repository.readPage = (after) => after == null
        ? pending.future
        : repository.original.getPostPage(after: after);
    final refresh = tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    await tester.pump();

    // when
    await tester.tap(find.text('새 글 1개'));
    await tester.pump();
    pending.complete(oldPage);
    await refresh;
    await tester.pumpAndSettle();

    // then
    expect(find.text('알림으로 적용한 새 글'), findsOneWidget);
    final controller = _controller(tester);
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(repository.requests.whereType<PostCursor>(), isNotEmpty);
    await _scrollToOldest(tester);
    expect(find.text('게시글 0'), findsOneWidget);
  });

  testWidgets('상세에 다시 들어가면 같은 ID의 글을 새로 조회한다', (tester) async {
    // given
    final repository = _repository(1);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('body-post-00')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    repository.detailBody = '서버에서 바뀐 본문';

    // when
    await tester.tap(find.byKey(const ValueKey('body-post-00')));
    await tester.pumpAndSettle();

    // then
    expect(repository.detailReads, 2);
    expect(find.text('서버에서 바뀐 본문'), findsOneWidget);
  });
}

const _author = Author(id: 'user-test', nickName: '테스트 펭귄', colorIndex: 0);

_PageRepository _repository(int count) {
  final rows = List.generate(
    count,
    (index) => {
      'id': "post-${index.toString().padLeft(2, '0')}",
      'authorId': _author.id,
      'nickName': _author.nickName,
      'colorIndex': _author.colorIndex,
      'body': '게시글 $index',
      'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
      'likeCount': 0,
      'commentCount': 0,
      'likedByMe': false,
    },
  );
  return _PageRepository(
    InMemoryPostRepository.fromJsonString(
      jsonEncode(rows),
      currentUser: _author,
    ),
  );
}

List<String> _expectedIds(int count) => List.generate(
  count,
  (index) => "post-${(count - index - 1).toString().padLeft(2, '0')}",
);

Widget _app(PostRepository repository) => RepositoryScope(
  postRepository: repository,
  commentRepository: InMemoryCommentRepository.fromJsonString('[]'),
  child: MyApp(
    createWriteViewModel: () => WriteViewModelImpl(repository: repository),
  ),
);

ScrollController _controller(WidgetTester tester) =>
    tester.widget<ListView>(find.byType(ListView)).controller!;

Future<void> _scrollToOldest(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const ValueKey('body-post-00')),
    500,
    maxScrolls: 50,
  );
  await tester.pumpAndSettle();
}

Future<void> _refresh(WidgetTester tester) async {
  final future = tester
      .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
      .show();
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  await future;
}

/// 지연·실패만 제어하고 문서 커서 정렬은 실제 메모리 구현을 사용한다.
class _PageRepository implements PostRepository {
  _PageRepository(this.original);
  final InMemoryPostRepository original;
  final requests = <PostCursor?>[];
  final batches = <List<String>>[];
  Future<PostPage> Function(PostCursor? after)? readPage;
  int detailReads = 0;
  String? detailBody;

  @override
  Author get currentUser => original.currentUser;
  @override
  Future<List<Post>> getPosts() => original.getPosts();
  @override
  Future<Post> addPost(String body, {String? requestId}) =>
      original.addPost(body, requestId: requestId);
  @override
  Future<PostPage> getPostPage({PostCursor? after}) async {
    requests.add(after);
    final page =
        await (readPage?.call(after) ?? original.getPostPage(after: after));
    batches.add(page.posts.map((post) => post.id).toList());
    return page;
  }

  @override
  Future<Post?> getPostById(String id) async {
    detailReads++;
    final post = await original.getPostById(id);
    if (post == null || detailBody == null) return post;
    return Post(
      id: post.id,
      author: post.author,
      body: detailBody!,
      createdAt: post.createdAt,
      likeCount: post.likeCount,
      commentCount: post.commentCount,
      likedByMe: post.likedByMe,
    );
  }
}
