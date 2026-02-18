import 'package:flutter/material.dart';
import '../../../core/models/card.dart';
import '../../../shared/utils/card_utils.dart';
import 'card_widget.dart';

class HandFan extends StatefulWidget {
  final List<PlayingCard> cards;
  final Set<int> selectedIndices;
  final bool enabled;
  final void Function(int index)? onCardTap;

  const HandFan({
    super.key,
    required this.cards,
    this.selectedIndices = const {},
    this.enabled = true,
    this.onCardTap,
  });

  @override
  State<HandFan> createState() => _HandFanState();
}

class _HandFanState extends State<HandFan> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<PlayingCard> _currentCards = [];
  bool _initialBuild = true;

  @override
  void initState() {
    super.initState();
    _currentCards = CardUtils.sorted(widget.cards);
  }

  @override
  void didUpdateWidget(HandFan oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newSorted = CardUtils.sorted(widget.cards);
    final oldSorted = _currentCards;

    if (_listEquals(newSorted, oldSorted)) return;

    // Find removed cards (in old but not in new)
    final removed = <int>[];
    for (int i = oldSorted.length - 1; i >= 0; i--) {
      if (!_containsCard(newSorted, oldSorted[i])) {
        removed.add(i);
      }
    }

    // Remove with animation (reverse order so indices stay valid)
    for (final idx in removed) {
      final card = oldSorted[idx];
      _listKey.currentState?.removeItem(
        idx,
        (context, animation) => _buildRemovedItem(card, animation),
        duration: const Duration(milliseconds: 250),
      );
    }

    // Find added cards (in new but not in old)
    // Build intermediate list after removals
    final afterRemoval = List<PlayingCard>.from(oldSorted);
    for (final idx in removed) {
      afterRemoval.removeAt(idx);
    }

    for (int i = 0; i < newSorted.length; i++) {
      if (i >= afterRemoval.length || !_cardEquals(newSorted[i], afterRemoval[i])) {
        if (!_containsCard(afterRemoval, newSorted[i])) {
          // Stagger insertion animation
          Future.delayed(Duration(milliseconds: 50 * (i - removed.length).clamp(0, 10)), () {
            if (mounted && _listKey.currentState != null) {
              _listKey.currentState!.insertItem(
                i.clamp(0, _currentCards.length),
                duration: const Duration(milliseconds: 300),
              );
            }
          });
        }
      }
    }

    _currentCards = newSorted;
  }

  bool _listEquals(List<PlayingCard> a, List<PlayingCard> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!_cardEquals(a[i], b[i])) return false;
    }
    return true;
  }

  bool _cardEquals(PlayingCard a, PlayingCard b) =>
      a.rank == b.rank && a.suit == b.suit;

  bool _containsCard(List<PlayingCard> list, PlayingCard card) =>
      list.any((c) => _cardEquals(c, card));

  Widget _buildRemovedItem(PlayingCard card, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0, -1),
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeInCubic,
      )),
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: CardWidget(card: card, faceUp: true, enabled: false),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sorted = CardUtils.sorted(widget.cards);

    // On first build or when AnimatedList state is lost, sync _currentCards
    if (_initialBuild) {
      _initialBuild = false;
      _currentCards = sorted;
    }

    return SizedBox(
      height: 94, // card height + selection offset
      child: AnimatedList(
        key: _listKey,
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        initialItemCount: sorted.length,
        itemBuilder: (context, index, animation) {
          if (index >= sorted.length) return const SizedBox.shrink();
          final card = sorted[index];
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: FadeTransition(
              opacity: animation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: CardWidget(
                  card: card,
                  faceUp: true,
                  selected: widget.selectedIndices.contains(index),
                  enabled: widget.enabled,
                  onTap: widget.onCardTap != null
                      ? () => widget.onCardTap!(index)
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class OpponentHand extends StatelessWidget {
  final int cardCount;

  const OpponentHand({super.key, required this.cardCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < cardCount; i++)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: CardWidget(
              faceUp: false,
              width: 45,
              height: 67,
            ),
          ),
      ],
    );
  }
}
