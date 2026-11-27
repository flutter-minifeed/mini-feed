import 'dart:async';

import 'package:flutter/material.dart';

import '../models/comment.dart';
import '../models/post.dart';
import '../repository/offline_exception.dart';
import '../repository/repository_scope.dart';
import '../widgets/comment_input.dart';
import '../widgets/comment_tile.dart';
import '../widgets/offline_banner.dart';
import '../widgets/post_card.dart';

// 상세 화면이 한 번에 불러오는 글과 댓글 목록.
// 오프라인이면 저장된 글만 보여주고 댓글은 null로 둔다(#15).
typedef _DetailData = ({Post post, List<Comment>? comments});

/// 게시글 상세 화면 (#9).
///
/// 피드 카드 본문을 누르면 [postId]만 넘겨 열고,
/// 댓글 아이콘을 누르면 [focusComment]를 true로 넘겨 댓글 입력창에 바로 포커스를 준다.
class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.postId,
    this.focusComment = false,
  });

  final String postId;
  final bool focusComment;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _commentController = TextEditingController();
  final _commentFocus = FocusNode();

  // 글·댓글을 불러오는 작업. 화면을 다시 그려도 새로 부르지 않게 한 번만 만든다.
  // 오프라인에서 다시 불러올 때만 새 작업으로 바꾼다.
  Future<_DetailData?>? _data;
  Timer? _offlineRetry;

  @override
  void initState() {
    super.initState();
    // 입력창은 글을 다 불러온 뒤에 화면에 붙는다. 아직 붙지 않은 FocusNode에
    // 포커스를 요청하면 Flutter가 기억해 뒀다가, 붙는 순간 포커스를 주고 키보드를 연다.
    if (widget.focusComment) _commentFocus.requestFocus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // RepositoryScope.of는 initState에서 부를 수 없어서, 여기서 처음 한 번만 부른다.
    _data ??= _load(RepositoryScope.of(context));
  }

  @override
  void dispose() {
    _offlineRetry?.cancel();
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  Future<_DetailData?> _load(RepositoryScope repositories) async {
    final Post? post;
    try {
      post = await repositories.postRepository.getPostById(widget.postId);
    } on OfflineException {
      // 캐시에도 없는 글이면 보여줄 본문이 없다. 안내를 띄우고 연결되면 다시 읽는다.
      _scheduleOfflineRetry();
      rethrow;
    }
    if (post == null) return null;
    try {
      final comments = await repositories.commentRepository.getComments(
        post.id,
      );
      return (post: post, comments: comments);
    } on OfflineException {
      _scheduleOfflineRetry();
      return (post: post, comments: null);
    }
  }

  // 연결되면 자동으로 다시 불러온다는 안내(M14)대로 일정 시간 뒤 다시 읽는다.
  // 읽는 사이 화면이 닫혔으면 타이머를 남기지 않는다.
  void _scheduleOfflineRetry() {
    if (!mounted) return;
    _offlineRetry?.cancel();
    _offlineRetry = Timer(offlineRetryInterval, _reload);
  }

  // 이전 결과를 화면에 둔 채로 글·댓글을 다시 읽는다.
  void _reload() {
    if (!mounted) return;
    _offlineRetry?.cancel();
    // 화살표 함수로 쓰면 대입한 Future가 반환돼 setState가 거부한다.
    setState(() {
      _data = _load(RepositoryScope.of(context));
    });
  }

  // 상세 안의 댓글 버튼. 입력창을 직접 누른 것과 같게 처리한다(#49 글쓰기와 같은 방식).
  // 포커스가 없으면 포커스를 주고, Android 뒤로가기로 키보드만 내린 상태(포커스는 남음)면
  // 키보드를 다시 올린다.
  void _focusCommentInput() {
    _commentFocus.context
        ?.findAncestorStateOfType<EditableTextState>()
        ?.requestKeyboard();
  }

  void _sendComment(String body) {
    // TODO(#20): MP3에서 commentRepository로 등록하고, 성공하면 입력을 지운다.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('게시글')),
      body: FutureBuilder<_DetailData?>(
        future: _data,
        builder: (context, snapshot) {
          // 다시 불러오는 동안에는 이전 결과를 그대로 보여준다.
          if (snapshot.connectionState != ConnectionState.done &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.error is OfflineException) {
            // 자동 재확인을 기다리지 않고 바로 확인할 수 있게 다시 시도를 둔다(배너와 같은 방식).
            return _Message(
              '오프라인이라 게시글을 불러올 수 없어요. 연결되면 자동으로 다시 불러와요.',
              onRetry: _reload,
            );
          }
          if (snapshot.hasError) {
            return const _Message('게시글을 불러오지 못했어요.');
          }
          final data = snapshot.data;
          if (data == null) {
            return const _Message('삭제되었거나 없는 게시글이에요.');
          }
          // 글과 댓글의 상대 시간을 같은 시각 기준으로 센다.
          final now = DateTime.now();
          final comments = data.comments;
          return Column(
            children: [
              if (comments == null)
                OfflineBanner(
                  message: '오프라인이에요. 저장된 글만 보여주고 있어요.',
                  onRetry: _reload,
                ),
              Expanded(
                child: ListView(
                  children: [
                    PostCard(
                      post: data.post,
                      now: now,
                      onComments: _focusCommentInput,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        // 오프라인이면 저장된 글의 댓글 수를 보여준다.
                        '댓글 ${comments?.length ?? data.post.commentCount}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (comments == null)
                      const _OfflineComments()
                    else
                      for (final comment in comments)
                        CommentTile(
                          key: ValueKey(comment.id),
                          comment: comment,
                          now: now,
                        ),
                  ],
                ),
              ),
              // 키보드가 올라오면 Scaffold가 body 높이를 줄여서 입력창이 키보드 바로 위에 온다.
              // 키보드가 없을 때는 SafeArea가 시스템 내비게이션 바만큼 띄운다.
              SafeArea(
                top: false,
                child: CommentInput(
                  controller: _commentController,
                  focusNode: _commentFocus,
                  onSend: _sendComment,
                  enabled: comments != null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// 오프라인이라 댓글 대신 보여주는 안내(M14).
class _OfflineComments extends StatelessWidget {
  const _OfflineComments();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Icon(Icons.wifi_off, size: 20, color: colors.onSurfaceVariant),
          Expanded(
            child: Text(
              '오프라인이라 댓글을 불러올 수 없어요. 연결되면 자동으로 다시 불러와요.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

// 글을 불러오지 못했거나 없을 때 가운데에 띄우는 안내 문구.
class _Message extends StatelessWidget {
  const _Message(this.text, {this.onRetry});

  final String text;

  /// 있으면 안내 아래에 다시 시도 버튼을 둔다.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final retry = onRetry;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (retry != null)
              TextButton(onPressed: retry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
