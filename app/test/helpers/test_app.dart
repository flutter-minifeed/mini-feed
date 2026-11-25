import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:minifeed/main.dart';
import 'package:minifeed/models/author.dart';
import 'package:minifeed/models/comment.dart';
import 'package:minifeed/models/post.dart';
import 'package:minifeed/repository/comment/comment_repository.dart';
import 'package:minifeed/repository/post/post_repository.dart';
import 'package:minifeed/repository/repository_scope.dart';
import 'package:minifeed/viewmodels/write_view_model.dart';

const testUser = Author(id: 'user-test', nickName: '테스트', colorIndex: 0);

/// 실제 메모리 저장소는 assets JSON을 읽어서 testWidgets 안에서 끝나지 않을 수 있다.
class FakePostRepository implements PostRepository {
  FakePostRepository({this.currentUser = testUser});

  final List<Post> posts = [];

  final List<String> addedBodies = [];
  final List<String?> requestIds = [];

  Completer<void>? blockAddUntil;

  @override
  final Author currentUser;

  @override
  Future<List<Post>> getPosts() async => List.unmodifiable(posts);

  @override
  Future<PostPage> getPostPage({PostCursor? after}) async {
    final ordered = [...posts]..sort(comparePostsNewestFirst);
    return PostPage.fromOrderedPosts(ordered, after: after);
  }

  @override
  Future<Post?> getPostById(String id) async =>
      posts.where((post) => post.id == id).firstOrNull;

  @override
  Future<Post> addPost(String body, {String? requestId}) async {
    addedBodies.add(body);
    requestIds.add(requestId);
    final id = requestId ?? 'fake-${addedBodies.length}';
    await blockAddUntil?.future;
    final saved = posts.where((post) => post.id == id).firstOrNull;
    if (saved != null) {
      return checkSameRequest(saved, author: currentUser, body: body);
    }
    final post = Post(
      id: id,
      author: currentUser,
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
  /// 테스트가 넣어 두는 댓글. 넣은 순서(오래된 순)대로 돌려준다.
  final List<Comment> comments = [];

  @override
  Future<List<Comment>> getComments(String postId) async =>
      comments.where((comment) => comment.postId == postId).toList();

  @override
  Future<AddedComment?> addComment(
    String postId,
    String body, {
    required Author author,
    required String requestId,
  }) async {
    // 실제 저장소와 같은 계약: 같은 요청 ID는 한 번만 저장하고 기존 댓글을 돌려준다.
    final saved = comments.where((c) => c.id == requestId).firstOrNull;
    final comment = saved != null
        ? checkSameComment(saved, author: author, body: body)
        : Comment(
            id: requestId,
            postId: postId,
            author: author,
            body: body,
            createdAt: DateTime.now(),
          );
    if (saved == null) comments.add(comment);
    final count = comments.where((c) => c.postId == postId).length;
    return (comment: comment, commentCount: count);
  }
}

Future<FakePostRepository> pumpApp(WidgetTester tester) async {
  final postRepository = FakePostRepository();
  await tester.pumpWidget(
    RepositoryScope(
      postRepository: postRepository,
      commentRepository: FakeCommentRepository(),
      child: MyApp(
        createWriteViewModel: () =>
            WriteViewModelImpl(repository: postRepository),
      ),
    ),
  );
  return postRepository;
}
