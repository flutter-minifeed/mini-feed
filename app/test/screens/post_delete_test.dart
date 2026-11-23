import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minifeed/main.dart';
import 'package:minifeed/models/author.dart';
import 'package:minifeed/models/post.dart';
import 'package:minifeed/repository/repository_scope.dart';
import 'package:minifeed/screens/detail_screen.dart';
import 'package:minifeed/viewmodels/write_view_model.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('내 글 삭제를 취소하면 서버 요청 없이 글이 남는다', (tester) async {
    // given
    final repo = await _openFeed(tester);
    await _confirmScreen(tester);

    // when
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    // then
    expect(repo.calls, 0);
    expect(find.text('글 0'), findsOneWidget);
  });

  testWidgets('피드 중간에서 삭제하면 해당 카드만 사라지고 위치가 유지된다', (tester) async {
    // given
    final repo = await _openFeed(tester, count: 30);
    final list = tester.widget<ListView>(find.byType(ListView)).controller!;
    list.jumpTo(900);
    await tester.pumpAndSettle();
    final menu = find.byTooltip('더보기').hitTestable().at(1);
    final offset = list.offset;
    final count = repo.posts.length;

    // when
    await _confirmScreen(tester, menu: menu);
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    // then
    expect(repo.posts.length, count - 1);
    expect(find.byKey(ValueKey(repo.deletedId)), findsNothing);
    expect(list.offset, offset);
  });

  testWidgets('삭제 거부 후 재시도가 가능하고 연속 탭은 한 번만 전송한다', (tester) async {
    // given
    final repo = await _openFeed(tester);
    repo.pending = Completer<bool>();
    await tester.tap(find.text('글 0'));
    await tester.pumpAndSettle();
    await _confirmScreen(tester);

    // when
    await tester.tap(find.text('삭제'));
    await tester.tap(find.text('삭제'));
    await tester.pump();
    expect(repo.calls, 1);
    repo.pending!.completeError(StateError('거부'));
    await tester.pumpAndSettle();

    // then
    expect(find.textContaining('글을 삭제하지 못했어요'), findsOneWidget);
    expect(repo.posts, hasLength(1));
    repo.pending = null;
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(repo.calls, 2);
    expect(find.byType(DetailScreen), findsNothing);
    expect(find.text('아직 게시글이 없습니다.'), findsOneWidget);
  });

  for (final comment in [false, true]) {
    final action = comment ? '댓글 전송' : '좋아요';
    testWidgets('타인 글에는 신고만 보이고 삭제 후 $action 시 확인하면 복귀한다', (tester) async {
      // given
      final repo = await _openFeed(tester, own: false);
      await tester.tap(find.text('글 0'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('더보기'));
      await tester.pumpAndSettle();
      expect(find.text('내 글 삭제'), findsNothing);
          expect(find.text('이 글 신고하기'), findsOneWidget);
          await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      repo.posts.clear();

      // when
      if (comment) {
        await tester.enterText(find.byType(TextField), '댓글');
            await tester.pump();
        await tester.tap(find.byTooltip('댓글 보내기'));
      } else {
        await tester.tap(find.byIcon(Icons.favorite_border));
      }
      await tester.pumpAndSettle();

      // then
      expect(find.text('삭제된 글이에요'), findsOneWidget);
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(find.byType(DetailScreen), findsNothing);
      expect(find.text('글 0'), findsNothing);
    });
  }
}

Future<void> _confirmScreen(WidgetTester tester, {Finder? menu}) async {
  await tester.tap(menu ?? find.byTooltip('더보기').first);
  await tester.pumpAndSettle();
  expect(find.text('이 글 신고하기'), findsNothing);
  await tester.tap(find.text('내 글 삭제'));
  await tester.pumpAndSettle();
  expect(find.text('이 글을 삭제할까요?'), findsOneWidget);
}

class _DeleteRepository extends FakePostRepository {
  int calls = 0;
  String? deletedId;
  Completer<bool>? pending;

  @override
  Future<bool> deletePost(String id) async {
    calls++;
    if (pending != null) return pending!.future;
    deletedId = id;
    posts.removeWhere((post) => post.id == id);
    return true;
  }
}

Future<_DeleteRepository> _openFeed(
  WidgetTester tester, {
  int count = 1,
  bool own = true,
}) async {
  final repo = _DeleteRepository();
  final author = own
      ? testUser
      : const Author(id: 'other', nickName: '다른 작성자', colorIndex: 1);
  for (var index = 0; index < count; index++) {
    repo.posts.add(
      Post(
        id: 'p$index',
        author: author,
        body: '글 $index',
        createdAt: DateTime(2026, 1, 1).subtract(Duration(minutes: index)),
        likeCount: 0,
        commentCount: 0,
        likedByMe: false,
      ),
    );
  }
  await tester.pumpWidget(
    RepositoryScope(
      postRepository: repo,
      commentRepository: FakeCommentRepository(),
      child: MyApp(
        createWriteViewModel: () => WriteViewModelImpl(repository: repo),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}
