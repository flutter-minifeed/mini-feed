import 'package:flutter/material.dart';
import 'package:minifeed/repository/repository_scope.dart';

/// 게시글 본문 최대 글자 수. 이모지 및 한글도 보이는 글자 하나를 1자로 세게 됩니다.
const maxPostLength = 300;

class WriteScreen extends StatefulWidget {
  const WriteScreen({super.key});

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  // 입력칸의 현재 내용을 코드에서 읽고 바꾸는 객체이다.
  // 다시 그릴 때 새로 생성하지 않도록 build 밖에서 생성한다.
  final _controller = TextEditingController();

  // 저장소에 저장하는 중인지. 이 동안 게시 버튼 및 닫기를 막는다.
  bool _isSaving = false;

  // 화면이 닫힐 때 한 번 호출된다. 직접 만든 컨트롤러를 해제한다.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 저장할 본문. 앞뒤 공백만 지우고 중간 줄바꿈은 그대로 둔다.
  String get _body => _controller.text.trim();

  // 공백 및 줄바꿈만 있으면 버려도 잃을 내용이 없으므로 빈 본문으로 봅니다.
  bool get _hasText => _body.isNotEmpty;

  // iOS·웹은 한글 조합이 끝날 때까지 maxLength를 넘는 입력을 허용하므로
  // 화면 입력 제한과 별도로 저장할 본문 길이를 다시 확인한다.
  bool get _withinLimit => _body.characters.length <= maxPostLength;

  bool get _canPost => !_isSaving && _hasText && _withinLimit;

  // 닫기 확인 창을 띄우고, 버리기를 고르면 true를 돌려준다.
  Future<bool> _confirmDiscard() async {
    final colors = Theme.of(context).colorScheme;
    final discard = await showDialog<bool>(
      context: context,
      // 기본 배경막(검정 54%)은 시안의 scrim(검정 32%)보다 진하다.
      barrierColor: colors.scrim.withValues(alpha: 0.32),
      builder: (dialogContext) => AlertDialog(
        // 아이콘 기본색은 secondary인데, 테마에 secondary를 정하지 않아 primary로 지정한다.
        icon: Icon(Icons.edit_off, color: colors.primary),
        title: const Text('작성 중인 글을 버릴까요?'),
        content: const Text(
          '닫으면 지금까지 쓴 글이 사라져요. 임시 저장은 되지 않아요.',
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

    // 창 바깥을 눌러 닫으면 null이 오고, 계속 쓰기와 같게 본다.
    return discard ?? false;
  }

  // X·뒤로가기·pop이 일어날 때마다 호출된다. 실제로 닫혔으면 didPop이 true다.
  Future<void> _onPopInvokedWithResult(bool didPop, Object? result) async {
    // 이미 닫혔거나(게시 성공) 게시 중이면 확인 창을 띄우지 않는다.
    if (didPop || _isSaving) return;
    final discard = await _confirmDiscard();
    if (discard && mounted) Navigator.of(context).pop();
  }

  Future<void> _submit() async {
    // 같은 프레임에 두 번 눌리거나 300자를 넘은 상태면 보내지 않는다.
    if (!_canPost) return;
    setState(() => _isSaving = true);

    // await 뒤에는 화면이 닫혔을 수 있어 context에서 필요한 것을 미리 꺼내 둔다.
    final repository = RepositoryScope.of(context).postRepository;
    final navigator = Navigator.of(context);

    try {
      final post = await repository.addPost(_body);

      // 만든 글을 결과로 돌려줘 피드가 상단 갱신에 쓸 수 있게 한다.
      navigator.pop(post);
    } finally {
      // 실패하면 본문은 그대로 두고 다시 게시할 수 있게 한다. 실패 안내는 MP2 #14
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // setState()가 호출될 때마다 다시 실행된다.
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // maxLength와 같은 기준(보이는 글자 수)으로 센다.
    final length = _controller.text.characters.length;

    // 본문이 있거나 게시 중이면 X·Android 뒤로가기로 바로 닫히지 않게 막는다.
    return PopScope(
      canPop: !_isSaving && !_hasText,
      onPopInvokedWithResult: _onPopInvokedWithResult,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 64,
          // CloseButton은 누르면 maybePop을 불러 PopScope 확인 흐름을 그대로 탄다.
          leading: CloseButton(color: colors.onSurfaceVariant),
          titleSpacing: 0,
          title: const Text('새 글'),
          actionsPadding: const EdgeInsets.only(right: 16),
          actions: [
            FilledButton.icon(
              // onPressed가 null이면 Flutter가 버튼을 비활성(회색)으로 그린다.
              onPressed: _canPost ? _submit : null,
              icon: Icon(_isSaving ? Icons.hourglass_top : Icons.send),
              label: Text(_isSaving ? '게시 중…' : '게시'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 8,
            children: [
              TextField(
                controller: _controller, // 입력 내용이 _controller.text로 들어간다.
                autofocus: true, // 화면이 열리면 바로 키보드가 올라온다.
                // 300자에서 입력을 막고, 더 긴 글을 붙여넣으면 300자까지만 남긴다.
                maxLength: maxPostLength,
                maxLines: null, // 줄 수 제한이 없고 내용에 따라 늘어난다.
                keyboardType:
                    TextInputType.multiline, // 키보드에 줄바꿈(엔터) 키가 나오도록 합니다.
                style: text.bodyLarge,
                decoration: InputDecoration(
                  hintText: '무슨 생각을 하고 있나요?', // 비어 있을 때 흐리게 보이는 안내 문구
                  hintStyle: text.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  border: InputBorder.none, // 입력칸 밑줄을 없앤다.
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                // 글자가 바뀔 때마다 호출. 빈 setState()로 build()를 다시 실행하며
                // 게시 버튼 활성 여부와 카운터를 새 입력 기준으로 다시 그립니다.
                onChanged: (_) => setState(() {}),
                // 기본 카운터는 입력칸과의 간격이 4라 시안(8)과 달라서 숨기고 아래에 직접 그린다.
                buildCounter: (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => null,
              ),
              // TextField 밖에 그려서 기본 카운터처럼 바뀔 때마다 TalkBack이 읽도록 표시한다.
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
            ],
          ),
        ),
      ),
    );
  }
}
