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
    await tester.pumpWidget(_app(_repository()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('body-post-0')));
    await tester.pumpAndSettle();

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

    // when: #8의 저장 동작을 같은 공통 저장소로 재현
    await repository.addPost('방금 작성한 글');
    await tester.tap(find.byType(CloseButton));
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
    child: const MyApp(),
  );
}

/// 조회의 실패·지연만 바꾸고 나머지는 실제 메모리 저장소에 위임한다.
class _ReadOverrideRepository implements PostRepository {
  _ReadOverrideRepository(this.original, this.read);

  final PostRepository original;
  final Future<List<Post>> Function() read;

  @override
  Future<List<Post>> getPosts() => read();

  @override
  Future<Post?> getPostById(String id) => original.getPostById(id);

  @override
  Future<Post> addPost(String body) => original.addPost(body);
}
