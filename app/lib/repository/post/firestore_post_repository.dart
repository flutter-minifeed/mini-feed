import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/author.dart';
import '../../models/post.dart';
import 'post_repository.dart';

class FirestorePostRepository implements PostRepository {
  FirestorePostRepository({
    required this._firestore,
    required this.currentUser,
  });

  static const _server = GetOptions(source: Source.server);

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
    final snapshot = await query.limit(PostPage.pageSize).get(_server);
    return PostPage(snapshot.docs.map(_toPost).toList());
  }

  @override
  Future<Post?> getPostById(String id) async {
    final snapshot = await _posts.doc(id).get(_server);
    return snapshot.exists ? _toPost(snapshot) : null;
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
        if (existing.author.id != currentUser.id || existing.body != body) {
          throw ArgumentError('같은 요청 ID로 다른 게시글을 저장할 수 없습니다.');
        }
        return existing;
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
