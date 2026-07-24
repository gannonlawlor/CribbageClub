import 'package:flutter/material.dart';
import '../../../config/constants.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/models/card.dart';
import '../../../shared/utils/score_calculator.dart';
import '../../../shared/widgets/cc_buttons.dart';
import 'card_widget.dart';

/// Manual count: the player calls their own score on the number pad. The
/// breakdown only appears when they get it wrong — a correct call just closes,
/// since the engine records the score to the history either way.
///
/// Used for both the hand and (for the dealer) the crib — [isCrib] switches
/// the scoring rules and [title] the wording.
class CountingOverlay extends StatefulWidget {
  final List<PlayingCard> cards;
  final PlayingCard cutCard;
  final bool isCrib;
  final String title;
  final VoidCallback onComplete;

  const CountingOverlay({
    super.key,
    required this.cards,
    required this.cutCard,
    required this.onComplete,
    this.isCrib = false,
    this.title = 'Your hand',
  });

  @override
  State<CountingOverlay> createState() => _CountingOverlayState();
}

class _CountingOverlayState extends State<CountingOverlay> {
  int _guessValue = 0;
  int _guess = 0;
  bool _showResult = false;
  late final DetailedScoreBreakdown _breakdown;

  @override
  void initState() {
    super.initState();
    _breakdown = calculateDetailedBreakdown(
      widget.cards,
      widget.cutCard,
      isCrib: widget.isCrib,
    );
  }

  void _submit() {
    // A correct call needs no explaining — record it and get out of the way.
    if (_guessValue == _breakdown.totalScore) {
      widget.onComplete();
      return;
    }
    setState(() {
      _guess = _guessValue;
      _showResult = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // Panel shell matching the game-over panel (design language §4).
    return Positioned.fill(
      child: Container(
        color: colors.scrim,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            constraints: const BoxConstraints(maxWidth: 360),
            decoration: BoxDecoration(
              color: colors.surfacePrimary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderStrong),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 40,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: _showResult ? _buildResult() : _buildInput(),
            ),
          ),
        ),
      ),
    );
  }

  /// Caption over title, the way every panel in the app opens.
  Widget _header(String caption, String title) {
    final colors = context.appColors;
    return Column(
      children: [
        Text(
          caption.toUpperCase(),
          style: TextStyle(
            color: colors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.88,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCardRow(List<PlayingCard> cards, PlayingCard cutCard) {
    final colors = context.appColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final availW = constraints.maxWidth;
        // Size cards to fit hand row (4 cards with 6px gaps)
        final gap = 6.0;
        final cardW = ((availW - (cards.length - 1) * gap) / cards.length)
            .clamp(0.0, 70.0);
        final cardH = cardW / AppConstants.cardAspectRatio;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hand cards
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  CardWidget(
                    card: cards[i],
                    faceUp: true,
                    enabled: false,
                    width: cardW,
                    height: cardH,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // Divider + cut card
            Row(
              children: [
                Expanded(child: Container(height: 1, color: colors.divider)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Cut',
                    style: TextStyle(color: colors.textDisabled, fontSize: 11),
                  ),
                ),
                Expanded(child: Container(height: 1, color: colors.divider)),
              ],
            ),
            const SizedBox(height: 8),
            CardWidget(
              card: cutCard,
              faceUp: true,
              enabled: false,
              width: cardW,
              height: cardH,
            ),
          ],
        );
      },
    );
  }

  void _onNumberTap(int digit) {
    setState(() {
      final newValue = _guessValue * 10 + digit;
      if (newValue <= 29) {
        _guessValue = newValue;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _guessValue = _guessValue ~/ 10;
    });
  }

  Widget _buildNumberPad(VoidCallback onSubmit) {
    final colors = context.appColors;

    Widget key({
      required Widget child,
      required VoidCallback onTap,
      Color? fill,
      bool bevel = false,
    }) {
      final radius = BorderRadius.circular(8);
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: bevel
                ? BoxDecoration(
                    color: colors.accentPressed,
                    borderRadius: radius,
                  )
                : null,
            child: Padding(
              padding: EdgeInsets.only(bottom: bevel ? 3 : 0),
              child: Material(
                color: fill ?? colors.surfaceDim,
                borderRadius: radius,
                child: InkWell(
                  borderRadius: radius,
                  onTap: onTap,
                  child: Container(
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: bevel ? null : Border.all(color: colors.border),
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget digit(int n) => key(
      onTap: () => _onNumberTap(n),
      child: Text(
        '$n',
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );

    return Column(
      children: [
        // The running guess is the largest number on the panel.
        Text(
          '$_guessValue',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 40,
            height: 1.1,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [digit(1), digit(2), digit(3)]),
        Row(children: [digit(4), digit(5), digit(6)]),
        Row(children: [digit(7), digit(8), digit(9)]),
        Row(
          children: [
            key(
              onTap: _onBackspace,
              child: Icon(
                Icons.backspace_outlined,
                color: colors.textTertiary,
                size: 20,
              ),
            ),
            digit(0),
            key(
              onTap: onSubmit,
              fill: colors.accent,
              bevel: true,
              child: Icon(Icons.check, color: colors.accentOnSurface, size: 22),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _header('How many', widget.title),
        const SizedBox(height: 14),
        _buildCardRow(widget.cards, widget.cutCard),
        const SizedBox(height: 14),
        _buildNumberPad(_submit),
      ],
    );
  }

  Widget _buildResult() {
    final colors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _header('Counted', widget.title),
        const SizedBox(height: 14),
        _buildCardRow(widget.cards, widget.cutCard),
        const SizedBox(height: 16),

        // The score is the number to read here (design principle §1).
        Text(
          '${_breakdown.totalScore}',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 40,
            height: 1,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'You said $_guess',
          style: TextStyle(
            color: colors.warning,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 14),

        // What made it up, shown as the cards themselves rather than spelled
        // out — each row is a scoring group and the points it earns.
        if (_breakdown.combinations.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < _breakdown.combinations.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: colors.border),
                    _comboRow(_breakdown.combinations[i]),
                  ],
                ],
              ),
            ),
          )
        else
          Text(
            'Nothing to count',
            style: TextStyle(color: colors.textTertiary, fontSize: 13),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: CcPrimaryButton(
            label: 'Done',
            height: 48,
            fontSize: 15,
            onPressed: widget.onComplete,
          ),
        ),
      ],
    );
  }

  /// One scoring group: its cards on the left, the points it earns on the
  /// right.
  Widget _comboRow(ScoringCombination c) {
    final colors = context.appColors;
    const cardW = 30.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final card in c.cards)
                  CardWidget(
                    card: card,
                    faceUp: true,
                    enabled: false,
                    width: cardW,
                    height: cardW / AppConstants.cardAspectRatio,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '+${c.points}',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
