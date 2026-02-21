import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
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
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                color: colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Row(
            children: [
              Text(
                'Why #${widget.rank}?',
                style: TextStyle(
                  color: colors.textPrimary,
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: colors.textDisabled),
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
                    Text(
                      '\u2022 ',
                      style: TextStyle(color: colors.textSecondary, fontSize: 15),
                    ),
                    Expanded(
                      child: Text(
                        insight,
                        style: TextStyle(
                          color: colors.textSecondary,
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
            // Cut score table
            const SizedBox(height: 12),
            _CutScoreTable(cutScores: _explanation!.cutScores),
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
    final colors = context.appColors;
    final netScore = explanation.isDealer
        ? explanation.averageHandScore + explanation.averageCribScore
        : explanation.averageHandScore - explanation.averageCribScore;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceDim,
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
    final colors = context.appColors;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: bold ? 18 : 16,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: colors.textDisabled, fontSize: 11),
        ),
      ],
    );
  }
}

class _CutScoreTable extends StatelessWidget {
  final List<CutScore> cutScores;

  const _CutScoreTable({required this.cutScores});

  @override
  Widget build(BuildContext context) {
    if (cutScores.isEmpty) return const SizedBox.shrink();

    final scores = cutScores.map((cs) => cs.totalScore).toList();
    final minScore = scores.reduce((a, b) => a < b ? a : b);
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final avgScore = scores.reduce((a, b) => a + b) / scores.length;

    final total = cutScores.length;
    final zeroCount = scores.where((s) => s == 0).length;
    final low = scores.where((s) => s >= 1 && s <= 3).length;
    final mid = scores.where((s) => s >= 4 && s <= 7).length;
    final good = scores.where((s) => s >= 8 && s <= 11).length;
    final great = scores.where((s) => s >= 12).length;

    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Score by cut card',
          style: TextStyle(color: colors.textTertiary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        // Min / Avg / Max row
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceDim,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ScoreStat(label: 'Min', value: '$minScore'),
              _ScoreStat(label: 'Avg', value: avgScore.toStringAsFixed(1), bold: true),
              _ScoreStat(label: 'Max', value: '$maxScore'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Bucket bars
        if (great > 0) _CutBucket(label: '12+ pts', count: great, total: total, color: Colors.greenAccent),
        if (good > 0) _CutBucket(label: '8-11 pts', count: good, total: total, color: Colors.green),
        if (mid > 0) _CutBucket(label: '4-7 pts', count: mid, total: total, color: Colors.amber),
        if (low > 0) _CutBucket(label: '1-3 pts', count: low, total: total, color: colors.textSecondary),
        if (zeroCount > 0) _CutBucket(label: '0 pts', count: zeroCount, total: total, color: colors.textDisabled),
      ],
    );
  }
}

class _CutBucket extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _CutBucket({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final pct = (count / total * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: TextStyle(color: color, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Stack(
                  children: [
                    Container(color: colors.surfaceDim),
                    FractionallySizedBox(
                      widthFactor: count / total,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(
              '$count cut${count != 1 ? 's' : ''} ($pct%)',
              textAlign: TextAlign.right,
              style: TextStyle(color: colors.textTertiary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
