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

class _Snapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class _Metadata extends Mock implements SnapshotMetadata {}

class _Query extends Mock implements Query<Map<String, dynamic>> {}

class _QuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class _QueryDoc extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

const _server = GetOptions(source: Source.server);
const _cache = GetOptions(source: Source.cache);

FirebaseException _firebaseError(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);

_Metadata _metadata({required bool fromCache}) {
  final metadata = _Metadata();
  when(() => metadata.isFromCache).thenReturn(fromCache);
  return metadata;
}

// 캐시에서 읽은 문서 한 건. 저장소가 읽는 필드와 캐시 표시만 채운다.
_Snapshot _cachedSnapshot(Map<String, dynamic> data) {
  final snapshot = _Snapshot();
  final metadata = _metadata(fromCache: true);
  when(() => snapshot.metadata).thenReturn(metadata);
  when(() => snapshot.exists).thenReturn(true);
  when(() => snapshot.data()).thenReturn(data);
  when(() => snapshot.id).thenReturn('test-post');
  return snapshot;
}

void main() {
  late _Firestore firestore;
  late _Posts posts;
  late _PostRef post;
  late FirestorePostRepository repository;

  setUpAll(() {
    registerFallbackValue((Transaction _) async => null as Post?);
    // orderBy(FieldPath.documentId)의 인자를 any()로 받기 위한 대체값.
    registerFallbackValue(FieldPath.documentId);
  });

  setUp(() {
    firestore = _Firestore();
    posts = _Posts();
    post = _PostRef();
    when(() => firestore.collection('posts')).thenReturn(posts);
    when(() => posts.doc('test-post')).thenReturn(post);
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

  group('#15 오프라인 조회', () {
    final cachedPost = {
      'authorId': 'writer',
      'nickName': '밤산책 고양이',
      'colorIndex': 4,
      'body': '캐시된 글',
      'createdAt': Timestamp.fromMillisecondsSinceEpoch(1000),
      'likeCount': 1,
      'commentCount': 0,
    };

    test('서버에 연결할 수 없으면 글 목록을 캐시에서 읽고 오프라인 페이지로 알린다', () async {
      // given
      final byTime = _Query();
      final ordered = _Query();
      final limited = _Query();
      final page = _QuerySnapshot();
      final doc = _QueryDoc();
      final metadata = _metadata(fromCache: true);
      when(
        () => posts.orderBy('createdAt', descending: true),
      ).thenReturn(byTime);
      when(
        () => byTime.orderBy(any(), descending: any(named: 'descending')),
      ).thenReturn(ordered);
      when(() => ordered.limit(20)).thenReturn(limited);
      when(() => limited.get(_server)).thenThrow(_firebaseError('unavailable'));
      when(() => limited.get(_cache)).thenAnswer((_) async => page);
      when(() => page.metadata).thenReturn(metadata);
      when(() => page.docs).thenReturn([doc]);
      when(() => doc.id).thenReturn('test-post');
      when(() => doc.data()).thenReturn(cachedPost);

      // when
      final result = await repository.getPostPage();

      // then
      expect(result.posts.single.body, '캐시된 글');
      expect(result.fromCache, isTrue);
    });

    test('서버에 연결할 수 없으면 캐시에 남은 글 상세를 돌려준다', () async {
      // given
      when(() => post.get(_server)).thenThrow(_firebaseError('unavailable'));
      when(
        () => post.get(_cache),
      ).thenAnswer((_) async => _cachedSnapshot(cachedPost));

      // when
      final result = await repository.getPostById('test-post');

      // then
      expect(result?.body, '캐시된 글');
    });

    test('서버가 시한 안에 답하지 않으면 캐시에 남은 글 상세를 돌려준다', () async {
      // given
      when(
        () => post.get(_server),
      ).thenThrow(_firebaseError('deadline-exceeded'));
      when(
        () => post.get(_cache),
      ).thenAnswer((_) async => _cachedSnapshot(cachedPost));

      // when
      final result = await repository.getPostById('test-post');

      // then
      expect(result?.body, '캐시된 글');
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
