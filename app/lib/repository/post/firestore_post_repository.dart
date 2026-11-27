import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/author.dart';
import '../../models/post.dart';
import '../offline_exception.dart';
import 'post_repository.dart';

class FirestorePostRepository implements PostRepository {
  FirestorePostRepository({
    required this._firestore,
    required this.currentUser,
  });

  static const _server = GetOptions(source: Source.server);
  static const _cache = GetOptions(source: Source.cache);

  final FirebaseFirestore _firestore;

  @override
  final Author currentUser;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');

  Query<Map<String, dynamic>> get _newestFirst => _posts
      .orderBy('createdAt', descending: true)
      .orderBy(FieldPath.documentId, descending: true);

  @override
  Future<List<Post>> getPosts() async {
    final snapshot = await _newestFirst.get(_server);
    return List.unmodifiable(snapshot.docs.map(_toPost));
  }

  @override
  Future<PostPage> getPostPage({PostCursor? after}) async {
    var query = _newestFirst;
    if (after != null) {
      query = query.startAfter([
        Timestamp.fromDate(after.createdAt),
        after.postId,
      ]);
    }
    final snapshot = await _serverOrCache(query.limit(PostPage.pageSize).get);
    return PostPage(
      snapshot.docs.map(_toPost).toList(),
      fromCache: snapshot.metadata.isFromCache,
    );
  }

  @override
  Future<Post?> getPostById(String id) async {
    final snapshot = await _serverOrCache(_posts.doc(id).get);
    return snapshot.exists ? _toPost(snapshot) : null;
  }

  // 서버에 연결할 수 없거나 제때 답하지 않을 때만 기기 캐시에서 다시 읽는다(#15).
  // 복구를 확인하는 조회가 시간 초과로 끝나도 오프라인 상태와 재확인이 이어지게 한다.
  // 권한 거부 같은 다른 오류는 캐시 값으로 가리지 않고 그대로 전달한다.
  // 캐시에도 없는 문서면 OfflineException으로 알린다.
  static Future<T> _serverOrCache<T>(
    Future<T> Function(GetOptions options) read,
  ) async {
    try {
      return await read(_server);
    } on FirebaseException catch (error) {
      if (!_isServerUnreachable(error)) rethrow;
    }
    try {
      return await read(_cache);
    } on FirebaseException catch (error) {
      if (error.code != 'unavailable') rethrow;
      throw const OfflineException();
    }
  }

  @override
  Future<Post> addPost(String body, {String? requestId}) async {
    final ref = _posts.doc(requestId);
    try {
      // 같은 문서를 동시에 읽고 생성해도 커밋은 한 번만 성공한다.
      // 재시도된 트랜잭션은 기존 문서를 읽고 쓰기 없이 끝난다.
      final existing = await _firestore.runTransaction<Post?>((
        transaction,
      ) async {
        final snapshot = await transaction.get(ref);
        if (snapshot.exists) return _toPost(snapshot);

        transaction.set(ref, {
          'authorId': currentUser.id,
          'nickName': currentUser.nickName,
          'colorIndex': currentUser.colorIndex,
          'body': body,
          'createdAt': FieldValue.serverTimestamp(),
          'likeCount': 0,
          'commentCount': 0,
        });
        return null;
      });

      if (existing != null) {
        return checkSameRequest(existing, author: currentUser, body: body);
      }

      // 최초 생성은 서버가 확정한 작성 시각까지 읽고 나서 성공으로 반환한다.
      return _toPost(await ref.get(_server));
    } on FirebaseException catch (error) {
      if (error.code == 'deadline-exceeded') {
        throw TimeoutException(error.message);
      }
      rethrow;
    }
  }
}

// 연결이 없거나 서버가 시한 안에 답하지 않으면 서버에 닿지 못한 것으로 본다(#15).
bool _isServerUnreachable(FirebaseException error) =>
    error.code == 'unavailable' || error.code == 'deadline-exceeded';

Post _toPost(DocumentSnapshot<Map<String, dynamic>> snapshot) {
  final data = snapshot.data();
  if (data == null) {
    throw StateError('게시글 ${snapshot.id}의 데이터가 없습니다.');
  }
  return Post(
    id: snapshot.id,
    author: Author(
      id: data['authorId'] as String,
      nickName: data['nickName'] as String,
      colorIndex: data['colorIndex'] as int,
    ),
    body: data['body'] as String,
    createdAt: (data['createdAt'] as Timestamp).toDate().toLocal(),
    likeCount: data['likeCount'] as int,
    commentCount: data['commentCount'] as int,
    likedByMe: false,
  );
}
