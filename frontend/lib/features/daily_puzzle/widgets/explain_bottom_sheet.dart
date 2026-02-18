import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/models/card.dart';
import '../../../src/rust/api/simple.dart' as rust;
import '../../game/widgets/card_widget.dart';
import '../models/keep_explanation.dart';
import '../services/insight_generator.dart';

/// Bottom sheet that computes the explain analysis on-demand with a loading spinner.
class ExplainBottomSheet extends StatefulWidget {
  final int rank;
  final List<PlayingCard> keep;
  final List<PlayingCard> discard;
  final List<dynamic> hand;
  final bool isDealer;

  const ExplainBottomSheet({
    super.key,
    required this.rank,
    required this.keep,
    required this.discard,
    required this.hand,
    required this.isDealer,
  });

  @override
  State<ExplainBottomSheet> createState() => _ExplainBottomSheetState();
}

class _ExplainBottomSheetState extends State<ExplainBottomSheet> {
  KeepExplanation? _explanation;
  List<String>? _insights;

  @override
  void initState() {
    super.initState();
    // Compute explanation after the first frame (shows loading immediately)
    Future(_computeExplanation);
  }

  void _computeExplanation() {
    final handJson = jsonEncode(widget.hand.map((c) => c.toJson()).toList());
    final keepJson = jsonEncode(widget.keep.map((c) => c.toJson()).toList());
    final resultJson = rust.explainKeepJson(
      handJson: handJson,
      keepJson: keepJson,
      isDealer: widget.isDealer,
    );
    final explanation = KeepExplanation.fromJson(
      jsonDecode(resultJson) as Map<String, dynamic>,
    );
    final insights = InsightGenerator.generateInsights(
      explanation,
      widget.keep,
      widget.discard,
    );
    if (mounted) {
      setState(() {
        _explanation = explanation;
        _insights = insights;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1B3A1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Row(
            children: [
              Text(
                'Why #${widget.rank}?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              ...widget.keep.map(
                (card) => Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: CardWidget(
                    card: card,
                    width: 32,
                    height: 45,
                    enabled: false,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Loading or content
          if (_explanation == null || _insights == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white54),
              ),
            )
          else ...[
            // Insights
            for (final insight in _insights!)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '\u2022 ',
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                    Expanded(
                      child: Text(
                        insight,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            // Score summary
            _ScoreSummary(explanation: _explanation!),
            // Cut score distribution
            const SizedBox(height: 12),
            _CutDistribution(cutScores: _explanation!.cutScores),
          ],
        ],
      ),
    );
  }
}

class _ScoreSummary extends StatelessWidget {
  final KeepExplanation explanation;

  const _ScoreSummary({required this.explanation});

  @override
  Widget build(BuildContext context) {
    final netScore = explanation.isDealer
        ? explanation.averageHandScore + explanation.averageCribScore
        : explanation.averageHandScore - explanation.averageCribScore;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ScoreStat(
            label: 'Hand avg',
            value: explanation.averageHandScore.toStringAsFixed(1),
          ),
          _ScoreStat(
            label: 'Crib avg',
            value:
                '${explanation.isDealer ? '+' : '\u2212'}${explanation.averageCribScore.toStringAsFixed(1)}',
          ),
          _ScoreStat(
            label: 'Net',
            value: netScore.toStringAsFixed(1),
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _ScoreStat extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _ScoreStat({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: bold ? 18 : 16,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }
}

class _CutDistribution extends StatelessWidget {
  final List<CutScore> cutScores;

  const _CutDistribution({required this.cutScores});

  @override
  Widget build(BuildContext context) {
    if (cutScores.isEmpty) return const SizedBox.shrink();

    // Build distribution: score -> count
    final dist = <int, int>{};
    for (final cs in cutScores) {
      dist[cs.totalScore] = (dist[cs.totalScore] ?? 0) + 1;
    }

    final maxScore = cutScores.first.totalScore;
    final minScore = cutScores.last.totalScore;
    final maxCount = dist.values.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Score distribution by cut',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 60,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var score = minScore; score <= maxScore; score++)
                if (dist.containsKey(score))
                  Expanded(
                    child: Tooltip(
                      message: '$score pts: ${dist[score]} cuts',
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                        height: 60 * (dist[score]! / maxCount),
                        decoration: BoxDecoration(
                          color: _barColor(score),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      height: 1,
                      color: Colors.white10,
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$minScore',
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
            Text(
              '$maxScore pts',
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  Color _barColor(int score) {
    if (score >= 12) return Colors.greenAccent;
    if (score >= 8) return Colors.green;
    if (score >= 4) return Colors.amber;
    return Colors.white38;
  }
}
