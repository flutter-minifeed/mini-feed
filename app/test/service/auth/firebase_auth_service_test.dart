// Firebase SDK의 sealed 타입은 운영 코드에서 확장하지 않고 테스트 대역에만 사용한다.
// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:minifeed/service/auth/auth_service.dart';
import 'package:minifeed/service/auth/firebase_auth_service.dart';

class _Auth extends Mock implements FirebaseAuth {}

class _User extends Mock implements User {}

class _Credential extends Mock implements UserCredential {}

class _Db extends Mock implements FirebaseFirestore {}

class _Collection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _Ref extends Mock implements DocumentReference<Map<String, dynamic>> {}

class _Snapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class _Metadata extends Mock implements SnapshotMetadata {}

class _Transaction extends Mock implements Transaction {}

void main() {
  late _Auth auth;
  late _User user;
  late _Db db;
  late _Ref ref;
  late _Snapshot cache;
  late _Snapshot server;
  late _Transaction transaction;
  late FirebaseAuthService authService;
  final original = {
    'nickName': '밤산책 고양이',
    'colorIndex': 4,
    'createdAt': Timestamp.fromMillisecondsSinceEpoch(1000),
  };

  setUpAll(() {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(const GetOptions());
    registerFallbackValue((Transaction transaction) async {});
  });
  setUp(() {
    auth = _Auth();
    user = _User();
    db = _Db();
    ref = _Ref();
    cache = _Snapshot();
    server = _Snapshot();
    transaction = _Transaction();
    final collection = _Collection();
    final metadata = _Metadata();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('user-a');
    when(() => user.isAnonymous).thenReturn(true);
    when(() => db.collection('users')).thenReturn(collection);
    when(() => collection.doc('user-a')).thenReturn(ref);
    when(() => cache.metadata).thenReturn(metadata);
    when(() => metadata.hasPendingWrites).thenReturn(false);
    when(() => cache.exists).thenReturn(true);
    when(() => cache.data()).thenReturn(original);
    when(() => server.exists).thenReturn(true);
    when(() => server.data()).thenReturn(original);
    when(() => ref.get(any())).thenAnswer(
      (invocation) async =>
          (invocation.positionalArguments.first as GetOptions).source ==
              Source.cache
          ? cache
          : server,
    );
    when(() => transaction.get(ref)).thenAnswer((_) async => server);
    when(() => transaction.set(ref, any<Map<String, dynamic>>()))
        .thenReturn(transaction);
    when(() => db.runTransaction<void>(any(), timeout: any(named: 'timeout')))
        .thenAnswer((invocation) async {
          await (invocation.positionalArguments.first
              as Future<void> Function(Transaction))(transaction);
        });
    authService = FirebaseAuthService(
      auth: auth,
      firestore: db,
      initialize: () async {},
    );
  });

  test('기존 익명 계정과 확정된 캐시가 있으면 재로그인 없이 같은 프로필을 사용한다', () async {
    // given / when
    final profile = await authService.signIn();
    // then
    expect(profile.author.id, 'user-a');
    expect(profile.author.nickName, '밤산책 고양이');
    expect(profile.createdAt.millisecondsSinceEpoch, 1000);
    verifyNever(() => auth.signInAnonymously());
    verifyNever(
      () => db.runTransaction<void>(any(), timeout: any(named: 'timeout')),
    );
  });
  test('기존 프로필을 불러오는 동안 새로 계산한 닉네임을 표시하지 않는다', () async {
    // given
    final displayedNames = <String>[];
    // when
    await authService.signIn(
      onAuthorReady: (author) => displayedNames.add(author.nickName),
    );
    // then
    expect(displayedNames, ['밤산책 고양이']);
  });
  test('미확정 캐시는 사용하지 않고 서버의 기존 프로필을 확인한다', () async {
    // given
    final metadata = cache.metadata;
    when(() => metadata.hasPendingWrites).thenReturn(true);
    when(() => cache.data()).thenReturn({...original, 'nickName': '임시 고양이'});
    // when
    final profile = await authService.signIn();
    // then
    expect(profile.author.nickName, '밤산책 고양이');
    verify(() => db.runTransaction<void>(any(), timeout: any(named: 'timeout')))
        .called(1);
    verifyNever(() => transaction.set(ref, any<Map<String, dynamic>>()));
  });
  test('최초 로그인하면 자신의 프로필을 서버 시각으로 한 번 생성한다', () async {
    // given
    when(() => auth.currentUser).thenReturn(null);
    final credential = _Credential();
    when(() => credential.user).thenReturn(user);
    when(() => auth.signInAnonymously()).thenAnswer((_) async => credential);
    when(() => cache.exists).thenReturn(false);
    final missing = _Snapshot();
    when(() => missing.exists).thenReturn(false);
    when(() => transaction.get(ref)).thenAnswer((_) async => missing);
    final saved = {
      'nickName': '용감한 치타',
      'colorIndex': 4,
      'createdAt': Timestamp.fromMillisecondsSinceEpoch(1000),
    };
    when(() => server.data()).thenReturn(saved);

    // when
    final profile = await authService.signIn();

    // then
    verify(() => auth.signInAnonymously()).called(1);
    final data =
        verify(() => transaction.set(ref, captureAny<Map<String, dynamic>>()))
                .captured
                .single
            as Map<String, dynamic>;
    expect(data.keys.toSet(), {'nickName', 'colorIndex', 'createdAt'});
    expect(data['nickName'], saved['nickName']);
    expect(data['colorIndex'], saved['colorIndex']);
    expect(data['createdAt'], isA<FieldValue>());
    expect(profile.author.id, 'user-a');
    expect(profile.author.nickName, saved['nickName']);
    expect(profile.author.colorIndex, saved['colorIndex']);
    expect(profile.createdAt.millisecondsSinceEpoch, 1000);
  });

  test('최초 인증 후 프로필 저장에 실패해도 같은 UID로 재시도한다', () async {
    // given
    User? signedInUser;
    when(() => auth.currentUser).thenAnswer((_) => signedInUser);
    final credential = _Credential();
    when(() => credential.user).thenReturn(user);
    when(() => auth.signInAnonymously()).thenAnswer((_) async {
      signedInUser = user;
      return credential;
    });
    when(() => cache.exists).thenReturn(false);
    final missing = _Snapshot();
    when(() => missing.exists).thenReturn(false);
    when(() => transaction.get(ref)).thenAnswer((_) async => missing);
    final saved = {
      'nickName': '용감한 치타',
      'colorIndex': 4,
      'createdAt': Timestamp.fromMillisecondsSinceEpoch(1000),
    };
    when(() => server.data()).thenReturn(saved);
    var transactionAttempts = 0;
    when(
      () => db.runTransaction<void>(any(), timeout: any(named: 'timeout')),
    ).thenAnswer((invocation) async {
      transactionAttempts++;
      await (invocation.positionalArguments.first
          as Future<void> Function(Transaction))(transaction);
      if (transactionAttempts == 1) {
        throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
      }
    });
    Object? firstError;

    // when
    try {
      await authService.signIn();
    } catch (error) {
      firstError = error;
    }
    final profile = await authService.signIn();

    // then
    expect(
      firstError,
      isA<SessionException>().having(
        (error) => error.failure,
        'failure',
        SessionFailure.offline,
      ),
    );
    verify(() => auth.signInAnonymously()).called(1);
    verify(() => db.collection('users')).called(2);
    verify(() => db.runTransaction<void>(any(), timeout: any(named: 'timeout')))
        .called(2);
    final writes = verify(
      () => transaction.set(ref, captureAny<Map<String, dynamic>>()),
    ).captured;
    expect(writes, hasLength(2));
    for (final data in writes.cast<Map<String, dynamic>>()) {
      expect(data['nickName'], saved['nickName']);
      expect(data['colorIndex'], saved['colorIndex']);
      expect(data['createdAt'], isA<FieldValue>());
    }
    expect(profile.author.id, 'user-a');
    expect(profile.author.nickName, saved['nickName']);
    expect(profile.author.colorIndex, saved['colorIndex']);
    expect(profile.createdAt.millisecondsSinceEpoch, 1000);
  });

  test('프로필 저장 실패 후 재시도해도 UID를 새로 만들지 않고 서버 프로필을 유지한다', () async {
    // given
    when(() => cache.exists).thenReturn(false);
    var tries = 0;
    when(
      () => db.runTransaction<void>(any(), timeout: any(named: 'timeout')),
    ).thenAnswer((invocation) async {
      if (++tries == 1) {
        throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
      }
      await (invocation.positionalArguments.first
          as Future<void> Function(Transaction))(transaction);
    });
    // when
    await expectLater(
      authService.signIn(),
      throwsA(
        isA<SessionException>().having(
          (e) => e.failure,
          'failure',
          SessionFailure.offline,
        ),
      ),
    );
    final profile = await authService.signIn();
    // then
    expect(profile.author.nickName, '밤산책 고양이');
    expect(profile.createdAt.millisecondsSinceEpoch, 1000);
    verifyNever(() => auth.signInAnonymously());
    verifyNever(() => transaction.set(ref, any<Map<String, dynamic>>()));
  });
  test('첫 실행 오프라인이면 실패를 알리고 프로필을 만들지 않는다', () async {
    // given
    when(() => auth.currentUser).thenReturn(null);
    when(() => auth.signInAnonymously())
        .thenThrow(FirebaseAuthException(code: 'network-request-failed'));
    // when / then
    await expectLater(
      authService.signIn(),
      throwsA(
        isA<SessionException>().having(
          (e) => e.failure,
          'failure',
          SessionFailure.offline,
        ),
      ),
    );
    verifyNever(() => db.collection('users'));
  });
  test('로그인 진행 중 다시 요청해도 원래 인증을 공유한다', () async {
    // given
    when(() => auth.currentUser).thenReturn(null);
    final pending = Completer<UserCredential>();
    when(() => auth.signInAnonymously()).thenAnswer((_) => pending.future);
    final credential = _Credential();
    when(() => credential.user).thenReturn(user);
    // when
    final first = authService.signIn();
    final retry = authService.signIn();
    pending.complete(credential);
    final profiles = await Future.wait([first, retry]);
    // then
    expect(profiles.first.author.id, profiles.last.author.id);
    verify(() => auth.signInAnonymously()).called(1);
  });
  test('잘못된 저장 프로필은 새로 생성하거나 덮어쓰지 않는다', () async {
    // given
    when(() => cache.data()).thenReturn({...original, 'colorIndex': 8});
    // when / then
    await expectLater(
      authService.signIn(),
      throwsA(
        isA<SessionException>().having(
          (e) => e.failure,
          'failure',
          SessionFailure.invalidProfile,
        ),
      ),
    );
    verifyNever(
      () => db.runTransaction<void>(any(), timeout: any(named: 'timeout')),
    );
  });
}
