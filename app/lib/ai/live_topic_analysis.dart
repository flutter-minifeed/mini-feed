import 'package:flutter/material.dart';
import 'package:minifeed/ai/topic_analysis_controller.dart';
import 'package:minifeed/ai/topic_analyzer.dart';
import 'package:minifeed/ai/topic_scores.dart';
import 'package:minifeed/widgets/compose_tag_editor.dart';

class LiveTopicAnalysis extends StatefulWidget {
  const LiveTopicAnalysis({
    super.key,
    required this.input,
    required this.keyboardVisible,
    required this.selected,
    required this.onSelected,
    required this.loadAnalyzer,
  });

  /// #64는 이 인자에 본문과 확정된 직접 입력 태그를 조합한다.
  /// 추천에서 선택한 태그는 입력을 바꾸지 않는다.
  final String input;
  final bool keyboardVisible;
  final List<String> selected;
  final ValueChanged<String>? onSelected;
  final Future<TopicAnalyzer> Function() loadAnalyzer;

  @override
  State<LiveTopicAnalysis> createState() => _LiveTopicAnalysisState();
}

class _LiveTopicAnalysisState extends State<LiveTopicAnalysis> {
  late final _analysis = TopicAnalysisController(
    loadAnalyzer: widget.loadAnalyzer,
  );
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _syncInput();
    _analysis.addListener(_refresh);
  }

  @override
  void didUpdateWidget(LiveTopicAnalysis oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncInput();
  }

  void _syncInput() => _analysis.updateInput(
    widget.input,
    keyboardVisible: widget.keyboardVisible,
  );

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _analysis.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _analysis.result;
    final showCard =
        !widget.keyboardVisible && _analysis.status != TopicAnalysisStatus.idle;
    final theme = Theme.of(context);
    final message = switch (_analysis.status) {
      TopicAnalysisStatus.idle => '',
      TopicAnalysisStatus.analyzing => '주제를 분석하고 있어요.',
      TopicAnalysisStatus.failed => '주제를 분석하지 못했어요.',
      TopicAnalysisStatus.timedOut => '분석 시간이 초과됐어요.',
      TopicAnalysisStatus.ready when result!.candidates.isEmpty =>
        '추천할 태그가 없어요.',
      TopicAnalysisStatus.ready => '이런 주제의 글 같아요',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showCard)
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Semantics(
                    liveRegion: true,
                    child: Text(message, style: theme.textTheme.bodyMedium),
                  ),
                  if (result != null && result.candidates.isNotEmpty) ...[
                    RecommendedTagChips(
                      candidates: result.candidates,
                      selected: widget.selected,
                      onSelected: widget.onSelected,
                    ),
                    Text(
                      '선택한 태그만 게시글에 추가돼요',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                  if (result != null)
                    TextButton(
                      onPressed: () => setState(() => _expanded = !_expanded),
                      child: Text(_expanded ? '주제 점수 접기' : '주제 점수 펼치기'),
                    ),
                ],
              ),
            ),
          ),
        // 숨겨진 막대도 유지해 같은 값으로 다시 애니메이션하지 않는다.
        if (_analysis.lastResult case final previous?)
          Visibility(
            visible: showCard && result != null && _expanded,
            maintainState: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TopicScores(result: previous),
            ),
          ),
      ],
    );
  }
}
