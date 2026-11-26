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
    return List.unmodifiable(
      await _withLikedByMe(snapshot.docs, fromCache: false),
    );
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
    final fromCache = snapshot.metadata.isFromCache;
    return PostPage(
      await _withLikedByMe(snapshot.docs, fromCache: fromCache),
      fromCache: fromCache,
    );
  }

  @override
  Future<Post?> getPostById(String id) async {
    final snapshot = await _serverOrCache(_posts.doc(id).get);
    if (!snapshot.exists) return null;
    final likedByMe = await _isLikedByMe(
      snapshot.reference,
      fromCache: snapshot.metadata.isFromCache,
    );
    return _toPost(snapshot, likedByMe: likedByMe);
  }

  // 서버에 연결할 수 없을 때만 기기 캐시에서 다시 읽는다(#15).
  // 권한 거부 같은 다른 오류는 캐시 값으로 가리지 않고 그대로 전달한다.
  // 캐시에도 없는 문서면 OfflineException으로 알린다.
  static Future<T> _serverOrCache<T>(
    Future<T> Function(GetOptions options) read,
  ) async {
    try {
      return await read(_server);
    } on FirebaseException catch (error) {
      if (error.code != 'unavailable') rethrow;
    }
    try {
      return await read(_cache);
    } on FirebaseException catch (error) {
      if (error.code != 'unavailable') rethrow;
      throw const OfflineException();
    }
  }

  // likedByMe는 공용 게시글 필드가 아니라 내 좋아요 문서가 있는지로 정한다(#18).
  // 규칙상 다른 사용자의 좋아요 문서는 읽을 수 없어서 글마다 내 문서만 확인한다.
  // 글을 캐시에서 읽었으면 좋아요도 서버에 다시 묻지 않고 캐시에서 읽는다.
  // 글을 읽은 뒤 좋아요를 읽기 전에 연결이 끊겨도 읽은 글을 버리지 않고 캐시로 대신한다.
  Future<bool> _isLikedByMe(
    DocumentReference<Map<String, dynamic>> post, {
    required bool fromCache,
  }) async {
    final like = post.collection('likes').doc(currentUser.id);
    if (!fromCache) {
      try {
        return (await like.get(_server)).exists;
      } on FirebaseException catch (error) {
        if (error.code != 'unavailable') rethrow;
      }
    }
    try {
      return (await like.get(_cache)).exists;
    } on FirebaseException catch (error) {
      if (error.code != 'unavailable') rethrow;
      // 온라인일 때 한 번도 읽지 않은 기록은 캐시에 없어서 누르지 않은 것으로 표시한다.
      return false;
    }
  }

  // Future.wait는 넘긴 순서대로 결과를 돌려주므로 조회 순서가 유지된다.
  Future<List<Post>> _withLikedByMe(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required bool fromCache,
  }) {
    return Future.wait(
      docs.map(
        (doc) async => _toPost(
          doc,
          likedByMe: await _isLikedByMe(doc.reference, fromCache: fromCache),
        ),
      ),
    );
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
        if (snapshot.exists) return _toPost(snapshot, likedByMe: false);

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
      // 방금 만든 글이라 내 좋아요는 아직 없다.
      return _toPost(await ref.get(_server), likedByMe: false);
    } on FirebaseException catch (error) {
      if (error.code == 'deadline-exceeded') {
        throw TimeoutException(error.message);
      }
      rethrow;
    }
  }
}

Post _toPost(
  DocumentSnapshot<Map<String, dynamic>> snapshot, {
  required bool likedByMe,
}) {
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
    likedByMe: likedByMe,
  );
}
