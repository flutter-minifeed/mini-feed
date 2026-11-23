import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/author.dart';
import '../../models/post.dart';
import 'post_repository.dart';

/// MP1용 게시글 저장소. JSON은 앱 시작 때 한 번만 읽고, 이후 조회·작성은 메모리 목록으로 한다.
///
/// 조회할 때마다 JSON을 다시 읽으면 새로 쓴 글이 사라지기 때문이다.
/// 앱을 완전히 종료하면 메모리가 비워져 다음 실행은 JSON 초기 상태로 돌아간다.
class InMemoryPostRepository implements PostRepository {
  // 외부에서는 load 또는 fromJsonString으로만 만든다.
  InMemoryPostRepository._(this._posts, this.currentUser);

  /// 게시글 더미 데이터 경로. pubspec.yaml의 assets에 등록돼 있다.
  static const assetPath = 'assets/dummy/post/posts.json';

  /// 앱 시작 때 main.dart에서 한 번 호출한다.
  static Future<InMemoryPostRepository> load({
    required Author currentUser,
  }) async {
    final json = await rootBundle.loadString(assetPath);
    return InMemoryPostRepository.fromJsonString(
      json,
      currentUser: currentUser,
    );
  }

  /// JSON 문자열을 게시글 목록으로 바꿔 저장소를 만든다.
  ///
  /// [load]가 읽은 파일 내용을 넘긴다. 테스트는 순서를 바꾼 JSON을 직접 넘긴다.
  factory InMemoryPostRepository.fromJsonString(
    String json, {
    required Author currentUser,
  }) {
    final posts = (jsonDecode(json) as List)
        .cast<Map<String, dynamic>>()
        .map(_postFromJson)
        .toList();
    // JSON 순서에 기대지 않고 직접 최신순으로 맞춘다.
    posts.sort(comparePostsNewestFirst);
    return InMemoryPostRepository._(posts, currentUser);
  }

  /// 새 글의 작성자. MP2 #12 익명 인증이 생기면 그 결과로 바뀐다.
  @override
  final Author currentUser;

  final List<Post> _posts; // 항상 최신순을 유지한다.
  int _localCount = 0; // 새 글 id 번호. JSON id(post-01~50)와 겹치지 않게 접두어를 다르게 쓴다.

  @override
  Future<List<Post>> getPosts() async {
    // 화면이 목록을 직접 고치지 못하게 수정 불가 복사본을 준다.
    return List.unmodifiable(_posts);
  }

  @override
  Future<PostPage> getPostPage({PostCursor? after}) async =>
      PostPage.fromOrderedPosts(_posts, after: after);

  @override
  Future<Post?> getPostById(String id) async => _findPost(id);

  @override
  Future<Post> addPost(
    String body, {
    String? requestId,
    List<String> tags = const [],
  }) async {
    final id = requestId ?? _nextPostId();
    final saved = _findPost(id);
    if (saved != null) {
      return checkSameRequest(
        saved,
        author: currentUser,
        body: body,
        tags: tags,
      );
    }

    final post = Post(
      id: id,
      author: currentUser,
      body: body,
      tags: tags,
      createdAt: DateTime.now(),
      likeCount: 0,
      commentCount: 0,
      likedByMe: false,
    );
    final index = _posts.indexWhere(
      (saved) => comparePostsNewestFirst(saved, post) > 0,
    );
    _posts.insert(index < 0 ? _posts.length : index, post);
    return post;
  }

  Post? _findPost(String id) =>
      _posts.where((post) => post.id == id).firstOrNull;

  String _nextPostId() {
    var id = 'post-local-${++_localCount}';
    while (_findPost(id) != null) {
      id = 'post-local-${++_localCount}';
    }
    return id;
  }
}

// JSON 한 건을 Post로 바꾼다. JSON 형식을 아는 곳은 이 파일뿐이다.
Post _postFromJson(Map<String, dynamic> json) {
  return Post(
    id: json['id'] as String,
    // JSON은 작성자 필드가 평평하게 들어 있어 Author로 묶는다.
    author: Author(
      id: json['authorId'] as String,
      nickName: json['nickName'] as String,
      colorIndex: json['colorIndex'] as int,
    ),
    body: json['body'] as String,
    tags: (json['tags'] as List?)?.cast<String>() ?? const [],
    // "+09:00"이 붙은 문자열은 UTC로 읽히므로 기기 시간대로 바꾼다.
    createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    likeCount: json['likeCount'] as int,
    commentCount: json['commentCount'] as int,
    likedByMe: json['likedByMe'] as bool,
  );
}
