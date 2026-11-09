import 'package:flutter/material.dart';

/// 상세 화면 맨 아래 댓글 입력줄. Figma CommentInput과 이름을 맞춘다(R10).
///
/// 입력이 비었거나 공백뿐이면(D4), 또는 200자를 넘으면 전송 버튼을 끈다.
/// 입력 내용과 포커스는 상세 화면이 가진다. 댓글 아이콘으로 열 때 포커스를 주고,
/// 등록이 끝난 뒤 입력을 지우는 것도 상세 화면이 정하기 때문이다.
class CommentInput extends StatelessWidget {
  const CommentInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  /// 댓글 최대 글자 수. Figma 안내 문구의 "(200자)"와 같다.
  static const maxLength = 200;

  final TextEditingController controller;
  final FocusNode focusNode;

  /// 전송 버튼을 누르면 앞뒤 공백을 지운 댓글 내용을 넘긴다.
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 64,
      padding: const EdgeInsets.only(left: 16, right: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLength: maxLength,
              // Figma에 글자 수 표시가 없어서 카운터를 숨긴다.
              buildCounter: (
                _, {
                required currentLength,
                required isFocused,
                required maxLength,
              }) => null,
              style: textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: '댓글 달기… (200자)',
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                filled: true,
                fillColor: colors.surfaceContainerHigh,
                isDense: true,
                // 글자 높이 20 + 위아래 12 = Figma 입력칸 높이 44
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 입력이 바뀔 때마다 전송 버튼만 다시 그린다.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final body = value.text.trim();
              // iOS·웹은 한글 조합이 끝날 때까지 maxLength를 넘는 입력을 허용하므로
              // 보낼 내용의 글자 수를 다시 확인한다.
              final canSend =
                  body.isNotEmpty && body.characters.length <= maxLength;
              return IconButton(
                icon: const Icon(Icons.send),
                color: colors.primary,
                tooltip: '댓글 보내기',
                // null이면 버튼이 꺼지고 Figma의 disabledContent(38% 회색)가 된다.
                onPressed: canSend ? () => onSend(body) : null,
              );
            },
          ),
        ],
      ),
    );
  }
}
