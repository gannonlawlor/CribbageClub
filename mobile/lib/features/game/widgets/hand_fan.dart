import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/constants.dart';
import '../../../core/models/card.dart';
import '../../../core/services/settings_provider.dart';
import '../../../shared/utils/card_dimensions.dart';
import '../../../shared/utils/card_utils.dart';
import 'card_widget.dart';

class HandFan extends ConsumerStatefulWidget {
  /// Design target for a hand card; shrinks only when the hand won't fit.
  static const double maxCardWidth = 74;
  static const double maxCardHeight = 104;

  /// Lift room reserved above the cards for the selected-card raise.
  static const double liftRoom = 8;

  /// Half a deal beat: the player's cards land every two of these, with the
  /// opponent's cards filling the off-beats so the deal alternates.
  static const Duration dealHalfBeat = Duration(milliseconds: 150);

  /// How far above the hand a dealt card starts — it drops in from the table.
  static const double dealEntryLift = 130;

  final List<PlayingCard> cards;
  final Set<int> selectedIndices;

  /// Cards that can't legally be played right now — rendered at 45% opacity.
  final Set<int> dimmedIndices;
  final bool enabled;

  /// The non-dealer is dealt to first; the dealer's cards arrive on the
  /// off-beat.
  final bool receiveFirst;

  /// Whether cards appearing in an empty hand should deal in. Off for the
  /// count, where the hand you already played is just being shown again —
  /// re-dealing it reads as a fresh hand.
  final bool animateDeal;
  final void Function(int index)? onCardTap;

  const HandFan({
    super.key,
    required this.cards,
    this.selectedIndices = const {},
    this.dimmedIndices = const {},
    this.enabled = true,
    this.receiveFirst = true,
    this.animateDeal = true,
    this.onCardTap,
  });

  @override
  ConsumerState<HandFan> createState() => _HandFanState();
}

class _HandFanState extends ConsumerState<HandFan> {
  bool _seenEmpty = false;
  int _revealedCount = 0;
  bool _faceUp = false;
  bool _isAnimating = false;
  final List<Timer> _dealTimers = [];

  @override
  void initState() {
    super.initState();
    _seenEmpty = true;
    if (widget.cards.isNotEmpty && widget.animateDeal) {
      // Cards already present on first build (e.g. first hand of new game).
      // Schedule animation for next frame so layout is ready.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startDealAnimation();
      });
    }
  }

  @override
  void didUpdateWidget(HandFan oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cards.isNotEmpty && widget.cards.isEmpty) {
      _seenEmpty = true;
    }
    if (_seenEmpty &&
        oldWidget.cards.isEmpty &&
        widget.cards.isNotEmpty &&
        widget.animateDeal) {
      _startDealAnimation();
    }
  }

  void _startDealAnimation() {
    for (final t in _dealTimers) {
      t.cancel();
    }
    _dealTimers.clear();
    final settings = ref.read(settingsProvider);
    final halfBeatMs = settings
        .scaleDuration(HandFan.dealHalfBeat)
        .inMilliseconds;
    final flipDelayMs = settings
        .scaleDuration(const Duration(milliseconds: 100))
        .inMilliseconds;
    final flipStaggerMs = settings
        .scaleDuration(const Duration(milliseconds: 80))
        .inMilliseconds;

    setState(() {
      _isAnimating = true;
      _revealedCount = 0;
      _faceUp = false;
      _seenEmpty = false;
    });

    // Cards arrive one at a time on every other half-beat; the opponent's
    // cards are dealt on the beats in between, so the deal alternates the way
    // a real one does. The dealer's own cards start on the off-beat.
    final totalCards = widget.cards.length;
    final phaseMs = widget.receiveFirst ? 0 : halfBeatMs;
    for (int i = 0; i < totalCards; i++) {
      _dealTimers.add(
        Timer(Duration(milliseconds: phaseMs + i * 2 * halfBeatMs), () {
          if (!mounted) return;
          setState(() => _revealedCount = i + 1);
          if (i == totalCards - 1) {
            // After all cards positioned, flip them face-up
            Future.delayed(Duration(milliseconds: flipDelayMs + 300), () {
              if (!mounted) return;
              setState(() => _faceUp = true);
              // After flip completes, end animation
              final totalFlipMs = flipStaggerMs * (totalCards - 1) + 400;
              Future.delayed(Duration(milliseconds: totalFlipMs), () {
                if (!mounted) return;
                setState(() => _isAnimating = false);
              });
            });
          }
        }),
      );
    }
  }

  @override
  void dispose() {
    for (final t in _dealTimers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sorted = CardUtils.sorted(widget.cards);
    final settings = ref.watch(settingsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final n = sorted.length;
        final cardW = math.min(HandFan.maxCardWidth, available * 0.28);
        final cardH = cardW / AppConstants.cardAspectRatio;
        final slotH = cardH + HandFan.liftRoom;

        if (n == 0) {
          return SizedBox(height: slotH);
        }

        // 10px gaps at the design size; the hand tightens into an overlap
        // only once six cards no longer fit.
        final step = n > 1
            ? math
                  .min(cardW + 10, (available - cardW) / (n - 1))
                  .clamp(cardW * 0.45, cardW + 10)
            : 0.0;
        final stackWidth = cardW + (n - 1) * step;
        final startX = (available - stackWidth) / 2;
        final centerX = (available - cardW) / 2;
        // Once the cards tuck under each other the far-corner pip is only
        // half visible, so the index carries the card on its own.
        final overlapping = n > 1 && step < cardW;

        if (_isAnimating) {
          final flipStagger = settings.scaleDuration(
            const Duration(milliseconds: 80),
          );
          return SizedBox(
            height: slotH,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (int i = 0; i < n; i++)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    left: i < _revealedCount ? startX + i * step : centerX,
                    // Undealt cards wait above the hand, up on the table, and
                    // drop into their slot when their turn comes.
                    bottom: i < _revealedCount ? 0 : HandFan.dealEntryLift,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: i < _revealedCount ? 1.0 : 0.0,
                      child: FlippableCardWidget(
                        card: sorted[i],
                        faceUp: _faceUp,
                        delay: flipStagger * i,
                        width: cardW,
                        height: cardH,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        // Normal (non-animating) render
        return SizedBox(
          height: slotH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < n; i++)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  left: startX + i * step,
                  bottom: 0,
                  child: CardWidget(
                    card: sorted[i],
                    faceUp: true,
                    selected: widget.selectedIndices.contains(i),
                    dimmed: widget.dimmedIndices.contains(i),
                    indexOnly: overlapping && i < n - 1,
                    enabled: widget.enabled,
                    onTap: widget.onCardTap != null
                        ? () => widget.onCardTap!(i)
                        : null,
                    width: cardW,
                    height: cardH,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class OpponentHand extends StatefulWidget {
  final int cardCount;

  /// Mirrors [HandFan.receiveFirst]: the non-dealer's cards land on the
  /// on-beats, the dealer's on the off-beats.
  final bool receiveFirst;

  /// Card width. Defaults to the responsive small-card size; the portrait
  /// layout passes its own so the row mirrors the player's hand.
  final double? cardWidth;

  /// Lay the cards out the way [HandFan] does — 10pt gaps that tighten into an
  /// overlap only when the hand won't fit — instead of a tight fixed stack.
  final bool fanned;

  /// Held before each card is revealed, so a deal flight arriving from the
  /// table can land first and hand the card over rather than double-drawing it.
  final Duration dealDelay;

  const OpponentHand({
    super.key,
    required this.cardCount,
    this.receiveFirst = false,
    this.cardWidth,
    this.fanned = false,
    this.dealDelay = Duration.zero,
  });

  @override
  State<OpponentHand> createState() => _OpponentHandState();
}

class _OpponentHandState extends State<OpponentHand> {
  bool _seenEmpty = false;
  int _revealedCount = 0;
  bool _isAnimating = false;
  final List<Timer> _dealTimers = [];

  @override
  void initState() {
    super.initState();
    _seenEmpty = true;
    if (widget.cardCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startDealAnimation();
      });
    }
  }

  @override
  void didUpdateWidget(OpponentHand oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cardCount > 0 && widget.cardCount <= 0) {
      _seenEmpty = true;
    }
    if (_seenEmpty && oldWidget.cardCount <= 0 && widget.cardCount > 0) {
      _startDealAnimation();
    }
  }

  void _startDealAnimation() {
    for (final t in _dealTimers) {
      t.cancel();
    }
    _dealTimers.clear();
    // Use initial settings since this isn't a ConsumerWidget
    final settings = getInitialSettings() ?? const SettingsState();
    final halfBeatMs = settings
        .scaleDuration(HandFan.dealHalfBeat)
        .inMilliseconds;

    setState(() {
      _isAnimating = true;
      _revealedCount = 0;
      _seenEmpty = false;
    });

    // Interleaved with the player's cards: one arrives every other half-beat.
    final totalCards = widget.cardCount;
    final phaseMs =
        (widget.receiveFirst ? 0 : halfBeatMs) +
        widget.dealDelay.inMilliseconds;
    for (int i = 0; i < totalCards; i++) {
      _dealTimers.add(
        Timer(Duration(milliseconds: phaseMs + i * 2 * halfBeatMs), () {
          if (!mounted) return;
          setState(() => _revealedCount = i + 1);
          if (i == totalCards - 1) {
            // Short delay after last card slides in, then end animation
            Future.delayed(const Duration(milliseconds: 350), () {
              if (!mounted) return;
              setState(() => _isAnimating = false);
            });
          }
        }),
      );
    }
  }

  @override
  void dispose() {
    for (final t in _dealTimers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dims = CardDimensions(constraints.maxWidth);
        final cardW = widget.cardWidth ?? dims.smallCardWidth;
        final cardH = cardW / AppConstants.cardAspectRatio;
        final n = widget.cardCount;
        // Fanned: the same rule the player's hand follows, so the two hands
        // read as a matched pair across the table.
        final visible = widget.fanned && n > 1
            ? math
                  .min(cardW + 10, (constraints.maxWidth - cardW) / (n - 1))
                  .clamp(cardW * 0.45, cardW + 10)
            : cardW * (1 - dims.opponentOverlap);

        if (n <= 0) {
          return SizedBox(height: cardH);
        }

        final stackWidth = cardW + (n - 1) * visible;
        final startX = (constraints.maxWidth - stackWidth) / 2;
        final centerX = (constraints.maxWidth - cardW) / 2;

        if (_isAnimating) {
          return SizedBox(
            height: cardH,
            child: Stack(
              children: [
                for (int i = 0; i < widget.cardCount; i++)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    left: i < _revealedCount ? startX + i * visible : centerX,
                    top: 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: i < _revealedCount ? 1.0 : 0.0,
                      child: CardWidget(
                        faceUp: false,
                        width: cardW,
                        height: cardH,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        // Normal (non-animating) render
        return SizedBox(
          height: cardH,
          child: Stack(
            children: [
              for (int i = 0; i < widget.cardCount; i++)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  left: startX + i * visible,
                  top: 0,
                  child: CardWidget(faceUp: false, width: cardW, height: cardH),
                ),
            ],
          ),
        );
      },
    );
  }
}
