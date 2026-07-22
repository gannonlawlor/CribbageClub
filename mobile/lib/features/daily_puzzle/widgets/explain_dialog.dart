import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/models/card.dart';
import '../../../shared/widgets/cc_dialog.dart';
import '../../../src/rust/api/simple.dart' as rust;
import '../../game/widgets/card_widget.dart';
import '../models/keep_explanation.dart';
import '../services/insight_generator.dart';

/// Explains the reasoning behind a keep's rating. Computes the analysis
/// on-demand (Rust FFI) and renders it inside the app-standard [CcDialog].
///
/// The header's "?" flips the dialog over (design language "Starter cut"
/// motion: 240ms rotateY, ease-out) to a glossary side that explains the
/// numbers in plain language.
class ExplainDialog extends StatefulWidget {
  final int rank;
  final List<PlayingCard> keep;
  final List<PlayingCard> discard;
  final List<dynamic> hand;
  final bool isDealer;

  const ExplainDialog({
    super.key,
    required this.rank,
    required this.keep,
    required this.discard,
    required this.hand,
    required this.isDealer,
  });

  @override
  State<ExplainDialog> createState() => _ExplainDialogState();
}

class _ExplainDialogState extends State<ExplainDialog> {
  final GlobalKey _frontCardKey = GlobalKey();
  KeepExplanation? _explanation;
  List<String>? _insights;
  bool _showHelp = false;
  double? _cardHeight;

  @override
  void initState() {
    super.initState();
    // Compute after the first frame so the dialog shows immediately.
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

  void _toggleHelp() {
    // Fix the glossary side to the analysis side's rendered height so the
    // card keeps one size through the flip; the glossary scrolls inside it.
    if (!_showHelp) {
      final box = _frontCardKey.currentContext?.findRenderObject();
      if (box is RenderBox && box.hasSize) {
        _cardHeight = box.size.height;
      }
    }
    setState(() => _showHelp = !_showHelp);
  }

  @override
  Widget build(BuildContext context) {
    final front = CcDialog(
      cardKey: _frontCardKey,
      title: 'Why #${widget.rank}?',
      headerActions: [
        _HelpButton(active: false, onTap: _toggleHelp),
      ],
      child: _FrontContent(
        keep: widget.keep,
        discard: widget.discard,
        explanation: _explanation,
        insights: _insights,
      ),
    );

    final back = CcDialog(
      height: _cardHeight,
      title: 'Reading the numbers',
      headerActions: [
        _HelpButton(active: true, onTap: _toggleHelp),
      ],
      child: _HelpContent(
        rank: widget.rank,
        isDealer: widget.isDealer,
        explanation: _explanation,
      ),
    );

    return _FlipTransition(showBack: _showHelp, front: front, back: back);
  }
}

/// 3D card flip between two children (design language "Starter cut" motion:
/// 240ms, ease-out, rotateY). The visible side swaps at 90° — edge-on, so the
/// size difference between sides is imperceptible.
class _FlipTransition extends StatelessWidget {
  final bool showBack;
  final Widget front;
  final Widget back;

  const _FlipTransition({
    required this.showBack,
    required this.front,
    required this.back,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: showBack ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 240),
      curve: const Cubic(0.2, 0, 0, 1), // --ease-out
      builder: (context, t, _) {
        // At rest, render the side untransformed — a π-rotated perspective
        // matrix distorts hit-testing for scroll/tap gestures.
        if (t == 0.0) return front;
        if (t == 1.0) return back;

        final angle = t * math.pi;
        final isBack = angle > math.pi / 2;
        // Pre-rotate the back side so it reads normally once flipped.
        final side = isBack
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(math.pi),
                child: back,
              )
            : front;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015) // perspective
            ..rotateY(angle),
          child: side,
        );
      },
    );
  }
}

/// Circular "?" header button. [active] marks the glossary side, where
/// tapping it flips back.
class _HelpButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _HelpButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = active ? colors.accent : colors.textTertiary;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? colors.accent : colors.borderStrong,
                width: 1.5,
              ),
            ),
            child: Text(
              '?',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Front: the analysis ─────────────────────────────────────

class _FrontContent extends StatelessWidget {
  final List<PlayingCard> keep;
  final List<PlayingCard> discard;
  final KeepExplanation? explanation;
  final List<String>? insights;

  const _FrontContent({
    required this.keep,
    required this.discard,
    required this.explanation,
    required this.insights,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final loading = explanation == null || insights == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Keep + dimmed discard on one row
        Row(
          children: [
            for (final card in keep)
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: CardWidget(
                  card: card,
                  width: 30,
                  height: 42,
                  enabled: false,
                ),
              ),
            const SizedBox(width: 8),
            Opacity(
              opacity: 0.4,
              child: Row(
                children: [
                  for (final card in discard)
                    Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: CardWidget(
                        card: card,
                        width: 30,
                        height: 42,
                        enabled: false,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (loading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.textDisabled,
                ),
              ),
            ),
          )
        else ...[
          for (final insight in insights!)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 7, right: 9),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                    ),
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
          const SizedBox(height: 6),
          _StatPanel(
            stats: [
              (
                'Hand avg',
                explanation!.averageHandScore.toStringAsFixed(1),
                false,
              ),
              (
                'Crib avg',
                '${explanation!.isDealer ? '+' : '−'}${explanation!.averageCribScore.toStringAsFixed(1)}',
                false,
              ),
              (
                'Net',
                (explanation!.isDealer
                        ? explanation!.averageHandScore +
                            explanation!.averageCribScore
                        : explanation!.averageHandScore -
                            explanation!.averageCribScore)
                    .toStringAsFixed(1),
                true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CutScoreTable(cutScores: explanation!.cutScores),
        ],
      ],
    );
  }
}

class _StatPanel extends StatelessWidget {
  final List<(String, String, bool)> stats;

  const _StatPanel({required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceDim,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final (label, value, emphasize) in stats)
            _ScoreStat(label: label, value: value, emphasize: emphasize),
        ],
      ),
    );
  }
}

class _ScoreStat extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _ScoreStat({
    required this.label,
    required this.value,
    this.emphasize = false,
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
            fontSize: emphasize ? 18 : 16,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: colors.textTertiary,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
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
          'SCORE BY CUT CARD',
          style: TextStyle(
            color: colors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.66,
          ),
        ),
        const SizedBox(height: 8),
        _StatPanel(
          stats: [
            ('Min', '$minScore', false),
            ('Avg', avgScore.toStringAsFixed(1), true),
            ('Max', '$maxScore', false),
          ],
        ),
        const SizedBox(height: 10),
        if (great > 0)
          _CutBucket(label: '12+', count: great, total: total, color: colors.evOptimal),
        if (good > 0)
          _CutBucket(label: '8-11', count: good, total: total, color: colors.evGood),
        if (mid > 0)
          _CutBucket(label: '4-7', count: mid, total: total, color: colors.warning),
        if (low > 0)
          _CutBucket(label: '1-3', count: low, total: total, color: colors.textSecondary),
        if (zeroCount > 0)
          _CutBucket(label: '0', count: zeroCount, total: total, color: colors.textDisabled),
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
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
                    Container(color: colors.boardHole),
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
            width: 62,
            child: Text(
              '$count · $pct%',
              maxLines: 1,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: 11,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Back: the glossary ──────────────────────────────────────

class _HelpContent extends StatelessWidget {
  final int rank;
  final bool isDealer;
  final KeepExplanation? explanation;

  const _HelpContent({
    required this.rank,
    required this.isDealer,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    final e = explanation;
    final hand = e?.averageHandScore.toStringAsFixed(1);
    final crib = e?.averageCribScore.toStringAsFixed(1);
    final net = e == null
        ? null
        : (isDealer
                ? e.averageHandScore + e.averageCribScore
                : e.averageHandScore - e.averageCribScore)
            .toStringAsFixed(1);

    String? cutExample;
    if (e != null && e.cutScores.isNotEmpty) {
      final scores = e.cutScores.map((cs) => cs.totalScore).toList();
      final min = scores.reduce((a, b) => a < b ? a : b);
      final max = scores.reduce((a, b) => a > b ? a : b);
      cutExample = 'Here: the worst cut leaves you $min, the best gives $max.';
    }

    final guaranteed = e?.guaranteedPoints.total;

    final cribBody = isDealer
        ? 'Points your two discards add to the crib. The crib is yours this '
            'hand, so this is added to your total (+).'
        : 'Points your two discards give away to the crib. The crib is your '
            'opponent\'s this hand, so this counts against you (−).';
    final cribExample = e == null
        ? null
        : isDealer
            ? 'Here: +$crib — your discards feed your own crib about '
                '$crib points.'
            : 'Here: −$crib — your discards hand the opponent about '
                '$crib points per hand.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _HelpEntry(
          term: 'The ranking',
          body: 'All 15 ways to keep 4 of your 6 cards, ordered by expected '
              'points. #1 is the strongest keep on average.',
          example: 'This keep ranks #$rank of 15.',
        ),
        _HelpEntry(
          term: 'Hand avg',
          body: 'Points your kept cards score at the show, averaged across '
              'all 46 possible cut cards.',
          example: e == null
              ? null
              : 'Here: $hand — over many hands this keep scores about '
                  '$hand points.',
        ),
        _HelpEntry(term: 'Crib avg', body: cribBody, example: cribExample),
        _HelpEntry(
          term: 'Net',
          body: 'Hand average ${isDealer ? 'plus' : 'minus'} the crib '
              'average — what the keep is really worth. Keeps are ranked '
              'by this number.',
          example: e == null
              ? null
              : 'Here: $hand ${isDealer ? '+' : '−'} $crib = $net points '
                  'per hand.',
        ),
        _HelpEntry(
          term: 'Guaranteed',
          body: 'Points already in your kept cards that score no matter '
              'which card is cut — fifteens, pairs, and runs you hold now.',
          example: guaranteed == null
              ? null
              : guaranteed > 0
                  ? 'This keep banks $guaranteed '
                      'point${guaranteed == 1 ? '' : 's'} before the cut.'
                  : 'This keep has no points until the cut.',
        ),
        _HelpEntry(
          term: 'Score by cut card',
          body: 'How your hand score lands across the 46 possible cuts: the '
              'worst case, the average, the best case, and how many cuts '
              'fall in each range.',
          example: cutExample,
          last: true,
        ),
      ],
    );
  }
}

class _HelpEntry extends StatelessWidget {
  final String term;
  final String body;
  final String? example;
  final bool last;

  const _HelpEntry({
    required this.term,
    required this.body,
    this.example,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            term.toUpperCase(),
            style: TextStyle(
              color: colors.accent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.66,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            body,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          if (example != null)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: colors.accentBorder, width: 2),
                ),
              ),
              child: Text(
                example!,
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 12.5,
                  height: 1.35,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
