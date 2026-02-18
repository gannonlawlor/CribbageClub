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
    const cardW = 52.0;
    const cardH = 72.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final card in cards) ...[
          CardWidget(
            card: card,
            faceUp: true,
            enabled: false,
            width: cardW,
            height: cardH,
          ),
          const SizedBox(width: 4),
        ],
        Container(
          width: 1,
          height: cardH * 0.7,
          color: Colors.white24,
        ),
        const SizedBox(width: 4),
        CardWidget(
          card: cutCard,
          faceUp: true,
          enabled: false,
          width: cardW,
          height: cardH,
        ),
      ],
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: onCountForMe,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.feltGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Count for me'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: onIllCount,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldAccent,
                foregroundColor: Colors.black87,
              ),
              child: const Text("I'll count"),
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
        const SizedBox(height: 16),
        _buildCardRow(cards, cutCard),
        const SizedBox(height: 20),
        const Text(
          'How many points?',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _guessValue > 0
                  ? () => setState(() => _guessValue--)
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
              color: Colors.white,
              disabledColor: Colors.white24,
              iconSize: 32,
            ),
            const SizedBox(width: 16),
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
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
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: _guessValue < 29
                  ? () => setState(() => _guessValue++)
                  : null,
              icon: const Icon(Icons.add_circle_outline),
              color: Colors.white,
              disabledColor: Colors.white24,
              iconSize: 32,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.goldAccent,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
          ),
          child: const Text('Submit'),
        ),
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
