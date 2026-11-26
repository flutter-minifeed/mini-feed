import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/author.dart';
import '../../models/comment.dart';
import '../offline_exception.dart';
import 'comment_repository.dart';

class FirestoreCommentRepository implements CommentRepository {
  FirestoreCommentRepository({required this._firestore});

  static const _server = GetOptions(source: Source.server);
  final FirebaseFirestore _firestore;

  @override
  Future<List<Comment>> getComments(String postId) async {
    final post = _firestore.collection('posts').doc(postId);
    try {
      final result = await post
          .collection('comments')
          .orderBy('createdAt')
          .orderBy(FieldPath.documentId)
          .get(_server);
      return List.unmodifiable(
        result.docs.map((comment) => _toComment(comment, postId)),
      );
    } on FirebaseException catch (error) {
      // #15 연결이 없으면 캐시에 남은 예전 댓글 대신 조회 불가를 알린다.
      if (error.code == 'unavailable') throw const OfflineException();
      if (error.code != 'permission-denied') rethrow;
      // #16 가드가 원본 글이 없는 하위 경로의 조회를 차단한다.
      // 부모도 읽지 못하거나 실제로 존재하면 실패를 그대로 전달한다.
      final DocumentSnapshot<Map<String, dynamic>> parent;
      try {
        parent = await post.get(_server);
      } on FirebaseException catch (parentError) {
        // 부모 글을 확인하는 사이 연결이 끊겨도 같은 오프라인 계약으로 알린다(#15).
        if (parentError.code == 'unavailable') throw const OfflineException();
        rethrow;
      }
      if (!parent.exists) return const [];
      rethrow;
    }
  }

  @override
  Future<AddedComment?> addComment(
    String postId,
    String body, {
    required Author author,
    required String requestId,
  }) async {
    final post = _firestore.collection('posts').doc(postId);
    final ref = post.collection('comments').doc(requestId);
    try {
      // 같은 요청 ID로 동시에 보내도 댓글 문서와 개수 증가는 한 번만 커밋된다.
      // 재시도된 트랜잭션은 기존 댓글을 읽고 쓰기 없이 끝난다.
      final saved = await _firestore.runTransaction<_SaveResult?>((
        transaction,
      ) async {
        final postSnapshot = await transaction.get(post);
        if (!postSnapshot.exists) return null;
        final count = postSnapshot.data()!['commentCount'] as int;
        if ((await transaction.get(ref)).exists) {
          return (created: false, count: count);
        }

        transaction.set(ref, {
          'authorId': author.id,
          'nickName': author.nickName,
          'colorIndex': author.colorIndex,
          'body': body,
          'createdAt': FieldValue.serverTimestamp(),
        });
        // 규칙은 lastCommentId로 같은 작업에서 새 댓글이 생겼는지 확인한다.
        // 개수는 다른 사용자의 동시 등록과 겹쳐도 규칙을 통과하도록 increment로 올린다.
        transaction.update(post, {
          'commentCount': FieldValue.increment(1),
          'lastCommentId': requestId,
        });
        return (created: true, count: count + 1);
      });
      if (saved == null) return null;

      // 서버가 확정한 작성 시각까지 읽고 나서 결과로 돌려준다.
      final comment = _toComment(await ref.get(_server), postId);
      if (!saved.created) {
        checkSameComment(comment, author: author, body: body);
      }
      return (comment: comment, commentCount: saved.count);
    } on FirebaseException catch (error) {
      if (error.code == 'deadline-exceeded') {
        throw TimeoutException(error.message);
      }
      if (error.code == 'unavailable') throw const OfflineException();
      rethrow;
    }
  }
}

/// 트랜잭션 결과. 이번 요청이 댓글을 새로 만들었는지와 그때의 댓글 수.
typedef _SaveResult = ({bool created, int count});

Comment _toComment(
  DocumentSnapshot<Map<String, dynamic>> snapshot,
  String postId,
) {
  final data = snapshot.data();
  if (data == null) {
    throw StateError('댓글 ${snapshot.id}의 데이터가 없습니다.');
  }
  return Comment(
    id: snapshot.id,
    postId: postId,
    author: Author(
      id: data['authorId'] as String,
      nickName: data['nickName'] as String,
      colorIndex: data['colorIndex'] as int,
    ),
    body: data['body'] as String,
    createdAt: (data['createdAt'] as Timestamp).toDate().toLocal(),
  );
}
