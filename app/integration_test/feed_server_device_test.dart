import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minifeed/main.dart';
import 'package:minifeed/viewmodels/write_view_model.dart';
import 'package:minifeed/models/author.dart';
import 'package:minifeed/repository/comment/firestore_comment_repository.dart';
import 'package:minifeed/repository/post/firestore_post_repository.dart';
import 'package:minifeed/repository/repository_scope.dart';
import 'package:minifeed/service/auth/firebase_auth_service.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('USB 기기에서 서버 페이지·상세·새 글 알림을 연결한다', (tester) async {
    // given: 로컬 데모 서버를 seed-repository-fixtures.mjs로 초기화한다.
    // USB에서는 adb reverse로 8080·9099 포트를 연결한다.
    final reader = await _openClient('issue13-reader');
    final writer = await _openClient('issue13-writer');
    addTearDown(() async {
      await reader.auth.signOut();
      await writer.auth.signOut();
      await reader.firestore.terminate();
      await writer.firestore.terminate();
    });
    final posts = FirestorePostRepository(
      firestore: reader.firestore,
      currentUser: reader.author,
    );
    final comments = FirestoreCommentRepository(firestore: reader.firestore);
    final writerPosts = FirestorePostRepository(
      firestore: writer.firestore,
      currentUser: writer.author,
    );

    // when: 네이티브 SDK로 같은 시각의 45개 글을 문서 커서로 조회한다.
    final first = await posts.getPostPage();
    final second = await posts.getPostPage(after: first.nextCursor);
    final third = await posts.getPostPage(after: second.nextCursor);

    // then
    expect(
      [first.posts.length, second.posts.length, third.posts.length],
      [20, 20, 5],
    );
    expect(third.nextCursor, isNull);
    final ids = [
      ...first.posts,
      ...second.posts,
      ...third.posts,
    ].map((post) => post.id).toList();
    expect(ids.toSet(), hasLength(45));
    expect(
      ids,
      List.generate(
        45,
        (index) => "fixture-${(45 - index).toString().padLeft(2, '0')}",
      ),
    );
    expect(await posts.getPostById('missing-fixture'), isNull);
    expect(await comments.getComments('fixture-44'), isEmpty);
    expect(
      (await comments.getComments('fixture-45')).map((comment) => comment.body),
      ['먼저 쓴 댓글', '나중에 쓴 댓글'],
    );
    debugPrint(
      '[#13] native pages 20 -> 20 -> 5; unique=45; missing=null; comments ordered',
    );

    // when: 다른 익명 클라이언트가 같은 로컬 서버에 새 글을 작성한다.
    await tester.pumpWidget(
      RepositoryScope(
        postRepository: posts,
        commentRepository: comments,
        child: MyApp(
          createWriteViewModel: () => WriteViewModelImpl(repository: posts),
        ),
      ),
    );
    await _settle(tester);
    expect(find.text('게시글 45'), findsOneWidget);
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('01_feed_server');
    await writerPosts.addPost('로컬 에뮬레이터에서 작성한 새 글');
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await _settle(tester);

    // then: 알림을 누를 때 새 목록·구분선과 최상단을 표시한다.
    expect(find.text('새 글 1개'), findsOneWidget);
    expect(find.text('로컬 에뮬레이터에서 작성한 새 글'), findsNothing);
    await binding.takeScreenshot('02_new_posts_chip');
    await tester.tap(find.text('새 글 1개'));
    await tester.pumpAndSettle();
    expect(find.text('로컬 에뮬레이터에서 작성한 새 글'), findsOneWidget);
    expect(find.text('여기까지 새 글 · 이전에 보던 글'), findsOneWidget);
    await binding.takeScreenshot('03_new_posts_applied');
    debugPrint(
      '[#13] second client write -> refresh -> chip -> new post at top',
    );

    // when: 본문으로 상세에 진입한다.
    await tester.tap(find.text('로컬 에뮬레이터에서 작성한 새 글'));
    await _settle(tester);

    // then
    expect(find.text('게시글'), findsOneWidget);
    expect(find.text('로컬 에뮬레이터에서 작성한 새 글'), findsOneWidget);
    expect(find.text('댓글 0'), findsOneWidget);
    await binding.takeScreenshot('04_detail_server');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('게시글 1'), 500, maxScrolls: 60);
    await tester.pumpAndSettle();
    final controller = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;
    final beforeCancel = controller.offset;
    await tester.tap(find.byTooltip('글쓰기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CloseButton));
    await _settle(tester);
    expect(controller.offset, closeTo(beforeCancel, 0.01));
    expect(find.text('게시글 1'), findsOneWidget);
    debugPrint(
      '[#13] cancel writing preserved loaded pages and scroll position',
    );
    await binding.takeScreenshot('05_feed_end');
    debugPrint('[#13] detail same body; comments=0; last fixture visible');
  }, timeout: const Timeout(Duration(minutes: 3)));
}

Future<void> _settle(WidgetTester tester) => tester.pumpAndSettle(
  const Duration(milliseconds: 100),
  EnginePhase.sendSemanticsUpdate,
  const Duration(seconds: 30),
);

typedef _Client = ({
  FirebaseAuth auth,
  FirebaseFirestore firestore,
  Author author,
});

Future<_Client> _openClient(String name) async {
  final app = await Firebase.initializeApp(
    name: name,
    options: FirebaseOptions(
      // 로컬 에뮬레이터 전용 가짜 키. 실제 설정값을 사용하지 않는다.
      apiKey: 'AIzaSy'.padRight(39, 'A'),
      appId: '1:123456789012:android:1234567890123456',
      messagingSenderId: '123456789012',
      projectId: 'demo-minifeed-repositories',
    ),
  );
  final auth = FirebaseAuth.instanceFor(app: app);
  await auth.useAuthEmulator('127.0.0.1', 9099, automaticHostMapping: false);
  await auth.signOut();
  final firestore = FirebaseFirestore.instanceFor(app: app);
  firestore.settings = const Settings(persistenceEnabled: false);
  firestore.useFirestoreEmulator(
    '127.0.0.1',
    8080,
    automaticHostMapping: false,
  );
  final profile = await FirebaseAuthService(
    auth: auth,
    firestore: firestore,
    initialize: () async {},
  ).signIn();
  return (auth: auth, firestore: firestore, author: profile.author);
}
