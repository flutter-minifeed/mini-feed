import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/author.dart';
import '../../models/comment.dart';
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
      if (error.code != 'permission-denied') rethrow;
      // #16 가드가 원본 글이 없는 하위 경로의 조회를 차단한다.
      // 부모도 읽지 못하거나 실제로 존재하면 실패를 그대로 전달한다.
      final parent = await post.get(_server);
      if (!parent.exists) return const [];
      rethrow;
    }
  }
}

Comment _toComment(
  QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  String postId,
) {
  final data = snapshot.data();
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
