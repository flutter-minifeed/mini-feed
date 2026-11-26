import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minifeed/main.dart';
import 'package:minifeed/models/author.dart';
import 'package:minifeed/repository/comment/firestore_comment_repository.dart';
import 'package:minifeed/repository/post/firestore_post_repository.dart';
import 'package:minifeed/repository/repository_scope.dart';
import 'package:minifeed/service/auth/firebase_auth_service.dart';
import 'package:minifeed/viewmodels/write_view_model.dart';
import 'package:minifeed/widgets/offline_banner.dart';

const _feedOffline = '오프라인이에요. 이전에 불러온 글을 보여주고 있어요.';
const _detailOffline = '오프라인이에요. 저장된 글만 보여주고 있어요.';
const _commentsOffline = '오프라인이라 댓글을 불러올 수 없어요. 연결되면 자동으로 다시 불러와요.';
const _reconnected = '다시 연결됐어요. 최신 글을 불러왔어요.';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('USB 기기에서 연결을 끊고 다시 이을 때 피드·상세 오프라인 화면을 확인한다', (
    tester,
  ) async {
    // given: 로컬 데모 서버를 seed-repository-fixtures.mjs로 초기화한다.
    // USB에서는 adb reverse로 8080·9099 포트를 연결한다.
    // 비행기 모드는 USB 포트 연결을 끊지 않아서, 앱 쪽 연결만 disableNetwork로 끊는다.
    final reader = await _openClient('issue15-reader', persistent: true);
    final writer = await _openClient('issue15-writer');
    addTearDown(() async {
      await reader.firestore.enableNetwork();
      await reader.auth.signOut();
      await writer.auth.signOut();
      await reader.firestore.terminate();
      await writer.firestore.terminate();
    });
    final posts = FirestorePostRepository(
      firestore: reader.firestore,
      currentUser: reader.author,
    );
    final writerPosts = FirestorePostRepository(
      firestore: writer.firestore,
      currentUser: writer.author,
    );
    await tester.pumpWidget(
      RepositoryScope(
        postRepository: posts,
        commentRepository: FirestoreCommentRepository(
          firestore: reader.firestore,
        ),
        child: MyApp(
          createWriteViewModel: () => WriteViewModelImpl(repository: posts),
        ),
      ),
    );
    await _settle(tester);
    expect(find.text('게시글 45'), findsOneWidget);
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    // when: 피드를 읽은 뒤 연결을 끊고 당겨서 새로고침한다.
    await reader.firestore.disableNetwork();
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await _settle(tester);

    // then: 실패 안내 대신 기기 캐시의 글과 오프라인 안내를 보여준다.
    expect(find.text(_feedOffline), findsOneWidget);
    expect(find.text('게시글 45'), findsOneWidget);
    await binding.takeScreenshot('01_feed_offline');
    debugPrint('[#15] offline refresh -> cached feed + banner');

    // when: 끊긴 동안 다른 기기가 글을 쓰고, 연결이 돌아온다.
    await writerPosts.addPost('연결이 끊긴 동안 다른 기기에서 쓴 글');
    await reader.firestore.enableNetwork();
    await _waitFor(tester, find.text(_reconnected));

    // then: 다시 연결 안내와 새 글 칩을 띄우고 읽던 목록은 그대로 둔다.
    expect(find.text(_feedOffline), findsNothing);
    expect(find.text(_reconnected), findsOneWidget);
    expect(find.text('새 글 1개'), findsOneWidget);
    expect(find.text('연결이 끊긴 동안 다른 기기에서 쓴 글'), findsNothing);
    await binding.takeScreenshot('02_feed_reconnected');
    debugPrint('[#15] reconnect -> snackbar + new post chip, list kept');

    // when: 연결된 상태로 상세를 한 번 연 뒤, 연결을 끊고 다시 연다.
    await tester.tap(find.text('게시글 45'));
    await _settle(tester);
    expect(find.text('먼저 쓴 댓글'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await _settle(tester);
    await reader.firestore.disableNetwork();
    await tester.tap(find.text('게시글 45'));
    await _settle(tester);

    // then: 저장된 본문만 보여주고 댓글 조회와 입력을 막는다.
    expect(find.text(_detailOffline), findsOneWidget);
    expect(find.text('게시글 45'), findsOneWidget);
    expect(find.text(_commentsOffline), findsOneWidget);
    expect(find.text('먼저 쓴 댓글'), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    await binding.takeScreenshot('03_detail_offline');
    debugPrint('[#15] offline detail -> cached body, comments blocked');

    // when: 상세를 연 채로 연결이 돌아온다.
    await reader.firestore.enableNetwork();
    await _waitFor(tester, find.text('먼저 쓴 댓글'));

    // then: 댓글을 자동으로 다시 불러오고 입력을 연다.
    expect(find.text(_detailOffline), findsNothing);
    expect(find.text('먼저 쓴 댓글'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    await binding.takeScreenshot('04_detail_reconnected');
    debugPrint('[#15] reconnect on detail -> comments reloaded, input enabled');
  }, timeout: const Timeout(Duration(minutes: 3)));
}

Future<void> _settle(WidgetTester tester) => tester.pumpAndSettle(
  const Duration(milliseconds: 100),
  EnginePhase.sendSemanticsUpdate,
  const Duration(seconds: 30),
);

// 실기기 테스트는 실제 시간이 흐른다. 앱의 재확인 간격 안에 화면이 바뀔 때까지 기다린다.
// 재연결 스낵바는 몇 초 뒤 사라지므로 고정 시간 대신 나타난 직후에 확인한다.
Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(
    offlineRetryInterval + const Duration(seconds: 10),
  );
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await tester.pump();
  }
  // 나타나는 애니메이션이 끝난 화면을 찍는다.
  await Future<void>.delayed(const Duration(milliseconds: 500));
  await tester.pump();
}

typedef _Client = ({
  FirebaseAuth auth,
  FirebaseFirestore firestore,
  Author author,
});

// [persistent]면 실제 앱처럼 기기 저장소 캐시를 켜고, 이전 실행의 캐시는 지운다.
Future<_Client> _openClient(String name, {bool persistent = false}) async {
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
  firestore.settings = Settings(persistenceEnabled: persistent);
  if (persistent) await firestore.clearPersistence();
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
