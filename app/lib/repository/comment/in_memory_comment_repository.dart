import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/author.dart';
import '../../models/comment.dart';
import 'comment_repository.dart';

/// MP1용 댓글 저장소. JSON은 앱 시작 때 한 번만 읽고, 이후 조회는 메모리 목록으로 한다.
///
/// 앱을 완전히 종료하면 다음 실행은 JSON 초기 상태로 돌아간다.
class InMemoryCommentRepository implements CommentRepository {
  // 외부에서는 load 또는 fromJsonString으로만 만든다.
  InMemoryCommentRepository._(this._comments);

  /// 댓글 더미 데이터 경로. pubspec.yaml의 assets에 등록돼 있다.
  static const assetPath = 'assets/dummy/comment/comments.json';

  /// 앱 시작 때 main.dart에서 한 번 호출한다.
  static Future<InMemoryCommentRepository> load() async {
    final json = await rootBundle.loadString(assetPath);
    return InMemoryCommentRepository.fromJsonString(json);
  }

  /// JSON 문자열을 댓글 목록으로 바꿔 저장소를 만든다.
  ///
  /// [load]가 읽은 파일 내용을 넘긴다. 테스트는 순서를 바꾼 JSON을 직접 넘긴다.
  factory InMemoryCommentRepository.fromJsonString(String json) {
    final comments = (jsonDecode(json) as List)
        .cast<Map<String, dynamic>>()
        .map(_commentFromJson)
        .toList();
    return InMemoryCommentRepository._(comments);
  }

  final List<Comment> _comments;

  @override
  Future<List<Comment>> getComments(String postId) async {
    // 게시글별로 골라 오래된 순으로 정렬한다. 없는 게시글이면 빈 목록이 된다.
    final result = _comments.where((c) => c.postId == postId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(result);
  }

  /// 게시글 목록을 모르므로 null을 돌려주지 않고 항상 저장한다(인터페이스 계약 참고).
  /// 댓글 수는 메모리에 있는 그 게시글의 댓글 수다.
  @override
  Future<AddedComment?> addComment(
    String postId,
    String body, {
    required Author author,
    required String requestId,
  }) async {
    // Firestore처럼 요청 ID는 게시글마다 따로 본다(posts/{postId}/comments/{requestId}).
    final saved = _comments
        .where((c) => c.postId == postId && c.id == requestId)
        .firstOrNull;
    final comment = saved != null
        ? checkSameComment(saved, author: author, body: body)
        : Comment(
            id: requestId,
            postId: postId,
            author: author,
            body: body,
            createdAt: DateTime.now(),
          );
    if (saved == null) _comments.add(comment);
    final count = _comments.where((c) => c.postId == postId).length;
    return (comment: comment, commentCount: count);
  }
}

// JSON 한 건을 Comment로 바꾼다. JSON 형식을 아는 곳은 이 파일뿐이다.
Comment _commentFromJson(Map<String, dynamic> json) {
  return Comment(
    id: json['id'] as String,
    postId: json['postId'] as String,
    // JSON은 작성자 필드가 평평하게 들어 있어 Author로 묶는다.
    author: Author(
      id: json['authorId'] as String,
      nickName: json['nickName'] as String,
      colorIndex: json['colorIndex'] as int,
    ),
    body: json['body'] as String,
    // "+09:00"이 붙은 문자열은 UTC로 읽히므로 기기 시간대로 바꾼다.
    createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
  );
}
