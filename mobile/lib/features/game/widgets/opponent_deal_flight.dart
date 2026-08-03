import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/constants.dart';
import '../../../core/services/settings_provider.dart';
import 'card_widget.dart';
import 'hand_fan.dart';

/// The opponent's half of the deal in the portrait layout: card backs fly one
/// at a time from the table up to their hand, on the beats between the
/// player's own cards, each fading out as the card it delivers appears there.
///
/// Triggered the same way [HandFan]'s deal is — by the player's hand going
/// from empty to a fresh six — so the two halves of the deal always run off
/// the same clock.
class OpponentDealFlight extends ConsumerStatefulWidget {
  /// How long a single card takes to cross the table. The opponent's hand
  /// holds each card back by this much so the two never draw the same card.
  static const Duration flightDuration = Duration(milliseconds: 340);

  /// The player's hand size; the 0 → 6 transition is the deal signal.
  final int handCount;

  /// Cards the opponent is dealt.
  final int cardCount;

  /// True when the opponent is the non-dealer and gets the first card.
  final bool receiveFirst;

  /// Flight endpoints in this widget's own coordinate space (it should be
  /// Positioned.fill over the game screen's stack).
  final Offset from;
  final Offset to;
  final double cardWidth;

  const OpponentDealFlight({
    super.key,
    required this.handCount,
    required this.receiveFirst,
    required this.from,
    required this.to,
    required this.cardWidth,
    this.cardCount = 6,
  });

  @override
  ConsumerState<OpponentDealFlight> createState() => _OpponentDealFlightState();
}

class _OpponentDealFlightState extends ConsumerState<OpponentDealFlight> {
  bool _seenEmpty = false;
  int _launched = 0;
  final Set<int> _landed = {};
  final List<Timer> _dealTimers = [];

  @override
  void initState() {
    super.initState();
    _seenEmpty = true;
    if (widget.handCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startDealAnimation();
      });
    }
  }

  @override
  void didUpdateWidget(OpponentDealFlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.handCount > 0 && widget.handCount <= 0) {
      _seenEmpty = true;
    }
    if (_seenEmpty && oldWidget.handCount <= 0 && widget.handCount > 0) {
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

    setState(() {
      _seenEmpty = false;
      _launched = 0;
      _landed.clear();
    });

    final phaseMs = widget.receiveFirst ? 0 : halfBeatMs;
    for (int i = 0; i < widget.cardCount; i++) {
      _dealTimers.add(
        Timer(Duration(milliseconds: phaseMs + i * 2 * halfBeatMs), () {
          if (mounted) setState(() => _launched = i + 1);
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
    final inFlight = [
      for (int i = 0; i < _launched; i++)
        if (!_landed.contains(i)) i,
    ];
    if (inFlight.isEmpty) return const SizedBox.shrink();

    final cardW = widget.cardWidth;
    final cardH = cardW / AppConstants.cardAspectRatio;

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final i in inFlight)
            TweenAnimationBuilder<double>(
              key: ValueKey('deal_flight_$i'),
              tween: Tween(begin: 0, end: 1),
              duration: OpponentDealFlight.flightDuration,
              curve: Curves.easeOutCubic,
              onEnd: () => setState(() => _landed.add(i)),
              builder: (context, t, _) {
                final pos = Offset.lerp(widget.from, widget.to, t)!;
                // Shrink toward the bar and fade out on arrival so the card
                // reads as tucked into the opponent's hand.
                final scale = 1 - 0.35 * t;
                final opacity = t > 0.75 ? (1 - t) / 0.25 : 1.0;
                return Positioned(
                  left: pos.dx - cardW / 2,
                  top: pos.dy - cardH / 2,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: CardWidget(
                        faceUp: false,
                        enabled: false,
                        width: cardW,
                        height: cardH,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
