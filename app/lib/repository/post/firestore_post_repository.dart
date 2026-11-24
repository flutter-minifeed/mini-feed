import 'dart:async';
import 'dart:convert';

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
  Future<Post> addPost(
    String body, {
    String? requestId,
    List<String> tags = const [],
  }) async {
    final savedTags = List<String>.unmodifiable(tags);
    final ref = _posts.doc(requestId);
    final fields = <String, Object>{
      'authorId': currentUser.id,
      'nickName': currentUser.nickName,
      'colorIndex': currentUser.colorIndex,
      'body': body,
      if (savedTags.isNotEmpty) 'tags': savedTags,
      'createdAt': FieldValue.serverTimestamp(),
      'likeCount': 0,
      'commentCount': 0,
    };
    _checkPostSize(ref.path, fields);
    try {
      // 같은 문서를 동시에 읽고 생성해도 커밋은 한 번만 성공한다.
      // 재시도된 트랜잭션은 기존 문서를 읽고 쓰기 없이 끝난다.
      final existing = await _firestore.runTransaction<Post?>((
        transaction,
      ) async {
        final snapshot = await transaction.get(ref);
        if (snapshot.exists) return _toPost(snapshot);

        transaction.set(ref, fields);
        return null;
      });

      if (existing != null) {
        return checkSameRequest(
          existing,
          author: currentUser,
          body: body,
          tags: savedTags,
        );
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

// Firestore 문서명에는 16바이트, 문서에는 별도로 32바이트가 더해진다.
// https://firebase.google.com/docs/firestore/storage-size
void _checkPostSize(String path, Map<String, Object> fields) {
  int stringBytes(String value) => utf8.encode(value).length + 1;
  int stringsBytes(Iterable<String> values) =>
      values.fold<int>(0, (bytes, value) => bytes + stringBytes(value));

  var bytes = 16 + stringsBytes(path.split('/')) + 32;
  for (final entry in fields.entries) {
    bytes += stringBytes(entry.key);
    bytes += switch (entry.value) {
      String value => stringBytes(value),
      List<String> tags => stringsBytes(tags),
      int() || FieldValue() => 8, // 정수와 서버 작성 시각
      _ => throw StateError('크기 계산이 필요한 게시글 필드: ${entry.key}'),
    };
  }
  if (bytes > 1024 * 1024) throw const PostTooLargeException();
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
    tags: (data['tags'] as List?)?.cast<String>() ?? const [],
    createdAt: (data['createdAt'] as Timestamp).toDate().toLocal(),
    likeCount: data['likeCount'] as int,
    commentCount: data['commentCount'] as int,
    likedByMe: false,
  );
}
