import 'package:flutter/material.dart';

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

  // 화면이 닫힐 때 한 번 호출된다. 직접 만든 컨트롤러를 해제한다.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 게시 가능 여부. 앞뒤 공백 및 줄바꿈을 지우고 남는 글자가 있어야 한다.
  // get으로 만들어서 _canPost를 읽을 때마다 현재 입력으로 다시 계산한다.
  bool get _canPost => _controller.text.trim().isNotEmpty;

  // setState()가 호출될 때마다 다시 실행된다.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 피드에서 fullscreenDialog: true로 열어서 AppBar가 X버튼을 자동으로 만들어준다.
        title: const Text('글쓰기'),
        // 상단 바 오른쪽에 놓이는 버튼들
        actions: [
          TextButton(
            // onPressed가 null이면 Flutter가 버튼을 비활성(회색)으로 그린다.
            // 저장소 연결은 다음 커밋으로
            onPressed: _canPost ? () {} : null,
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
    );
  }
}
