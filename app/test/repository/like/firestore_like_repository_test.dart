// Firebase SDK의 sealed 타입은 테스트 대역에서만 사용한다.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:minifeed/repository/like/firestore_like_repository.dart';
import 'package:minifeed/repository/like/like_repository.dart';
import 'package:minifeed/repository/offline_exception.dart';

class _Firestore extends Mock implements FirebaseFirestore {}

class _Collection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _DocRef extends Mock implements DocumentReference<Map<String, dynamic>> {}

void main() {
  late _Firestore firestore;
  late FirestoreLikeRepository repository;

  setUpAll(() {
    registerFallbackValue((Transaction _) async => null as LikeState?);
  });

  setUp(() {
    firestore = _Firestore();
    final posts = _Collection();
    final post = _DocRef();
    final likes = _Collection();
    when(() => firestore.collection('posts')).thenReturn(posts);
    when(() => posts.doc('test-post')).thenReturn(post);
    when(() => post.collection('likes')).thenReturn(likes);
    when(() => likes.doc('u')).thenReturn(_DocRef());
    repository = FirestoreLikeRepository(firestore: firestore, userId: 'u');
  });

  test('서버에 연결할 수 없으면 좋아요 저장 실패를 오프라인으로 알린다', () async {
    // given
    when(() => firestore.runTransaction<LikeState?>(any())).thenAnswer(
      (_) async => throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      ),
    );

    // when, then
    await expectLater(
      repository.setLike('test-post', liked: true),
      throwsA(isA<OfflineException>()),
    );
  });

  test('좋아요 저장 권한 오류는 오프라인으로 바뀌지 않는다', () async {
    // given
    final error = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
    );
    when(
      () => firestore.runTransaction<LikeState?>(any()),
    ).thenAnswer((_) async => throw error);

    // when, then
    await expectLater(
      repository.setLike('test-post', liked: true),
      throwsA(same(error)),
    );
  });
}
