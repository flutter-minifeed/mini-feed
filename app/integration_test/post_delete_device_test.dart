import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minifeed/main.dart';
import 'package:minifeed/repository/comment/firestore_comment_repository.dart';
import 'package:minifeed/repository/post/firestore_post_repository.dart';
import 'package:minifeed/repository/repository_scope.dart';
import 'package:minifeed/service/auth/firebase_auth_service.dart';
import 'package:minifeed/viewmodels/write_view_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('로컬 서버의 두 익명 사용자가 삭제·거부·삭제된 글 조작을 확인한다', (tester) async {
    // given
    final owner = await _client('owner');
    final peer = await _client('peer');
    final ownPost = await owner.posts.addPost('내 삭제 검증 글');
    final otherPost = await peer.posts.addPost('다른 작성자의 삭제 검증 글');
    final ownBody = find.byKey(ValueKey('body-${ownPost.id}'));
    final otherBody = find.byKey(ValueKey('body-${otherPost.id}'));

    await tester.pumpWidget(
      RepositoryScope(
        postRepository: owner.posts,
        commentRepository: FirestoreCommentRepository(firestore: owner.db),
        child: MyApp(
          createWriteViewModel: () =>
              WriteViewModelImpl(repository: owner.posts),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // when: 타인 세션이 삭제를 요청하면 서버가 거부한다.
    await expectLater(
      peer.posts.deletePost(ownPost.id),
      throwsA(
        isA<FirebaseException>().having(
          (error) => error.code,
          '코드',
          'permission-denied',
        ),
      ),
    );
    await tester.tap(ownBody);
    await tester.pumpAndSettle();
    await _menu(tester, '내 글 삭제');
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(await peer.posts.getPostById(ownPost.id), isNotNull);
    await _menu(tester, '내 글 삭제');
    await tester.tap(find.text('삭제'));
    await _until(tester, () => find.text('미니피드').evaluate().isNotEmpty);

    // then
    expect(ownBody, findsNothing);
    expect(await peer.posts.getPostById(ownPost.id), isNull);
    expect(await owner.posts.deletePost(ownPost.id), isFalse);

    // when: 열어 둔 상세에서 실제 작성자가 삭제한 뒤 좋아요를 누른다.
    await tester.tap(otherBody);
    await tester.pumpAndSettle();
    await _menu(tester, '이 글 신고하기');
    expect(await peer.posts.deletePost(otherPost.id), isTrue);
    await tester.tap(find.byIcon(Icons.favorite_border));
    await _until(tester, () => find.text('삭제된 글이에요').evaluate().isNotEmpty);

    // then
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('미니피드'), findsOneWidget);
    expect(otherBody, findsNothing);
  });
}

Future<void> _menu(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('더보기'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> _until(WidgetTester tester, bool Function() ready) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (!ready() && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(ready(), isTrue);
  await tester.pumpAndSettle();
}

Future<({FirebaseFirestore db, FirestorePostRepository posts})> _client(
  String name,
) async {
  final app = await Firebase.initializeApp(
    name: 'issue21-$name',
    options: FirebaseOptions(
      apiKey: 'AIzaSy'.padRight(39, 'A'),
      appId: '1:123456789012:android:1234567890123456',
      messagingSenderId: '123456789012',
      projectId: 'demo-minifeed-issue21',
    ),
  );
  final auth = FirebaseAuth.instanceFor(app: app);
  await auth.useAuthEmulator('127.0.0.1', 9099, automaticHostMapping: false);
  final db = FirebaseFirestore.instanceFor(app: app);
  db.settings = const Settings(persistenceEnabled: false);
  db.useFirestoreEmulator('127.0.0.1', 8080, automaticHostMapping: false);
  final user = await FirebaseAuthService(
    auth: auth,
    firestore: db,
    initialize: () async {},
  ).signIn();
  return (
    db: db,
    posts: FirestorePostRepository(firestore: db, currentUser: user.author),
  );
}
