import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/card.dart';
import 'card_widget.dart';

class PlayArea extends StatefulWidget {
  final List<PlayingCard> playedCards;
  final int peggingCount;

  const PlayArea({
    super.key,
    required this.playedCards,
    required this.peggingCount,
  });

  @override
  State<PlayArea> createState() => _PlayAreaState();
}

class _PlayAreaState extends State<PlayArea> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  int _currentCount = 0;

  @override
  void initState() {
    super.initState();
    _currentCount = widget.playedCards.length;
  }

  @override
  void didUpdateWidget(PlayArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newCount = widget.playedCards.length;
    final oldCount = _currentCount;

    if (newCount > oldCount) {
      // Cards were added — insert with animation
      for (int i = oldCount; i < newCount; i++) {
        _listKey.currentState?.insertItem(
          i,
          duration: const Duration(milliseconds: 200),
        );
      }
    } else if (newCount < oldCount) {
      // Cards were removed (new pegging round) — remove with animation
      for (int i = oldCount - 1; i >= newCount; i--) {
        final card = i < oldWidget.playedCards.length
            ? oldWidget.playedCards[i]
            : null;
        _listKey.currentState?.removeItem(
          i.clamp(0, _currentCount - 1),
          (context, animation) => FadeTransition(
            opacity: animation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: CardWidget(
                card: card,
                faceUp: true,
                enabled: false,
                width: 50,
                height: 75,
              ),
            ),
          ),
          duration: const Duration(milliseconds: 200),
        );
      }
    }

    _currentCount = newCount;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Pegging count badge
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Container(
            key: ValueKey(widget.peggingCount),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Count: ${widget.peggingCount}',
              style: const TextStyle(
                color: AppTheme.goldAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: widget.playedCards.isEmpty
              ? const Center(
                  child: Text(
                    'No cards played yet',
                    style: TextStyle(color: Colors.white38),
                  ),
                )
              : AnimatedList(
                  key: _listKey,
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  initialItemCount: widget.playedCards.length,
                  itemBuilder: (context, index, animation) {
                    if (index >= widget.playedCards.length) {
                      return const SizedBox.shrink();
                    }
                    return _ScaleBounceTransition(
                      animation: animation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: CardWidget(
                          card: widget.playedCards[index],
                          faceUp: true,
                          enabled: false,
                          width: 50,
                          height: 75,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Scale bounce: 0 → 1.1 → 1.0
class _ScaleBounceTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _ScaleBounceTransition({
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Use an overshoot curve for the bounce effect
        final curved = Curves.elasticOut.transform(animation.value.clamp(0.0, 1.0));
        final scale = curved.clamp(0.0, 1.15);
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: child,
    );
  }
}
