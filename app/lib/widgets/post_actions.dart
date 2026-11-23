import 'package:flutter/material.dart';

enum PostAction { delete, report }

Future<PostAction?> showPostMenu(BuildContext context, {required bool own}) {
  return showModalBottomSheet<PostAction>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final color = own ? Theme.of(context).colorScheme.error : null;
      return SafeArea(
        top: false,
        child: ListTile(
          leading: Icon(own ? Icons.delete_outline : Icons.flag),
          title: Text(own ? '내 글 삭제' : '이 글 신고하기'),
          iconColor: color,
          textColor: color,
          onTap: () => Navigator.pop(
            context,
            own ? PostAction.delete : PostAction.report,
          ),
        ),
      );
    },
  );
}

/// 서버가 삭제를 확인했거나 이미 없는 글임을 확인하면 목록에서 제거한다.
Future<bool> handlePostMenu(
  BuildContext context, {
  required bool own,
  required Future<bool> Function() deletePost,
}) async {
  final action = await showPostMenu(context, own: own);
  if (!context.mounted || action == null) return false;
  if (action == PostAction.report) {
    // 신고 사유 선택·접수는 신고 기능에서 연결한다.
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('신고 기능을 준비 중이에요.')));
    return false;
  }
  final deleted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DeleteDialog(deletePost: deletePost),
  );
  if (!context.mounted || deleted == null) return false;
  if (!deleted) await showDeletedPostNotice(context);
  return true;
}

class _DeleteDialog extends StatefulWidget {
  const _DeleteDialog({required this.deletePost});
  final Future<bool> Function() deletePost;

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  bool _sending = false;
  bool _failed = false;

  Future<void> _delete() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _failed = false;
    });
    try {
      final deleted = await widget.deletePost();
      if (mounted) Navigator.pop(context, deleted);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return PopScope(
      canPop: !_sending,
      child: AlertDialog(
        icon: Icon(Icons.delete_outline, color: error),
        title: const Text('이 글을 삭제할까요?'),
        content: Text(
          _failed
              ? '글을 삭제하지 못했어요. 잠시 후 다시 시도해 주세요.'
              : '삭제한 글은 되돌릴 수 없어요. 댓글과 좋아요도 함께 사라져요.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: _sending ? null : () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: _sending ? null : _delete,
            style: TextButton.styleFrom(foregroundColor: error),
            child: Text(_sending ? '삭제 중…' : '삭제'),
          ),
        ],
      ),
    );
  }
}

Future<void> showDeletedPostNotice(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        icon: const Icon(Icons.info_outline),
        title: const Text('삭제된 글이에요'),
        content: const Text(
          '작성자가 이 글을 지웠어요. 확인을 누르면 피드로 돌아가요.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    ),
  );
}
