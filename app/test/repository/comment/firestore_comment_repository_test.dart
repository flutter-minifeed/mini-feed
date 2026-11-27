// Firebase SDK의 sealed 타입은 테스트 대역에서만 사용한다.
// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:minifeed/models/author.dart';
import 'package:minifeed/repository/comment/firestore_comment_repository.dart';
import 'package:minifeed/repository/offline_exception.dart';

class _Firestore extends Mock implements FirebaseFirestore {}

class _Collection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _PostRef extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

// FirestoreCommentRepository의 트랜잭션 결과 타입과 같은 기록 타입.
typedef _SaveResult = ({bool created, int count});

const _me = Author(id: 'u', nickName: '테스트 펭귄', colorIndex: 1);

void main() {
  late _Firestore firestore;
  late FirestoreCommentRepository repository;

  setUpAll(() {
    registerFallbackValue((Transaction _) async => null as _SaveResult?);
  });

  setUp(() {
    firestore = _Firestore();
    final posts = _Collection();
    final post = _PostRef();
    final comments = _Collection();
    when(() => firestore.collection('posts')).thenReturn(posts);
    when(() => posts.doc('test-post')).thenReturn(post);
    when(() => post.collection('comments')).thenReturn(comments);
    when(() => comments.doc('request-1')).thenReturn(_PostRef());
    repository = FirestoreCommentRepository(firestore: firestore);
  });

  Future<Object?> addComment() => repository.addComment(
    'test-post',
    '새 댓글',
    author: _me,
    requestId: 'request-1',
  );

  test('Firestore가 마감 시간 오류를 보내면 댓글 저장 시한 초과로 전달한다', () async {
    // given
    when(() => firestore.runTransaction<_SaveResult?>(any())).thenAnswer(
      (_) async => throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'deadline-exceeded',
      ),
    );

    // when, then
    await expectLater(addComment(), throwsA(isA<TimeoutException>()));
  });

  test('서버에 연결할 수 없으면 댓글 저장 실패를 오프라인으로 알린다', () async {
    // given
    when(() => firestore.runTransaction<_SaveResult?>(any())).thenAnswer(
      (_) async => throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      ),
    );

    // when, then
    await expectLater(addComment(), throwsA(isA<OfflineException>()));
  });

  test('Firestore 댓글 저장 권한 오류는 시한 초과로 바뀌지 않는다', () async {
    // given
    final error = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
    );
    when(
      () => firestore.runTransaction<_SaveResult?>(any()),
    ).thenAnswer((_) async => throw error);

    // when, then
    await expectLater(addComment(), throwsA(same(error)));
  });
}
