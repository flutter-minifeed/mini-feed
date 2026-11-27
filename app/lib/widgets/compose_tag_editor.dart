import 'package:flutter/material.dart';

import '../models/compose_tag.dart';

class ComposeTagEditor extends StatelessWidget {
  const ComposeTagEditor({
    super.key,
    required this.tags,
    required this.controller,
    required this.enabled,
    required this.error,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  });

  final List<ComposeTag> tags;
  final TextEditingController controller;
  final bool enabled;
  final String? error;
  final VoidCallback onAdd;
  final ValueChanged<ComposeTag> onRemove;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('게시할 태그', style: theme.textTheme.labelMedium),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final tag in tags)
              InputChip(
                label: Text('#${tag.name}'),
                labelStyle: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                backgroundColor: theme.colorScheme.primaryContainer,
                shape: const StadiumBorder(),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                deleteIcon: const Icon(Icons.close, size: 14),
                deleteIconBoxConstraints: const BoxConstraints.tightFor(
                  width: 24,
                ),
                deleteButtonTooltipMessage: '${tag.name} 제거',
                onDeleted: enabled ? () => onRemove(tag) : null,
                visualDensity: VisualDensity.compact,
              ),
            SizedBox(
              width: 152,
              child: TextField(
                controller: controller,
                readOnly: !enabled,
                onChanged: onChanged,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onAdd(),
                decoration: InputDecoration(
                  hintText: '#태그 입력',
                  isDense: true,
                  border: InputBorder.none,
                  suffixIcon: controller.text.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: '태그 추가',
                          onPressed: enabled ? onAdd : null,
                          icon: const Icon(Icons.add, size: 20),
                        ),
                ),
              ),
            ),
          ],
        ),
        if (error != null)
          Semantics(
            liveRegion: true,
            child: Text(
              error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

class RecommendedTagChips extends StatelessWidget {
  const RecommendedTagChips({
    super.key,
    required this.candidates,
    required this.selected,
    required this.onSelected,
  });

  final List<String> candidates;
  final List<String> selected;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final name in candidates)
          ActionChip(
            label: Text(name),
            avatar: Icon(
              selected.contains(name) ? Icons.check : Icons.add,
              size: 16,
            ),
            onPressed: onSelected == null || selected.contains(name)
                ? null
                : () => onSelected!(name),
          ),
      ],
    );
  }
}
