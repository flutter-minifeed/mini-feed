import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/comment.dart';
import 'comment_repository.dart';

// MP1용 댓글 저장소. JSON은 앱 시작 때 한 번만 읽고, 이후 조회는 메모리 목록으로 한다.
// 앱을 완전히 종료하면 다음 실행은 JSON 초기 상태로 돌아간다.
class InMemoryCommentRepository implements CommentRepository {
  // 외부에서는 load 또는 fromJsonString으로만 만든다.
  InMemoryCommentRepository._(this._comments);

  static const assetPath = 'assets/dummy/comment/comments.json';

  // 앱 시작 때 한 번 호출한다. bundle은 테스트에서 바꿔 넣을 수 있게 열어 뒀다.
  static Future<InMemoryCommentRepository> load({AssetBundle? bundle}) async {
    final json = await (bundle ?? rootBundle).loadString(assetPath);
    return InMemoryCommentRepository.fromJsonString(json);
  }

  // JSON 문자열로 만든다. 단위 테스트는 asset 없이 이 생성자를 쓴다.
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
}

// JSON 한 건을 Comment로 바꾼다. JSON 형식을 아는 곳은 이 파일뿐이다.
Comment _commentFromJson(Map<String, dynamic> json) {
  return Comment(
    id: json['id'] as String,
    postId: json['postId'] as String,
    authorId: json['authorId'] as String,
    nickName: json['nickName'] as String,
    colorIndex: json['colorIndex'] as int,
    body: json['body'] as String,
    // "+09:00"이 붙은 문자열은 UTC로 읽히므로 기기 시간대로 바꾼다.
    createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
  );
}
