import 'package:flutter/material.dart';
import 'package:minifeed/ai/topic_analyzer.dart';

const _topicColors = [
  Color(0xff64748b),
  Color(0xff6366f1),
  Color(0xffea580c),
  Color(0xff16804a),
  Color(0xff9333ea),
  Color(0xff0284c7),
  Color(0xffdb2777),
  Color(0xffa16207),
];

class TopicScores extends StatelessWidget {
  const TopicScores({super.key, required this.result});

  final TopicAnalysis result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '모델 점수 · 추천 기준 ${result.threshold.toStringAsFixed(2)}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        for (final (index, score) in result.scores.indexed)
          ConstrainedBox(
            key: ValueKey(score.label),
            constraints: const BoxConstraints(minHeight: 32),
            child: Semantics(
              label: score.label,
              value: score.value.toStringAsFixed(2),
              excludeSemantics: true,
              child: Row(
                spacing: 10,
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(score.label, style: theme.textTheme.bodySmall),
                  ),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 200),
                        tween: Tween(begin: 0, end: score.value),
                        builder: (context, value, child) =>
                            LinearProgressIndicator(
                              value: value,
                              color: _topicColors[index],
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                              stopIndicatorRadius: 0,
                              trackGap: 0,
                            ),
                      ),
                    ),
                  ),
                  Text(
                    score.value.toStringAsFixed(2),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
