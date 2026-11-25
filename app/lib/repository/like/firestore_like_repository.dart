import 'package:cloud_firestore/cloud_firestore.dart';

import '../offline_exception.dart';
import 'like_repository.dart';

/// `posts/{postId}/likes/{uid}` 문서 하나가 좋아요 하나다.
/// 문서 ID가 누른 사람의 UID라서 같은 사람은 한 글에 한 문서만 가진다.
class FirestoreLikeRepository implements LikeRepository {
  FirestoreLikeRepository({required this._firestore, required this._userId});

  final FirebaseFirestore _firestore;

  /// 좋아요 문서 ID로 쓰는 현재 사용자 UID.
  final String _userId;

  @override
  Future<LikeState?> setLike(String postId, {required bool liked}) async {
    try {
      return await _setLike(postId, liked: liked);
    } on FirebaseException catch (error) {
      // #15 트랜잭션은 서버 연결이 필요하다. 화면이 Firestore 코드를 몰라도 되게 바꾼다.
      if (error.code == 'unavailable') throw const OfflineException();
      rethrow;
    }
  }

  Future<LikeState?> _setLike(String postId, {required bool liked}) {
    final post = _firestore.collection('posts').doc(postId);
    final like = post.collection('likes').doc(_userId);

    // 글과 내 좋아요를 같은 트랜잭션에서 읽는다.
    // 다른 사용자가 그사이 개수를 바꾸면 커밋이 거절되고 새 값으로 다시 실행된다.
    return _firestore.runTransaction<LikeState?>((transaction) async {
      final postSnapshot = await transaction.get(post);
      if (!postSnapshot.exists) return null;
      final likeCount = postSnapshot.data()!['likeCount'] as int;

      final likeSnapshot = await transaction.get(like);
      // 이미 원하는 상태면 쓰지 않아서 중복 설정·취소가 개수를 바꾸지 않는다.
      if (likeSnapshot.exists == liked) {
        return (liked: liked, likeCount: likeCount);
      }

      final change = liked ? 1 : -1;
      if (liked) {
        transaction.set(like, {'createdAt': FieldValue.serverTimestamp()});
      } else {
        transaction.delete(like);
      }
      // 읽은 개수를 그대로 쓰면, 다른 사용자가 먼저 커밋했을 때 규칙의 ±1 검사에
      // 걸려 재시도 없이 권한 거부가 난다. 서버가 현재 값에 더하도록 increment를 쓴다.
      transaction.update(post, {'likeCount': FieldValue.increment(change)});
      return (liked: liked, likeCount: likeCount + change);
    });
  }
}
