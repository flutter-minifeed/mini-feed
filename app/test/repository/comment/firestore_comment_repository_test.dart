// Firebase SDK의 sealed 타입은 테스트 대역에서만 사용한다.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:minifeed/repository/comment/firestore_comment_repository.dart';
import 'package:minifeed/repository/offline_exception.dart';

class _Firestore extends Mock implements FirebaseFirestore {}

class _Collection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _PostRef extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class _Query extends Mock implements Query<Map<String, dynamic>> {}

const _server = GetOptions(source: Source.server);

void main() {
  late _PostRef post;
  late _Query ordered;
  late FirestoreCommentRepository repository;

  setUpAll(() {
    registerFallbackValue<Object>('field');
    registerFallbackValue(const GetOptions());
  });

  setUp(() {
    final firestore = _Firestore();
    final posts = _Collection();
    final comments = _Collection();
    final byTime = _Query();
    post = _PostRef();
    ordered = _Query();
    when(() => firestore.collection('posts')).thenReturn(posts);
    when(() => posts.doc('test-post')).thenReturn(post);
    when(() => post.collection('comments')).thenReturn(comments);
    when(() => comments.orderBy('createdAt')).thenReturn(byTime);
    when(() => byTime.orderBy(any())).thenReturn(ordered);
    repository = FirestoreCommentRepository(firestore: firestore);
  });

  test('서버에 연결할 수 없으면 캐시 댓글 대신 오프라인으로 알린다', () async {
    // given
    when(() => ordered.get(_server)).thenThrow(
      FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
    );

    // when, then
    await expectLater(
      repository.getComments('test-post'),
      throwsA(isA<OfflineException>()),
    );
    // 오프라인을 없는 게시글로 오해해 빈 목록을 돌려주지 않는다.
    verifyNever(() => post.get(any()));
  });
}
