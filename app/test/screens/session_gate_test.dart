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
import 'package:minifeed/service/auth/auth_service.dart';
import 'package:minifeed/theme/app_theme.dart';
import 'package:minifeed/widgets/author_tile.dart';

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

class _SharedAuthService implements AuthService {
  int calls = 0;
  final request = Completer<UserProfile>();

  @override
  Future<UserProfile> signIn({void Function(Author)? onAuthorReady}) {
    calls++;
    return request.future;
  }
}

Widget _app(
  AuthService authService, {
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
  testWidgets('인증이 끝나기 전에는 시작 화면만 보인다', (tester) async {
    // given
    final authService = _TestAuthService();
    addTearDown(() => tester.pumpWidget(const SizedBox()));

    // when
    await tester.pumpWidget(_app(authService));

    // then
    expect(find.text(author.nickName), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('피드: ${author.id}'), findsNothing);
    expect(authService.calls, 1);
  });

  testWidgets('인증에 성공하면 해당 사용자의 피드로 진입한다', (tester) async {
    // given
    final authService = _TestAuthService();
    await tester.pumpWidget(_app(authService));

    // when
    authService.requests.single.complete(profile);
    await tester.pumpAndSettle();

    // then
    expect(find.text('피드: ${author.id}'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('첫 실행 오프라인이면 프로필을 숨기고 연결 안내를 표시한다', (tester) async {
    // given
    final authService = _TestAuthService();
    await tester.pumpWidget(_app(authService));

    // when
    authService.requests.single.completeError(
      const SessionException(SessionFailure.offline),
    );
    await tester.pumpAndSettle();

    // then
    expect(find.text('네트워크에 연결되어 있지 않아요'), findsOneWidget);
    expect(find.text(author.nickName), findsNothing);
    expect(find.text('피드: ${author.id}'), findsNothing);
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('오프라인 후 연결을 복구하고 재시도하면 피드로 진입한다', (tester) async {
    // given
    final authService = _TestAuthService();
    await tester.pumpWidget(_app(authService));
    authService.requests.single.completeError(
      const SessionException(SessionFailure.offline),
    );
    await tester.pumpAndSettle();

    // when
    await tester.tap(find.text('다시 시도'));
    await tester.pump();
    authService.requests.last.complete(profile);
    await tester.pumpAndSettle();

    // then
    expect(authService.calls, 2);
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
    final oldFeedWasShown = find.text('피드: old').evaluate().isNotEmpty;
    authService.requests.last.complete(profile);
    await tester.pumpAndSettle();

    // then
    expect(oldFeedWasShown, isFalse);
    expect(find.text('피드: old'), findsNothing);
    expect(find.text('피드: ${author.id}'), findsOneWidget);
  });

  testWidgets('시간 초과 후 같은 인증 작업을 다시 기다려도 한 번만 피드로 진입한다', (tester) async {
    // given
    final authService = _SharedAuthService();
    var sessionBuilds = 0;
    await tester.pumpWidget(
      _app(
        authService,
        waitLimit: const Duration(seconds: 1),
        build: (currentUser) async {
          sessionBuilds++;
          return MaterialApp(
            home: Scaffold(body: Text('피드: ${currentUser.id}')),
          );
        },
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    // when
    await tester.tap(find.text('다시 시도'));
    await tester.pump();
    authService.request.complete(profile);
    await tester.pumpAndSettle();

    // then
    expect(authService.calls, 2);
    expect(sessionBuilds, 1);
    expect(find.text('피드: ${author.id}'), findsOneWidget);
    expect(find.text('다시 시도'), findsNothing);
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

  testWidgets('인증한 작성자 정보가 저장소를 통해 글쓰기 화면에 표시된다', (tester) async {
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
    final displayedAuthor = tester
        .widget<AuthorTile>(find.byType(AuthorTile))
        .author;
    expect(find.text(author.nickName), findsOneWidget);
    expect(posts.currentUser.id, author.id);
    expect(displayedAuthor.id, author.id);
    expect(displayedAuthor.nickName, author.nickName);
    expect(displayedAuthor.colorIndex, author.colorIndex);
  });
}
