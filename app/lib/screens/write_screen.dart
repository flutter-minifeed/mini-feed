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
  bool _isPosting = false;

  // 화면이 닫힐 때 한 번 호출된다. 직접 만든 컨트롤러를 해제한다.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 공백 및 줄바꿈만 있으면 버려도 잃을 내용이 없으므로 빈 본문으로 봅니다.
  bool get _hasText => _controller.text.trim().isNotEmpty;

  bool get _canPost => !_isPosting && _hasText;

  // 닫기 확인 창을 띄우고, 버리기를 고르면 true를 돌려준다.
  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('작성 중인 글을 버릴까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('계속 쓰기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('버리기'),
          ),
        ],
      ),
    );

    // 창 바깥을 눌러 닫으면 null이 오고, 계속 쓰기와 같게 본다.
    return discard ?? false;
  }

  // X·뒤로가기·pop이 일어날 때마다 호출된다. 실제로 닫혔으면 didPop이 true다.
  Future<void> _onPopBlocked(bool didPop, Object? result) async {
    // 이미 닫혔거나(게시 성공) 게시 중이면 확인 창을 띄우지 않는다.
    if (didPop || _isPosting) return;
    final discard = await _confirmDiscard();
    if (discard && mounted) Navigator.of(context).pop();
  }

  Future<void> _submit() async {
    // 같은 프레임에 두 번 눌려도 요청은 한 번만 보낸다.
    if (_isPosting) return;
    setState(() => _isPosting = true);

    // await 뒤에는 화면이 닫혔을 수 있어 context에서 필요한 것을 미리 꺼내 둔다.
    final repository = RepositoryScope.of(context).postRepository;
    final navigator = Navigator.of(context);

    try {
      // 앞뒤 공백만 지우고 중간 줄바꿈은 그대로 저장한다.
      final post = await repository.addPost(_controller.text.trim());

      // 만든 글을 결과로 돌려줘 피드가 상단 갱신에 쓸 수 있게 한다.
      navigator.pop(post);
    } finally {
      // 실패하면 본문은 그대로 두고 다시 게시할 수 있게 한다. 실패 안내는 MP2 #14
      if (mounted) setState(() => _isPosting = false);
    }
  }

  // setState()가 호출될 때마다 다시 실행된다.
  @override
  Widget build(BuildContext context) {
    // 본문이 있거나 게시 중이면 X·Android 뒤로가기로 바로 닫히지 않게 막는다.
    return PopScope(
      canPop: !_isPosting && !_hasText,
      onPopInvokedWithResult: _onPopBlocked,
      child: Scaffold(
        appBar: AppBar(
          // 피드에서 fullscreenDialog: true로 열어서 AppBar가 X버튼을 자동으로 만들어준다.
          title: const Text('글쓰기'),
          // 상단 바 오른쪽에 놓이는 버튼들
          actions: [
            TextButton(
              // onPressed가 null이면 Flutter가 버튼을 비활성(회색)으로 그린다.
              onPressed: _canPost ? _submit : null,
              child: const Text('게시'),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller, // 입력 내용이 _controller.text로 들어간다.
            autofocus: true, // 화면이 열리면 바로 키보드가 올라온다.
            // 300자에서 입력을 막고, 더 긴 글을 붙여넣으면 300자까지만 남긴다.
            maxLength: maxPostLength,
            maxLines: null, // 줄 수 제한이 없고 내용에 따라 늘어난다.
            expands: true, // 입력칸이 남은 화면 높이를 모두 채운다.
            keyboardType: TextInputType.multiline, // 키보드에 줄바꿈(엔터) 키가 나오도록 합니다.
            // expands일 때 없으면 커서가 칸의 세로 가운데에서 시작합니다.
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText: '내용을 입력하세요', // 비어 있을 때 흐리게 보이는 안내 문구
              border: InputBorder.none, // 입력칸 밑줄을 없앤다.
            ),
            // 글자가 바뀔 때마다 호출. 빈 setState()로 build()를 다시 실행하며
            // 게시 버튼 활성 여부와 카운터를 새 입력 기준으로 다시 그립니다.
            onChanged: (_) => setState(() {}),
            // 입력칸 오른쪽 아래 글자 수 표시를 직접 만듭니다.
            // 기본 카운터는 300자가 돼도 색이 안 바뀌기 때문
            buildCounter:
                (
                  context, {
                  required currentLength, // 지금 글자 수
                  required isFocused, // 입력칸에 커서가 있는지
                  maxLength,
                }) {
                  return Text(
                    '$currentLength/$maxPostLength',
                    style: currentLength >= maxPostLength
                        ? TextStyle(color: Theme.of(context).colorScheme.error)
                        : null,
                  );
                },
          ),
        ),
      ),
    );
  }
}
