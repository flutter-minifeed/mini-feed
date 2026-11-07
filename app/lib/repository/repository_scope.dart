import 'package:flutter/widgets.dart';

import 'comment_repository.dart';
import 'post_repository.dart';

/// 앱 전체가 저장소 객체 하나씩을 함께 쓰게 하는 통로.
///
/// 화면은 [RepositoryScope.of]로 꺼내 쓰고, 직접 저장소를 만들지 않는다.
/// 타입이 인터페이스라 화면은 메모리 구현인지 Firestore 구현인지 모른다.
class RepositoryScope extends InheritedWidget {
  const RepositoryScope({
    super.key,
    required this.postRepository,
    required this.commentRepository,
    required super.child,
  });

  /// 피드·글쓰기·상세가 함께 쓰는 게시글 저장소.
  final PostRepository postRepository;

  /// 상세 화면이 쓰는 댓글 저장소.
  final CommentRepository commentRepository;

  /// 위젯 트리 위쪽에서 가장 가까운 RepositoryScope를 찾는다.
  ///
  /// 화면에서는 `RepositoryScope.of(context).postRepository`처럼 쓴다.
  static RepositoryScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RepositoryScope>();
    assert(scope != null, 'RepositoryScope가 위젯 트리 위에 없습니다.');
    return scope!;
  }

  // 저장소 객체가 바뀌었을 때만 아래 화면을 다시 그린다.
  @override
  bool updateShouldNotify(RepositoryScope oldWidget) {
    return postRepository != oldWidget.postRepository ||
        commentRepository != oldWidget.commentRepository;
  }
}
