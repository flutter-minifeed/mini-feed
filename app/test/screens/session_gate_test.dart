import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minifeed/models/author.dart';
import 'package:minifeed/models/user_profile.dart';
import 'package:minifeed/repository/comment/in_memory_comment_repository.dart';
import 'package:minifeed/repository/post/in_memory_post_repository.dart';
import 'package:minifeed/repository/repository_scope.dart';
import 'package:minifeed/screens/feed_screen.dart';
import 'package:minifeed/screens/session_gate.dart';
import 'package:minifeed/screens/start_screen.dart';
import 'package:minifeed/service/auth/auth_service.dart';
import 'package:minifeed/theme/app_theme.dart';

const author = Author(
  id: 'real-anonymous-uid',
  nickName: '밤산책 고양이',
  colorIndex: 4,
);
final profile = UserProfile(
  author: author,
  createdAt: DateTime.utc(2026, 11, 16),
);

class _TestAuthService implements AuthService {
  int calls = 0;
  final requests = <Completer<UserProfile>>[];
  @override
  Future<UserProfile> signIn({void Function(Author)? onAuthorReady}) {
    calls++;
    onAuthorReady?.call(author);
    final request = Completer<UserProfile>();
    requests.add(request);
    return request.future;
  }
}

Widget _app(
  _TestAuthService authService, {
  Duration waitLimit = const Duration(seconds: 30),
  Duration profileDisplayDuration = Duration.zero,
  Future<Widget> Function(Author)? build,
}) => SessionGate(
  authService: authService,
  waitLimit: waitLimit,
  profileDisplayDuration: profileDisplayDuration,
  buildSession:
      build ??
      (author) async =>
          MaterialApp(home: Scaffold(body: Text('피드: ${author.id}'))),
);

void main() {
  testWidgets('인증이 끝나기 전에는 시작 화면만 보이고 성공하면 해당 사용자로 피드에 들어간다', (tester) async {
    // given / when
    final authService = _TestAuthService();
    await tester.pumpWidget(_app(authService));
    // then
    expect(find.text('밤산책 고양이'), findsOneWidget);
    expect(find.text('피드: ${author.id}'), findsNothing);
    expect(authService.calls, 1);
    // when
    authService.requests.single.complete(profile);
    await tester.pumpAndSettle();
    // then
    expect(find.text('피드: ${author.id}'), findsOneWidget);
  });

  testWidgets('첫 실행 오프라인 후 연결을 복구하고 재시도하면 피드로 진입한다', (tester) async {
    // given
    final authService = _TestAuthService();
    await tester.pumpWidget(_app(authService));
    authService.requests.single.completeError(
      const SessionException(SessionFailure.offline),
    );
    await tester.pumpAndSettle();
    expect(find.text('네트워크에 연결되어 있지 않아요'), findsOneWidget);
    expect(find.text('밤산책 고양이'), findsNothing);
    // when
    await tester.tap(find.text('다시 시도'));
    await tester.pump();
    await tester.tapAt(const Offset(1, 1));
    expect(authService.calls, 2);
    authService.requests.last.complete(profile);
    await tester.pumpAndSettle();
    // then
    expect(find.text('피드: ${author.id}'), findsOneWidget);
  });

  testWidgets('시간 제한 직전에 준비가 끝나면 표시 대기 후 피드로 진입한다', (tester) async {
    // given
    final authService = _TestAuthService();
    await tester.pumpWidget(
      _app(
        authService,
        waitLimit: const Duration(seconds: 1),
        profileDisplayDuration: const Duration(milliseconds: 600),
      ),
    );

    // when
    await tester.pump(const Duration(milliseconds: 800));
    authService.requests.single.complete(profile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // then
    expect(find.text('피드: ${author.id}'), findsOneWidget);
    expect(find.text('다시 시도'), findsNothing);
  });

  testWidgets('대기 한도를 넘긴 이전 요청은 재시도 결과를 덮어쓰지 않는다', (tester) async {
    // given
    final authService = _TestAuthService();
    await tester.pumpWidget(
      _app(authService, waitLimit: const Duration(seconds: 1)),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('다시 시도'), findsOneWidget);
    // when
    await tester.tap(find.text('다시 시도'));
    await tester.pump();
    authService.requests.first.complete(
      UserProfile(
        author: const Author(id: 'old', nickName: '조용한 토끼', colorIndex: 1),
        createdAt: DateTime.utc(2026),
      ),
    );
    await tester.pump();
    // then
    expect(find.text('피드: old'), findsNothing);
    authService.requests.last.complete(profile);
    await tester.pumpAndSettle();
    expect(find.text('피드: ${author.id}'), findsOneWidget);
  });

  testWidgets('화면을 닫은 뒤 인증 응답이 도착해도 상태 변경 오류가 나지 않는다', (tester) async {
    // given
    final authService = _TestAuthService();
    await tester.pumpWidget(_app(authService));
    // when
    await tester.pumpWidget(const SizedBox());
    authService.requests.single.complete(profile);
    await tester.pump();
    // then
    expect(tester.takeException(), isNull);
  });

  testWidgets('프로필 권한 거부는 오프라인이라고 잘못 안내하지 않는다', (tester) async {
    // given
    final authService = _TestAuthService();
    await tester.pumpWidget(_app(authService));
    // when
    authService.requests.single.completeError(
      const SessionException(SessionFailure.permissionDenied),
    );
    await tester.pumpAndSettle();
    // then
    expect(find.text('프로필을 불러올 수 없어요'), findsOneWidget);
    expect(find.text('네트워크에 연결되어 있지 않아요'), findsNothing);
  });

  for (final (state, failure) in [
    ('로딩', null),
    ('오프라인', SessionFailure.offline),
  ]) {
    testWidgets('$state 시작 화면이 화면 너비의 중앙에 배치된다', (tester) async {
      // given
      const size = Size(412, 892);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // when
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: StartScreen(failure: failure),
        ),
      );

      // then
      final stateIndicator = failure == null
          ? find.byType(CircularProgressIndicator)
          : find.byIcon(Icons.wifi_off);
      for (final element in [
        find.text('미니피드'),
        stateIndicator,
        find.byIcon(Icons.lock_outline),
      ]) {
        expect(tester.getCenter(element).dx, closeTo(size.width / 2, 0.01));
      }
    });
  }

  testWidgets('작은 화면과 큰 글자에서도 오류 안내와 재시도 버튼을 볼 수 있다', (tester) async {
    // given
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // when
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: StartScreen(failure: SessionFailure.offline, onRetry: () {}),
        ),
      ),
    );
    await tester.ensureVisible(find.text('다시 시도'));
    // then
    expect(tester.takeException(), isNull);
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('인증한 프로필이 글쓰기 표시와 새 글 작성자에 전달된다', (tester) async {
    // given
    final authService = _TestAuthService();
    late InMemoryPostRepository posts;
    await tester.pumpWidget(
      _app(
        authService,
        build: (currentUser) async {
          posts = InMemoryPostRepository.fromJsonString(
            '[]',
            currentUser: currentUser,
          );
          return RepositoryScope(
            postRepository: posts,
            commentRepository: InMemoryCommentRepository.fromJsonString('[]'),
            child: MaterialApp(theme: appTheme, home: const FeedScreen()),
          );
        },
      ),
    );
    authService.requests.single.complete(profile);
    await tester.pumpAndSettle();
    // when
    await tester.tap(find.byTooltip('글쓰기'));
    await tester.pumpAndSettle();
    // then
    expect(find.text('밤산책 고양이'), findsOneWidget);
    expect(posts.currentUser.id, author.id);
    final post = await posts.addPost('새 글');
    expect(post.author.id, author.id);
    expect(post.author.colorIndex, author.colorIndex);
  });
}
