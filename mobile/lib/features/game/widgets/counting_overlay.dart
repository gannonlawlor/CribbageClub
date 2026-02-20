import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/card.dart';
import '../../../shared/utils/score_calculator.dart';
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

  const CountingOverlay({
    super.key,
    required this.hand,
    required this.cutCard,
    required this.crib,
    required this.isDealer,
    required this.onComplete,
  });

  @override
  State<CountingOverlay> createState() => _CountingOverlayState();
}

class _CountingOverlayState extends State<CountingOverlay> {
  _Phase _phase = _Phase.handPrompt;
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
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: AppTheme.feltGreenDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white24,
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: _buildPhaseContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (_phase) {
      case _Phase.handPrompt:
        return _buildPrompt(
          title: 'Count Your Hand',
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
          title: 'Your Hand',
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
          title: 'Hand Score',
          cards: widget.hand,
          cutCard: widget.cutCard,
          breakdown: _handBreakdown,
          guess: _handGuess,
          onContinue: _advance,
          buttonLabel: widget.isDealer && widget.crib.isNotEmpty
              ? 'Count Crib'
              : 'Done',
        );
      case _Phase.cribPrompt:
        return _buildPrompt(
          title: 'Count Your Crib',
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
          title: 'Your Crib',
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
          title: 'Crib Score',
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

  Widget _buildCardRow(List<PlayingCard> cards, PlayingCard cutCard) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availW = constraints.maxWidth;
        // Size cards to fit hand row (4 cards with 6px gaps)
        final gap = 6.0;
        final cardW = ((availW - (cards.length - 1) * gap) / cards.length)
            .clamp(0.0, 70.0);
        final cardH = cardW / AppTheme.cardAspectRatio;
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
                Expanded(
                  child: Container(height: 1, color: Colors.white24),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Cut',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ),
                Expanded(
                  child: Container(height: 1, color: Colors.white24),
                ),
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
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildCardRow(cards, cutCard),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onCountForMe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.feltGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Count for me'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onIllCount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldAccent,
                  foregroundColor: Colors.black87,
                ),
                child: const Text("I'll count"),
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
    Widget numButton(int digit) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Material(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _onNumberTap(digit),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                child: Text(
                  '$digit',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Display
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 8),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            '$_guessValue',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Number rows
        Row(children: [numButton(1), numButton(2), numButton(3)]),
        Row(children: [numButton(4), numButton(5), numButton(6)]),
        Row(children: [numButton(7), numButton(8), numButton(9)]),
        Row(
          children: [
            // Backspace
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Material(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _onBackspace,
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.backspace_outlined,
                        color: Colors.white70,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            numButton(0),
            // Enter
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Material(
                  color: AppTheme.goldAccent.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onSubmit,
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check,
                        color: AppTheme.goldAccent,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
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
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildCardRow(cards, cutCard),
        const SizedBox(height: 12),
        const Text(
          'How many points?',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
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
    final isCorrect = guess == null || guess == breakdown.totalScore;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildCardRow(cards, cutCard),
        const SizedBox(height: 16),
        // Guess feedback
        if (guess != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isCorrect
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCorrect
                    ? Colors.green.withValues(alpha: 0.5)
                    : Colors.amber.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              isCorrect
                  ? 'Correct! $guess points'
                  : 'You said $guess, actual is ${breakdown.totalScore}',
              style: TextStyle(
                color: isCorrect ? Colors.greenAccent : Colors.amberAccent,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Breakdown list
        if (breakdown.combinations.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                for (final combo in breakdown.combinations)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            combo.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '+${combo.points}',
                          style: const TextStyle(
                            color: AppTheme.goldAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(color: Colors.white24, height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${breakdown.totalScore}',
                      style: const TextStyle(
                        color: AppTheme.goldAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'No points — 0',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.feltGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
          ),
          child: Text(buttonLabel),
        ),
      ],
    );
  }
}
