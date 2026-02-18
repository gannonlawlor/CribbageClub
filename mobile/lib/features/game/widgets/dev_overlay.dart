import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/card.dart';
import '../../../core/models/game_history_event.dart';
import '../../../core/models/score_breakdown.dart';
import '../state/game_providers.dart';

/// Dev-only overlay for local AI games.
/// Provides a game log, score editing, and hand pre-configuration.
/// Gated behind [kDebugMode] at the call site.
class DevOverlay extends ConsumerStatefulWidget {
  final String gameId;
  final String playerId;

  const DevOverlay({super.key, required this.gameId, required this.playerId});

  @override
  ConsumerState<DevOverlay> createState() => _DevOverlayState();
}

class _DevOverlayState extends ConsumerState<DevOverlay>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;

  // Score sliders
  double _playerScore = 0;
  double _opponentScore = 0;
  bool _scoresInitialized = false;

  // Hand picker
  _HandTarget _handTarget = _HandTarget.player;
  final Set<PlayingCard> _playerHandCards = {};
  final Set<PlayingCard> _opponentHandCards = {};
  bool _handsQueued = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(localGameNotifierProvider(widget.gameId)).gameState;
    if (gs == null) return const SizedBox.shrink();

    // Initialize score sliders from current game state
    if (!_scoresInitialized) {
      final pIdx = gs.players.indexWhere((p) => p.id == widget.playerId);
      if (pIdx >= 0) {
        _playerScore = gs.players[pIdx].score.toDouble();
        _opponentScore = gs.players[1 - pIdx].score.toDouble();
        _scoresInitialized = true;
      }
    }

    return Stack(
      children: [
        // Toggle button
        Positioned(
          bottom: 80,
          right: 4,
          child: SizedBox(
            width: 32,
            height: 32,
            child: FloatingActionButton(
              heroTag: 'dev_toggle',
              mini: true,
              backgroundColor: _open
                  ? Colors.red.shade700
                  : Colors.orange.shade800,
              onPressed: _toggle,
              child: Icon(
                _open ? Icons.close : Icons.bug_report,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),

        // Slide-in panel
        if (_open || _animController.isAnimating)
          SlideTransition(
            position: _slideAnimation,
            child: _buildPanel(context, gs),
          ),
      ],
    );
  }

  Widget _buildPanel(BuildContext context, dynamic gs) {
    final playerIdx = gs.players.indexWhere((p) => p.id == widget.playerId);
    final player = playerIdx >= 0 ? gs.players[playerIdx] : gs.players[0];
    final opponent = gs.players[playerIdx >= 0 ? 1 - playerIdx : 1];

    return Container(
      color: Colors.black.withValues(alpha: 0.92),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: _toggle,
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'DEV MODE',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),

            // Scrollable content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  // Section 1: Game Log
                  _sectionHeader('Game Log'),
                  _buildGameLog(gs),
                  const SizedBox(height: 16),

                  // Section 2: Set Scores
                  _sectionHeader('Set Scores'),
                  _buildScoreEditor(player, opponent),
                  const SizedBox(height: 16),

                  // Section 3: Set Next Deal Hands
                  _sectionHeader('Set Next Deal'),
                  _buildHandPicker(player, opponent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.orange,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ── Game Log ──────────────────────────────────────────────────────────

  Widget _buildGameLog(dynamic gs) {
    final events = gs.history as List<GameHistoryEvent>;
    if (events.isEmpty) {
      return const Text(
        'No events yet.',
        style: TextStyle(color: Colors.white38, fontSize: 12),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(
              _describeEvent(event),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          );
        },
      ),
    );
  }

  String _playerLabel(String id) => id == widget.playerId ? 'You' : 'Opponent';

  String _breakdownSummary(ScoreBreakdown b) {
    final parts = <String>[];
    if (b.fifteens > 0) parts.add('${b.fifteens} fifteens');
    if (b.pairs > 0) parts.add('${b.pairs} pairs');
    if (b.runs > 0) parts.add('${b.runs} runs');
    if (b.flushes > 0) parts.add('${b.flushes} flush');
    if (b.nobs > 0) parts.add('${b.nobs} nobs');
    return parts.isEmpty ? '' : ' (${parts.join(', ')})';
  }

  String _describeEvent(GameHistoryEvent event) {
    return switch (event) {
      RoundStarted(:final roundNumber) => 'Round $roundNumber started',
      CardsDealt() => 'Cards dealt',
      DeckCut(
        :final cuttingPlayerId,
        :final cutCard,
        :final dealerScoredNobs,
      ) =>
        '${_playerLabel(cuttingPlayerId)} cut ${cutCard.rank.display}${cutCard.suit.symbol}'
            '${dealerScoredNobs ? " - Nobs! +2" : ""}',
      CardPlayed(
        :final playerId,
        :final card,
        :final newCount,
        :final pointsScored,
      ) =>
        '${_playerLabel(playerId)} played ${card.rank.display}${card.suit.symbol} (count: $newCount)'
            '${pointsScored > 0 ? " +$pointsScored" : ""}',
      GoAnnounced(:final playerId, :final pointsScored) =>
        '${_playerLabel(playerId)} said Go${pointsScored > 0 ? " +$pointsScored" : ""}',
      PeggingEnded() => 'Pegging ended',
      HandCounted(:final playerId, :final totalPoints, :final scoreBreakdown) =>
        '${_playerLabel(playerId)} counted $totalPoints pts${_breakdownSummary(scoreBreakdown)}',
      CribCounted(
        :final dealerPlayerId,
        :final totalPoints,
        :final scoreBreakdown,
      ) =>
        '${_playerLabel(dealerPlayerId)} counted $totalPoints in crib${_breakdownSummary(scoreBreakdown)}',
      GameEnded(:final winnerPlayerId, :final finalScore) =>
        '${_playerLabel(winnerPlayerId)} wins with $finalScore!',
      GameForfeited(:final forfeitingPlayerId, :final reason) =>
        '${_playerLabel(forfeitingPlayerId)} forfeited ($reason)',
    };
  }

  // ── Score Editor ──────────────────────────────────────────────────────

  Widget _buildScoreEditor(dynamic player, dynamic opponent) {
    return Column(
      children: [
        _scoreRow('You', _playerScore, (v) {
          setState(() => _playerScore = v);
        }),
        const SizedBox(height: 4),
        _scoreRow('Opponent', _opponentScore, (v) {
          setState(() => _opponentScore = v);
        }),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onPressed: () {
              final notifier = ref.read(
                localGameNotifierProvider(widget.gameId).notifier,
              );
              notifier.devSetScore(player.id as String, _playerScore.round());
              notifier.devSetScore(
                opponent.id as String,
                _opponentScore.round(),
              );
              // Refresh sliders from updated state
              final gs = ref
                  .read(localGameNotifierProvider(widget.gameId))
                  .gameState;
              if (gs != null) {
                final pIdx = gs.players.indexWhere(
                  (p) => p.id == widget.playerId,
                );
                if (pIdx >= 0) {
                  setState(() {
                    _playerScore = gs.players[pIdx].score.toDouble();
                    _opponentScore = gs.players[1 - pIdx].score.toDouble();
                  });
                }
              }
            },
            child: const Text('Apply Scores'),
          ),
        ),
      ],
    );
  }

  Widget _scoreRow(String label, double value, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            '$label:',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 121,
            divisions: 121,
            activeColor: Colors.orange,
            inactiveColor: Colors.white24,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '${value.round()}',
            style: const TextStyle(color: Colors.white, fontSize: 13),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // ── Hand Picker ───────────────────────────────────────────────────────

  Widget _buildHandPicker(dynamic player, dynamic opponent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Target toggle
        Row(
          children: [
            _targetButton(
              'Your Hand',
              _HandTarget.player,
              _playerHandCards.length,
            ),
            const SizedBox(width: 8),
            _targetButton(
              'Opp Hand',
              _HandTarget.opponent,
              _opponentHandCards.length,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Card grid by suit
        for (final suit in Suit.values) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Wrap(
              spacing: 3,
              runSpacing: 3,
              children: [
                for (final rank in Rank.values)
                  _cardChip(PlayingCard(rank: rank, suit: suit)),
              ],
            ),
          ),
        ],

        const SizedBox(height: 8),

        // Selected cards summary
        if (_playerHandCards.isNotEmpty || _opponentHandCards.isNotEmpty) ...[
          if (_playerHandCards.isNotEmpty)
            Text(
              'You: ${_playerHandCards.map(_cardLabel).join(', ')}',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          if (_opponentHandCards.isNotEmpty)
            Text(
              'Opp: ${_opponentHandCards.map(_cardLabel).join(', ')}',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          const SizedBox(height: 8),
        ],

        // Queue button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onPressed:
                (_playerHandCards.length == 6 && _opponentHandCards.length == 6)
                ? () {
                    final gs = ref
                        .read(localGameNotifierProvider(widget.gameId))
                        .gameState;
                    if (gs == null) return;
                    final pIdx = gs.players.indexWhere(
                      (p) => p.id == widget.playerId,
                    );
                    if (pIdx < 0) return;
                    final opponentId = gs.players[1 - pIdx].id;

                    final notifier = ref.read(
                      localGameNotifierProvider(widget.gameId).notifier,
                    );
                    notifier.devSetNextHands({
                      widget.playerId: _playerHandCards.toList(),
                      opponentId: _opponentHandCards.toList(),
                    });
                    setState(() => _handsQueued = true);
                  }
                : null,
            child: Text(
              _playerHandCards.length == 6 && _opponentHandCards.length == 6
                  ? 'Queue for Next Deal'
                  : 'Select 6 cards per hand',
            ),
          ),
        ),

        if (_handsQueued)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Hands queued - will apply on next round',
              style: TextStyle(color: Colors.greenAccent, fontSize: 11),
            ),
          ),

        // Clear button
        if (_playerHandCards.isNotEmpty || _opponentHandCards.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton(
              onPressed: () {
                setState(() {
                  _playerHandCards.clear();
                  _opponentHandCards.clear();
                  _handsQueued = false;
                });
              },
              child: const Text(
                'Clear selections',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _targetButton(String label, _HandTarget target, int count) {
    final selected = _handTarget == target;
    return GestureDetector(
      onTap: () => setState(() => _handTarget = target),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? Colors.orange.shade800
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$label ($count/6)',
          style: TextStyle(
            color: selected ? Colors.white : Colors.white60,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _cardChip(PlayingCard card) {
    final inPlayer = _playerHandCards.contains(card);
    final inOpponent = _opponentHandCards.contains(card);
    final isSelected = inPlayer || inOpponent;

    Color bgColor;
    if (inPlayer) {
      bgColor = Colors.blue.shade800;
    } else if (inOpponent) {
      bgColor = Colors.red.shade800;
    } else {
      bgColor = Colors.white.withValues(alpha: 0.1);
    }

    return GestureDetector(
      onTap: () => _toggleCard(card),
      child: Container(
        width: 24,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(3),
          border: isSelected
              ? Border.all(color: Colors.white54, width: 1)
              : null,
        ),
        child: Text(
          card.rank.display,
          style: TextStyle(
            color: card.suit.isRed ? Colors.red.shade300 : Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _toggleCard(PlayingCard card) {
    setState(() {
      _handsQueued = false;
      final targetSet = _handTarget == _HandTarget.player
          ? _playerHandCards
          : _opponentHandCards;
      final otherSet = _handTarget == _HandTarget.player
          ? _opponentHandCards
          : _playerHandCards;

      if (targetSet.contains(card)) {
        targetSet.remove(card);
      } else if (otherSet.contains(card)) {
        // Move from other set to this one
        otherSet.remove(card);
        if (targetSet.length < 6) targetSet.add(card);
      } else if (targetSet.length < 6) {
        targetSet.add(card);
      }
    });
  }

  String _cardLabel(PlayingCard c) => '${c.rank.display}${c.suit.symbol}';
}

enum _HandTarget { player, opponent }
