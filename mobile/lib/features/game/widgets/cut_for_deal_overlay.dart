import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/constants.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/models/card.dart';
import '../../../core/services/settings_provider.dart';
import 'card_widget.dart';

/// Opening cut for first deal: a ribbon of face-down cards, the player picks
/// one, it slides to their side of the table and flips; the opponent's pick
/// follows to the other side. Low card deals first.
///
/// The dealer was already decided when the game was created — the revealed
/// ranks are generated to agree with it, so the ceremony always tells the
/// truth without the engine needing a cut-for-deal stage.
class CutForDealOverlay extends ConsumerStatefulWidget {
  final bool playerDeals;
  final String opponentName;
  final VoidCallback onComplete;

  const CutForDealOverlay({
    super.key,
    required this.playerDeals,
    required this.opponentName,
    required this.onComplete,
  });

  @override
  ConsumerState<CutForDealOverlay> createState() => _CutForDealOverlayState();
}

enum _CutPhase { pick, playerCut, opponentCut, result, fadeOut }

class _CutForDealOverlayState extends ConsumerState<CutForDealOverlay> {
  /// The whole deck goes on the table, the way it does in front of you.
  static const int _ribbonCount = 52;

  /// Cascaded in rows rather than one long ribbon: 52 cards in a single row
  /// leaves a 6pt sliver each and reads as a striped bar, not a deck. Thirteen
  /// to a row shows better than half of every card.
  static const int _perRow = 13;
  static const int _spreadRows = _ribbonCount ~/ _perRow;

  /// Row pitch as a fraction of card height — rows overlap, so the spread
  /// cascades the way a dealer's ribbon does.
  static const double _rowPitch = 0.62;

  /// Odd rows shift half a card over, so the spread doesn't line up into a
  /// grid.
  static const double _rowStagger = 0.5;

  /// One line of the 10pt slot label. The label sits outside the card's own
  /// box, so the slot has to leave room for it.
  static const double _labelHeight = 13;

  late final PlayingCard _playerCard;
  late final PlayingCard _opponentCard;
  late int _opponentPick;

  _CutPhase _phase = _CutPhase.pick;
  int? _playerPick;
  bool _playerFaceUp = false;
  bool _opponentFaceUp = false;
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    final rng = math.Random();

    // Two distinct ranks so there's never a tie to explain; the lower one
    // belongs to whoever actually deals.
    final ranks = Rank.values.toList()..shuffle(rng);
    final low = ranks[0].index < ranks[1].index ? ranks[0] : ranks[1];
    final high = ranks[0].index < ranks[1].index ? ranks[1] : ranks[0];
    final suits = Suit.values;
    final lowCard = PlayingCard(rank: low, suit: suits[rng.nextInt(4)]);
    final highCard = PlayingCard(rank: high, suit: suits[rng.nextInt(4)]);

    _playerCard = widget.playerDeals ? lowCard : highCard;
    _opponentCard = widget.playerDeals ? highCard : lowCard;
    _opponentPick = rng.nextInt(_ribbonCount);
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  Duration _scaled(int ms) =>
      ref.read(settingsProvider).scaleDuration(Duration(milliseconds: ms));

  void _after(int ms, VoidCallback fn) {
    _timers.add(
      Timer(_scaled(ms), () {
        if (mounted) fn();
      }),
    );
  }

  /// Where slot [i] sits in the spread. Cards later in the deck draw on top,
  /// so each row cascades over the one above it and a tap always lands on the
  /// card whose sliver is showing.
  ({double x, double y}) _slot(
    int i, {
    required double ribbonX,
    required double ribbonY,
    required double step,
    required double cardH,
  }) {
    final row = i ~/ _perRow;
    return (
      x: ribbonX + (i % _perRow) * step + (row.isOdd ? step * _rowStagger : 0),
      y: ribbonY + row * cardH * _rowPitch,
    );
  }

  void _onPick(int index) {
    if (_phase != _CutPhase.pick) return;
    // Never let the engine draw the card the player just took.
    if (_opponentPick == index) {
      _opponentPick = (index + 1) % _ribbonCount;
    }
    setState(() {
      _playerPick = index;
      _phase = _CutPhase.playerCut;
    });
    // Slide down, then flip, then the opponent takes their turn.
    _after(320, () => setState(() => _playerFaceUp = true));
    _after(1000, () => setState(() => _phase = _CutPhase.opponentCut));
    _after(1320, () => setState(() => _opponentFaceUp = true));
    _after(2000, () => setState(() => _phase = _CutPhase.result));
    _after(3800, _finish);
  }

  void _finish() {
    if (_phase == _CutPhase.fadeOut) return;
    setState(() => _phase = _CutPhase.fadeOut);
    _timers.add(
      Timer(const Duration(milliseconds: 260), () {
        if (mounted) widget.onComplete();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Positioned.fill(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 240),
        opacity: _phase == _CutPhase.fadeOut ? 0 : 1,
        child: GestureDetector(
          // Once the outcome is on screen a tap skips the hold.
          onTap: _phase == _CutPhase.result ? _finish : null,
          // Near-opaque: the table behind still knows who deals, and a
          // readable DEALER badge would spoil the reveal.
          child: Container(
            color: colors.scaffoldBg.withValues(alpha: 0.985),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;

                  final cardW = math.min(52.0, w * 0.14);
                  final cardH = cardW / AppConstants.cardAspectRatio;
                  // Each row spans the full width; the whole deck is on the
                  // table, so every card shows an edge you can pick.
                  final step = (w - 44 - cardW) / (_perRow - 1 + _rowStagger);
                  final ribbonX = 22.0;
                  final spreadH = cardH * (1 + (_spreadRows - 1) * _rowPitch);
                  final ribbonY = h * 0.50 - spreadH / 2;
                  ({double x, double y}) slotAt(int i) => _slot(
                    i,
                    ribbonX: ribbonX,
                    ribbonY: ribbonY,
                    step: step,
                    cardH: cardH,
                  );

                  // The picked cards travel to each player's side of the
                  // table, clear of the spread.
                  final slotX = (w - cardW) / 2;
                  final playerSlotY = math.min(
                    ribbonY + spreadH + 46,
                    h - cardH - 86,
                  );
                  // Both slots are the card's own top edge; the name sits in
                  // the gap above (opponent) or below (player).
                  final opponentSlotY = math.max(
                    ribbonY - cardH - 46,
                    68.0 + _labelHeight + 5,
                  );

                  return Stack(
                    children: [
                      // Header
                      Positioned(
                        left: 24,
                        right: 24,
                        top: h * 0.10,
                        child: Column(
                          children: [
                            Text(
                              'Cut for deal',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _headline(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 14,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Opponent's cut card
                      if (_phase.index >= _CutPhase.opponentCut.index)
                        _travellingCard(
                          fromX: slotAt(_opponentPick).x,
                          fromY: slotAt(_opponentPick).y,
                          toX: slotX,
                          toY: opponentSlotY,
                          card: _opponentCard,
                          faceUp: _opponentFaceUp,
                          label: widget.opponentName,
                          labelBelow: false,
                          cardW: cardW,
                          cardH: cardH,
                          colors: colors,
                        ),

                      // The spread (picked cards drop out of it). Later cards
                      // sit on top, so a tap always lands on the card whose
                      // sliver is showing at that point.
                      for (int i = 0; i < _ribbonCount; i++)
                        if (i != _playerPick &&
                            !(_phase.index >= _CutPhase.opponentCut.index &&
                                i == _opponentPick))
                          Positioned(
                            left: slotAt(i).x,
                            top: slotAt(i).y,
                            child: GestureDetector(
                              onTap: () => _onPick(i),
                              child: CardWidget(
                                faceUp: false,
                                enabled: false,
                                width: cardW,
                                height: cardH,
                              ),
                            ),
                          ),

                      // Player's cut card
                      if (_playerPick != null)
                        _travellingCard(
                          fromX: slotAt(_playerPick!).x,
                          fromY: slotAt(_playerPick!).y,
                          toX: slotX,
                          toY: playerSlotY,
                          card: _playerCard,
                          faceUp: _playerFaceUp,
                          label: 'You',
                          labelBelow: true,
                          cardW: cardW,
                          cardH: cardH,
                          colors: colors,
                        ),

                      // Result
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: h * 0.06,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 240),
                          opacity: _phase.index >= _CutPhase.result.index
                              ? 1
                              : 0,
                          child: Column(
                            children: [
                              Text(
                                widget.playerDeals
                                    ? 'You deal first'
                                    : '${widget.opponentName} deals first',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to continue',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colors.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _headline() {
    switch (_phase) {
      case _CutPhase.pick:
        return 'Pick a card — low card deals first';
      case _CutPhase.playerCut:
        return 'Your cut';
      case _CutPhase.opponentCut:
        return '${widget.opponentName} cuts';
      case _CutPhase.result:
      case _CutPhase.fadeOut:
        return 'Low card deals first';
    }
  }

  /// A card that starts in the ribbon and settles at its player's slot,
  /// flipping once it arrives.
  Widget _travellingCard({
    required double fromX,
    required double fromY,
    required double toX,
    required double toY,
    required PlayingCard card,
    required bool faceUp,
    required String label,
    required bool labelBelow,
    required double cardW,
    required double cardH,
    required AppColors colors,
  }) {
    final labelText = Text(
      label.toUpperCase(),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: colors.textTertiary,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    );

    // The card and its label are laid out apart, not stacked in a Column: a
    // name wider than the card would otherwise set the Column's width and
    // push the card off the slot it shares with the other player's cut.
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        // Drive the slide from the ribbon by hand so the first frame renders
        // at the ribbon position rather than popping in at the slot.
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => Stack(
          children: [
            // The label belongs to the slot, not the card, so it fades in
            // where the card is headed rather than travelling with it.
            Positioned(
              left: 0,
              right: 0,
              top: labelBelow ? toY + cardH + 5 : toY - _labelHeight - 5,
              child: Opacity(opacity: t, child: labelText),
            ),
            Positioned(
              left: toX + (fromX - toX) * (1 - t),
              top: toY + (fromY - toY) * (1 - t),
              child: FlippableCardWidget(
                card: card,
                faceUp: faceUp,
                width: cardW,
                height: cardH,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
