import 'package:flutter/material.dart';
import 'package:minifeed/ai/live_topic_analysis.dart';
import 'package:minifeed/ai/topic_analyzer.dart';
import 'package:minifeed/models/compose_tag.dart';
import 'package:minifeed/widgets/compose_tag_editor.dart';
import 'package:minifeed/viewmodels/write_view_model.dart';
import 'package:minifeed/widgets/author_tile.dart';

const maxPostLength = 300;

class WriteScreen extends StatefulWidget {
  const WriteScreen({
    super.key,
    required this.viewModel,
    this.loadAnalyzer = TopicAnalyzer.load,
  });

  final WriteViewModel viewModel;
  final Future<TopicAnalyzer> Function() loadAnalyzer;

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _tagController = TextEditingController();
  final _selection = ComposeTags();
  String? _tagError;

  // 글쓰기 화면을 닫으면 실패 안내도 함께 없어지도록 화면 전용으로 둔다.
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _isConfirmingDiscard = false;

  WriteViewModel get _viewModel => widget.viewModel;
  bool get _isSaving => _viewModel.status == WriteStatus.saving;

  @override
  void dispose() {
    _viewModel.dispose();
    _controller.dispose();
    _tagController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showKeyboard() {
    _focusNode.context
        ?.findAncestorStateOfType<EditableTextState>()
        ?.requestKeyboard();
  }

  String get _body => _controller.text.trim();

  bool get _hasText => _body.isNotEmpty;

  // iOS·웹은 한글 조합이 끝날 때까지 maxLength를 넘는 입력을 허용해서 저장 전에 다시 센다.
  bool get _withinLimit => _body.characters.length <= maxPostLength;

  bool get _canPost =>
      !_isSaving &&
      _viewModel.status != WriteStatus.succeeded &&
      _hasText &&
      _withinLimit;

  bool _addTag(String input, TagSource source) {
    if (_isSaving) return false;
    setState(() {
      _tagError = _selection.add(input, source);
      if (_tagError == null && source == TagSource.manual) {
        _tagController.clear();
      }
    });
    return _tagError == null;
  }

  Future<bool> _confirmDiscard() async {
    final colors = Theme.of(context).colorScheme;
    final discard = await showDialog<bool>(
      context: context,
      barrierColor: colors.scrim.withValues(alpha: 0.32),
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.edit_off, color: colors.primary),
        title: const Text('작성 중인 글을 버릴까요?'),
        contentTextStyle: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: colors.onSurfaceVariant),
        content: Text(
          _viewModel.status == WriteStatus.timedOut
              ? '입력한 본문은 사라져요. 이미 요청한 글은 나중에 게시될 수 있어요.'
              : '닫으면 지금까지 쓴 글이 사라져요. 임시 저장은 되지 않아요.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('계속 쓰기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: colors.error),
            child: const Text('버리기'),
          ),
        ],
      ),
    );

    return discard ?? false;
  }

  Future<void> _onPopInvokedWithResult(bool didPop, Object? result) async {
    if (didPop || _isSaving || _isConfirmingDiscard) return;
    _isConfirmingDiscard = true;
    try {
      final discard = await _confirmDiscard();
      if (discard && mounted) Navigator.of(context).pop();
    } finally {
      _isConfirmingDiscard = false;
    }
  }

  Future<void> _submit() async {
    if (!mounted || !_canPost) return;
    _messengerKey.currentState?.clearSnackBars();
    if (_tagController.text.trim().isNotEmpty &&
        !_addTag(_tagController.text, TagSource.manual)) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final viewModel = _viewModel;
    final post = await viewModel.submit(_body, tags: _selection.names);

    if (!mounted || !identical(viewModel, _viewModel)) return;
    if (post != null) {
      Navigator.of(context).pop(post);
      return;
    }

    final message = viewModel.status == WriteStatus.timedOut
        ? '응답이 늦어요. 입력한 글은 그대로 있고, 요청한 글은 나중에 게시될 수 있어요.'
        : '올리지 못했어요. 입력한 글은 그대로 있어요.';
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        action: SnackBarAction(label: '다시 시도', onPressed: _submit),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) =>
          ScaffoldMessenger(key: _messengerKey, child: _buildContent(context)),
    );
  }

  Widget _buildContent(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final length = _controller.text.characters.length;

    return PopScope(
      canPop:
          !_isSaving &&
          !_hasText &&
          _selection.tags.isEmpty &&
          _tagController.text.trim().isEmpty &&
          _viewModel.status != WriteStatus.timedOut,
      onPopInvokedWithResult: _onPopInvokedWithResult,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 64,
          leading: CloseButton(color: colors.onSurfaceVariant),
          titleSpacing: 0,
          title: const Text('새 글'),
          actionsPadding: const EdgeInsets.only(right: 16),
          actions: [
            FilledButton.icon(
              onPressed: _canPost ? _submit : null,
              icon: Icon(_isSaving ? Icons.hourglass_top : Icons.send),
              label: Text(_isSaving ? '게시 중…' : '게시'),
            ),
          ],
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _showKeyboard,
          child: SizedBox.expand(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 8,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: AuthorTile(
                      author: _viewModel.author,
                      subtitle: '이 기기의 익명 닉네임 · 바꿀 수 없어요',
                    ),
                  ),
                  TextField(
                    key: const ValueKey('post-body'),
                    readOnly: _isSaving,
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    maxLength: maxPostLength,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: text.bodyLarge,
                    decoration: InputDecoration(
                      hintText: '무슨 생각을 하고 있나요?',
                      hintStyle: text.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => setState(() {}),
                    buildCounter: (
                      context, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                  ),
                  Semantics(
                    container: true,
                    liveRegion: true,
                    child: Text(
                      '$length / $maxPostLength',
                      style: text.labelSmall?.copyWith(
                        color: length >= maxPostLength
                            ? colors.error
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ComposeTagEditor(
                      tags: _selection.tags,
                      controller: _tagController,
                      enabled: !_isSaving,
                      error: _tagError,
                      onChanged: (_) => setState(() => _tagError = null),
                      onAdd: () =>
                          _addTag(_tagController.text, TagSource.manual),
                      onRemove: (tag) => setState(() {
                        _selection.remove(tag);
                        _tagError = null;
                      }),
                    ),
                  ),
                  LiveTopicAnalysis(
                    input: _body,
                    keyboardVisible:
                        MediaQuery.viewInsetsOf(context).bottom > 0,
                    loadAnalyzer: widget.loadAnalyzer,
                    selected: _selection.names,
                    onSelected: _isSaving
                        ? null
                        : (name) => _addTag(name, TagSource.recommended),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
