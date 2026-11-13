import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:minifeed/main.dart';
import 'package:minifeed/models/author.dart';
import 'package:minifeed/models/comment.dart';
import 'package:minifeed/models/post.dart';
import 'package:minifeed/repository/comment/comment_repository.dart';
import 'package:minifeed/repository/post/post_repository.dart';
import 'package:minifeed/repository/repository_scope.dart';

const testUser = Author(id: 'user-test', nickName: '테스트', colorIndex: 0);

/// 받은 본문을 기록하는 가짜 게시글 저장소.
///
/// 실제 메모리 저장소는 assets JSON을 읽어서 testWidgets 안에서 끝나지 않을 수 있다.
class FakePostRepository implements PostRepository {
  final List<Post> posts = [];

  /// addPost가 받은 본문. 공백 제거·중복 요청 검사에 쓴다.
  final List<String> addedBodies = [];

  /// 값을 넣으면 addPost가 이 Completer가 끝날 때까지 멈춘다. 게시 중 상태 검사에 쓴다.
  Completer<void>? addGate;

  @override
  Author get currentUser => testUser;

  @override
  Future<List<Post>> getPosts() async => List.unmodifiable(posts);

  @override
  Future<Post?> getPostById(String id) async =>
      posts.where((post) => post.id == id).firstOrNull;

  @override
  Future<Post> addPost(String body) async {
    addedBodies.add(body);
    await addGate?.future; // addGate가 없으면(null) 바로 넘어간다.
    final post = Post(
      id: 'fake-${addedBodies.length}',
      author: testUser,
      body: body,
      createdAt: DateTime.now(),
      likeCount: 0,
      commentCount: 0,
      likedByMe: false,
    );
    posts.insert(0, post);
    return post;
  }
}

class FakeCommentRepository implements CommentRepository {
  @override
  Future<List<Comment>> getComments(String postId) async => [];
}

/// 가짜 저장소를 넣은 앱을 띄우고, 검사할 수 있게 게시글 저장소를 돌려준다.
Future<FakePostRepository> pumpApp(WidgetTester tester) async {
  final postRepository = FakePostRepository();
  await tester.pumpWidget(
    RepositoryScope(
      postRepository: postRepository,
      commentRepository: FakeCommentRepository(),
      child: const MyApp(),
    ),
  );
  return postRepository;
}
