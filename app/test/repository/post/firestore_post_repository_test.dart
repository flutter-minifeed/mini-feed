// Firebase SDK의 sealed 타입은 테스트 대역에서만 사용한다.
// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:minifeed/models/author.dart';
import 'package:minifeed/models/post.dart';
import 'package:minifeed/repository/post/firestore_post_repository.dart';
import 'package:minifeed/repository/post/post_repository.dart';

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
    when(() => post.path).thenReturn('posts/test-post');
    when(() => firestore.collection('posts')).thenReturn(posts);
    when(() => posts.doc('test-post')).thenReturn(post);
    repository = FirestorePostRepository(
      firestore: firestore,
      currentUser: const Author(id: 'u', nickName: '테스트 펭귄', colorIndex: 1),
    );
  });

  test('UTF-8로 저장할 태그가 문서 용량을 넘으면 쓰기 전에 안내한다', () async {
    // 태그 하나는 한글 15자와 숫자 5자, 문자열 끝 1바이트로 총 51바이트다.
    final tags = List.generate(
      21000,
      (index) => '${'가' * 15}${index.toString().padLeft(5, '0')}',
    );
    await expectLater(
      repository.addPost('새 글', requestId: 'test-post', tags: tags),
      throwsA(isA<PostTooLargeException>()),
    );
    verifyNever(() => firestore.runTransaction<Post?>(any()));
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
