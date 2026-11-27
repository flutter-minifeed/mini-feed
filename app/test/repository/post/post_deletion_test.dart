import 'package:flutter_test/flutter_test.dart';
import 'package:minifeed/models/author.dart';
import 'package:minifeed/repository/post/in_memory_post_repository.dart';

void main() {
  const me = Author(id: 'me', nickName: '작성자', colorIndex: 0);

  test('동시에 같은 글을 삭제하면 한 번만 성공하고 게시 재시도로 되살릴 수 없다', () async {
    // given
    final posts = InMemoryPostRepository.fromJsonString('[]', currentUser: me);
    final post = await posts.addPost('테스트', requestId: 'delete-1');

    // when
    final removed = await Future.wait([
      posts.deletePost(post.id),
      posts.deletePost(post.id),
    ]);

    // then
    expect(removed, unorderedEquals([true, false]));
    expect(await posts.getPostById(post.id), isNull);
    expect((await posts.getPostPage()).posts, isEmpty);
    await expectLater(
      posts.addPost('테스트', requestId: post.id),
      throwsStateError,
    );
  });

  test('다른 작성자의 글 삭제를 거부하고 글을 보존한다', () async {
    // given
    final posts = InMemoryPostRepository.fromJsonString(
      '[{"id":"other","authorId":"peer","nickName":"작성자","colorIndex":0,'
      '"body":"타인 글","createdAt":"2026-01-01T00:00:00Z","likeCount":0,'
      '"commentCount":0,"likedByMe":false}]',
      currentUser: me,
    );

    // when
    await expectLater(posts.deletePost('other'), throwsStateError);

    // then
    expect((await posts.getPostById('other'))?.body, '타인 글');
  });
}
