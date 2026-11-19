// Firebase SDK의 sealed 타입은 테스트 대역에서만 사용한다.
// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:minifeed/models/author.dart';
import 'package:minifeed/models/post.dart';
import 'package:minifeed/repository/post/firestore_post_repository.dart';

class _Firestore extends Mock implements FirebaseFirestore {}

class _Posts extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _PostRef extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

void main() {
  late _Firestore firestore;
  late FirestorePostRepository repository;

  setUpAll(() {
    registerFallbackValue((Transaction _) async => null as Post?);
  });

  setUp(() {
    firestore = _Firestore();
    final posts = _Posts();
    final post = _PostRef();
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
}
