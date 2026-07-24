import 'package:flutter/material.dart';
import '../../../config/constants.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/models/card.dart';
import '../../../shared/utils/score_calculator.dart';
import '../../../shared/widgets/cc_buttons.dart';
import 'card_widget.dart';

enum _Phase {
  handPrompt,
  handInput,
  handResult,
  cribPrompt,
  cribInput,
  cribResult,
  done,
}

class CountingOverlay extends StatefulWidget {
  final List<PlayingCard> hand;
  final PlayingCard cutCard;
  final List<PlayingCard> crib;
  final bool isDealer;
  final VoidCallback onComplete;

  /// Skip straight to the number pad. The count-it-for-me / I'll-count choice
  /// now lives on the game screen, so by the time this panel opens the player
  /// has already said they want to count it themselves.
  final bool startAtInput;

  const CountingOverlay({
    super.key,
    required this.hand,
    required this.cutCard,
    required this.crib,
    required this.isDealer,
    required this.onComplete,
    this.startAtInput = false,
  });

  @override
  State<CountingOverlay> createState() => _CountingOverlayState();
}

class _CountingOverlayState extends State<CountingOverlay> {
  late _Phase _phase = widget.startAtInput
      ? _Phase.handInput
      : _Phase.handPrompt;
  int _guessValue = 0;
  int? _handGuess;
  int? _cribGuess;
  late final DetailedScoreBreakdown _handBreakdown;
  late final DetailedScoreBreakdown _cribBreakdown;

  @override
  void initState() {
    super.initState();
    _handBreakdown = calculateDetailedBreakdown(widget.hand, widget.cutCard);
    if (widget.isDealer && widget.crib.isNotEmpty) {
      _cribBreakdown = calculateDetailedBreakdown(
        widget.crib,
        widget.cutCard,
        isCrib: true,
      );
    } else {
      _cribBreakdown = const DetailedScoreBreakdown(
        combinations: [],
        totalScore: 0,
      );
    }
  }

  void _advance() {
    setState(() {
      switch (_phase) {
        case _Phase.handPrompt:
        case _Phase.handInput:
        case _Phase.handResult:
          if (_phase == _Phase.handResult &&
              widget.isDealer &&
              widget.crib.isNotEmpty) {
            _phase = _Phase.cribPrompt;
            _guessValue = 0;
          } else if (_phase == _Phase.handResult) {
            _phase = _Phase.done;
          }
        case _Phase.cribPrompt:
        case _Phase.cribInput:
        case _Phase.cribResult:
          if (_phase == _Phase.cribResult) {
            _phase = _Phase.done;
          }
        case _Phase.done:
          break;
      }
    });
    if (_phase == _Phase.done) {
      widget.onComplete();
    }
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
            child: SingleChildScrollView(child: _buildPhaseContent()),
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (_phase) {
      case _Phase.handPrompt:
        return _buildPrompt(
          title: 'Your hand',
          cards: widget.hand,
          cutCard: widget.cutCard,
          onCountForMe: () {
            setState(() => _phase = _Phase.handResult);
          },
          onIllCount: () {
            setState(() {
              _phase = _Phase.handInput;
              _guessValue = 0;
            });
          },
        );
      case _Phase.handInput:
        return _buildInput(
          title: 'Your hand',
          cards: widget.hand,
          cutCard: widget.cutCard,
          onSubmit: () {
            setState(() {
              _handGuess = _guessValue;
              _phase = _Phase.handResult;
            });
          },
        );
      case _Phase.handResult:
        return _buildResult(
          title: 'Your hand',
          cards: widget.hand,
          cutCard: widget.cutCard,
          breakdown: _handBreakdown,
          guess: _handGuess,
          onContinue: _advance,
          buttonLabel: widget.isDealer && widget.crib.isNotEmpty
              ? 'Count the crib'
              : 'Done',
        );
      case _Phase.cribPrompt:
        return _buildPrompt(
          title: 'Your crib',
          cards: widget.crib,
          cutCard: widget.cutCard,
          onCountForMe: () {
            setState(() => _phase = _Phase.cribResult);
          },
          onIllCount: () {
            setState(() {
              _phase = _Phase.cribInput;
              _guessValue = 0;
            });
          },
        );
      case _Phase.cribInput:
        return _buildInput(
          title: 'Your crib',
          cards: widget.crib,
          cutCard: widget.cutCard,
          onSubmit: () {
            setState(() {
              _cribGuess = _guessValue;
              _phase = _Phase.cribResult;
            });
          },
        );
      case _Phase.cribResult:
        return _buildResult(
          title: 'Your crib',
          cards: widget.crib,
          cutCard: widget.cutCard,
          breakdown: _cribBreakdown,
          guess: _cribGuess,
          onContinue: _advance,
          buttonLabel: 'Done',
        );
      case _Phase.done:
        return const SizedBox.shrink();
    }
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

  Widget _buildPrompt({
    required String title,
    required List<PlayingCard> cards,
    required PlayingCard cutCard,
    required VoidCallback onCountForMe,
    required VoidCallback onIllCount,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _header('Count', title),
        const SizedBox(height: 16),
        _buildCardRow(cards, cutCard),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: CcSecondaryButton(
                label: 'Count it for me',
                height: 44,
                fontSize: 13,
                onPressed: onCountForMe,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CcPrimaryButton(
                label: "I'll count",
                height: 44,
                fontSize: 14,
                onPressed: onIllCount,
              ),
            ),
          ],
        ),
      ],
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

  Widget _buildInput({
    required String title,
    required List<PlayingCard> cards,
    required PlayingCard cutCard,
    required VoidCallback onSubmit,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _header('How many', title),
        const SizedBox(height: 14),
        _buildCardRow(cards, cutCard),
        const SizedBox(height: 14),
        _buildNumberPad(onSubmit),
      ],
    );
  }

  Widget _buildResult({
    required String title,
    required List<PlayingCard> cards,
    required PlayingCard cutCard,
    required DetailedScoreBreakdown breakdown,
    required int? guess,
    required VoidCallback onContinue,
    required String buttonLabel,
  }) {
    final colors = context.appColors;
    final correct = guess == null || guess == breakdown.totalScore;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _header('Counted', title),
        const SizedBox(height: 14),
        _buildCardRow(cards, cutCard),
        const SizedBox(height: 16),

        // The score is the number to read here (design principle §1).
        Text(
          '${breakdown.totalScore}',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 40,
            height: 1,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (guess != null) ...[
          const SizedBox(height: 6),
          Text(
            correct ? 'You called it' : 'You said $guess',
            style: TextStyle(
              color: correct ? colors.success : colors.warning,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
        const SizedBox(height: 14),

        // What made it up, as a table: reason left, points right, tabular.
        if (breakdown.combinations.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < breakdown.combinations.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: colors.border),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              breakdown.combinations[i].description,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${breakdown.combinations[i].points}',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
            label: buttonLabel,
            height: 48,
            fontSize: 15,
            onPressed: onContinue,
          ),
        ),
      ],
    );
  }
}
