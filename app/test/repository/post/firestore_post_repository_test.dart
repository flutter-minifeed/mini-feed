// Firebase SDK의 sealed 타입은 테스트 대역에서만 사용한다.
// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:minifeed/models/author.dart';
import 'package:minifeed/models/post.dart';
import 'package:minifeed/repository/offline_exception.dart';
import 'package:minifeed/repository/post/firestore_post_repository.dart';

class _Firestore extends Mock implements FirebaseFirestore {}

class _Posts extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _PostRef extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class _Likes extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _Snapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class _Metadata extends Mock implements SnapshotMetadata {}

const _server = GetOptions(source: Source.server);
const _cache = GetOptions(source: Source.cache);

FirebaseException _firebaseError(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);

// 캐시에서 읽은 문서 한 건. 저장소가 읽는 필드와 캐시 표시만 채운다.
_Snapshot _cachedSnapshot(
  DocumentReference<Map<String, dynamic>> reference, {
  Map<String, dynamic>? data,
}) => _snapshot(reference, data: data, fromCache: true);

// 서버에서 읽은 문서 한 건.
_Snapshot _serverSnapshot(
  DocumentReference<Map<String, dynamic>> reference, {
  Map<String, dynamic>? data,
}) => _snapshot(reference, data: data, fromCache: false);

_Snapshot _snapshot(
  DocumentReference<Map<String, dynamic>> reference, {
  required Map<String, dynamic>? data,
  required bool fromCache,
}) {
  final snapshot = _Snapshot();
  final metadata = _Metadata();
  when(() => metadata.isFromCache).thenReturn(fromCache);
  when(() => snapshot.metadata).thenReturn(metadata);
  when(() => snapshot.exists).thenReturn(data != null);
  when(() => snapshot.data()).thenReturn(data);
  when(() => snapshot.id).thenReturn('test-post');
  when(() => snapshot.reference).thenReturn(reference);
  return snapshot;
}

void main() {
  late _Firestore firestore;
  late _PostRef post;
  late _PostRef like;
  late FirestorePostRepository repository;

  setUpAll(() {
    registerFallbackValue((Transaction _) async => null as Post?);
  });

  setUp(() {
    firestore = _Firestore();
    final posts = _Posts();
    final likes = _Likes();
    post = _PostRef();
    like = _PostRef();
    when(() => firestore.collection('posts')).thenReturn(posts);
    when(() => posts.doc('test-post')).thenReturn(post);
    when(() => post.collection('likes')).thenReturn(likes);
    when(() => likes.doc('u')).thenReturn(like);
    repository = FirestorePostRepository(
      firestore: firestore,
      currentUser: const Author(id: 'u', nickName: '테스트 펭귄', colorIndex: 1),
    );
  });

  test('Firestore가 마감 시간 오류를 보내면 저장 시한 초과로 전달한다', () async {
    // given
    when(() => firestore.runTransaction<Post?>(any())).thenAnswer(
      (_) async => throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'deadline-exceeded',
      ),
    );

    // when, then
    await expectLater(
      repository.addPost('새 글', requestId: 'test-post'),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('Firestore 저장 권한 오류는 시한 초과로 바뀌지 않는다', () async {
    // given
    final error = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
    );
    when(() => firestore.runTransaction<Post?>(any()))
        .thenAnswer((_) async => throw error);

    // when, then
    await expectLater(
      repository.addPost('새 글', requestId: 'test-post'),
      throwsA(same(error)),
    );
  });

  group('#15 오프라인 상세 조회', () {
    final cachedPost = {
      'authorId': 'writer',
      'nickName': '밤산책 고양이',
      'colorIndex': 4,
      'body': '캐시된 글',
      'createdAt': Timestamp.fromMillisecondsSinceEpoch(1000),
      'likeCount': 1,
      'commentCount': 0,
    };

    test('서버에 연결할 수 없으면 캐시에 남은 글과 내 좋아요를 돌려준다', () async {
      // given
      when(() => post.get(_server)).thenThrow(_firebaseError('unavailable'));
      when(
        () => post.get(_cache),
      ).thenAnswer((_) async => _cachedSnapshot(post, data: cachedPost));
      when(
        () => like.get(_cache),
      ).thenAnswer((_) async => _cachedSnapshot(like, data: const {}));

      // when
      final result = await repository.getPostById('test-post');

      // then
      expect((result?.body, result?.likedByMe), ('캐시된 글', true));
      verifyNever(() => like.get(_server));
    });

    test('좋아요 기록이 캐시에 없으면 누르지 않은 것으로 표시한다', () async {
      // given
      when(() => post.get(_server)).thenThrow(_firebaseError('unavailable'));
      when(
        () => post.get(_cache),
      ).thenAnswer((_) async => _cachedSnapshot(post, data: cachedPost));
      when(() => like.get(_cache)).thenThrow(_firebaseError('unavailable'));

      // when
      final result = await repository.getPostById('test-post');

      // then
      expect(result?.likedByMe, isFalse);
    });

    test('글을 서버에서 읽은 뒤 좋아요를 읽기 전에 연결이 끊기면 좋아요는 캐시에서 읽는다', () async {
      // given
      when(
        () => post.get(_server),
      ).thenAnswer((_) async => _serverSnapshot(post, data: cachedPost));
      when(() => like.get(_server)).thenThrow(_firebaseError('unavailable'));
      when(
        () => like.get(_cache),
      ).thenAnswer((_) async => _cachedSnapshot(like, data: const {}));

      // when
      final result = await repository.getPostById('test-post');

      // then
      expect((result?.body, result?.likedByMe), ('캐시된 글', true));
    });

    test('서버와 캐시 모두에서 글을 읽지 못하면 없는 글이 아니라 오프라인으로 알린다', () async {
      // given
      when(() => post.get(_server)).thenThrow(_firebaseError('unavailable'));
      when(() => post.get(_cache)).thenThrow(_firebaseError('unavailable'));

      // when, then
      await expectLater(
        repository.getPostById('test-post'),
        throwsA(isA<OfflineException>()),
      );
    });

    test('서버 권한 오류는 캐시 값으로 바꾸지 않고 그대로 전달한다', () async {
      // given
      final error = _firebaseError('permission-denied');
      when(() => post.get(_server)).thenThrow(error);

      // when, then
      await expectLater(
        repository.getPostById('test-post'),
        throwsA(same(error)),
      );
      verifyNever(() => post.get(_cache));
    });
  });
}
