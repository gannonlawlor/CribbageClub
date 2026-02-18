import '../models/card.dart';
import '../models/game_action.dart';
import '../models/game_history_event.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/score_breakdown.dart';
import 'deck.dart';
import 'hand_counting.dart';
import 'score_breakdown_calculator.dart';

class GameEngine {
  final String id;
  final Deck _deck;
  final List<GameHistoryEvent> _history = [];
  GameState _state;
  int _currentRound;

  static const _cardsPerHand = 6;
  static const _keepCards = 4;
  static const _winScore = 121;

  GameEngine({
    required this.id,
    required List<Player> players,
    Deck? deck,
  })  : _deck = deck ?? Deck(),
        _state = GameState(gameId: id, players: players),
        _currentRound = 1 {
    assert(players.length == 2);
    _dealCards();
  }

  GameEngine._restore({
    required this.id,
    required Deck deck,
    required GameState state,
    required List<GameHistoryEvent> history,
    required int currentRound,
  })  : _deck = deck,
        _state = state,
        _currentRound = currentRound {
    _history.addAll(history);
  }

  factory GameEngine.restore(GameState state) {
    final deck = Deck(state.remainingDeck);
    final currentRound = state.history
        .whereType<RoundStarted>()
        .length
        .clamp(1, 999);
    return GameEngine._restore(
      id: state.gameId,
      deck: deck,
      state: state.copyWith(history: [], remainingDeck: []),
      history: List.of(state.history),
      currentRound: currentRound,
    );
  }

  GameState get currentState => _state.copyWith(
        history: List.unmodifiable(_history),
        remainingDeck: _deck.remainingCards(),
      );

  GameState applyAction(GameAction action) {
    action.map(
      discardToCrib: (a) => _discardToCrib(a.playerId, a.card),
      cutDeck: (a) => _cutDeck(a.playerId),
      playCard: (a) => _playCard(a.playerId, a.card),
      go: (a) => _announceGo(a.playerId),
      countHand: (a) => _countHand(a.playerId),
    );
    return currentState;
  }

  // ── Deal ──────────────────────────────────────────────────────────────

  void _dealCards() {
    _addEvent(GameHistoryEvent.roundStarted(
      timestamp: _now(),
      roundNumber: _currentRound,
    ));

    _state = _state.copyWith(
      stage: GameStage.dealing,
      players: _state.players
          .map((p) => p.copyWith(hand: _deck.drawN(_cardsPerHand)))
          .toList(),
      currentPlayerId: _state.players.first.id,
    );

    _addEvent(GameHistoryEvent.cardsDealt(
      timestamp: _now(),
      dealtHands: {for (final p in _state.players) p.id: p.hand},
    ));

    _state = _state.copyWith(stage: GameStage.discardingToCrib);
  }

  // ── Discard ───────────────────────────────────────────────────────────

  void _discardToCrib(String playerId, PlayingCard card) {
    assert(_state.stage == GameStage.discardingToCrib);
    final playerIndex = _playerIndex(playerId);
    final player = _state.players[playerIndex];
    assert(player.hand.contains(card));

    final updatedPlayer = player.copyWith(
      hand: List.of(player.hand)..remove(card),
    );
    final updatedPlayers = List.of(_state.players)
      ..[playerIndex] = updatedPlayer;

    var nextPlayerId = _state.currentPlayerId;
    if (updatedPlayer.hand.length == _keepCards) {
      final otherIndex = (playerIndex + 1) % _state.players.length;
      final other = _state.players[otherIndex];
      if (other.hand.length > _keepCards) {
        nextPlayerId = other.id;
      }
    }

    _state = _state.copyWith(
      players: updatedPlayers,
      crib: [..._state.crib, card],
      currentPlayerId: nextPlayerId,
    );

    if (_state.crib.length == _state.players.length * 2) {
      _transitionToCutting();
    }
  }

  void _transitionToCutting() {
    final nonDealerIndex = _nonDealerIndex();
    _state = _state.copyWith(
      stage: GameStage.cutting,
      currentPlayerId: _state.players[nonDealerIndex].id,
    );
  }

  // ── Cut ───────────────────────────────────────────────────────────────

  void _cutDeck(String playerId) {
    assert(_state.stage == GameStage.cutting);
    assert(playerId == _state.currentPlayerId);

    final cutCard = _deck.cut();
    final handsForCounting = {for (final p in _state.players) p.id: p.hand};
    final dealerScoredNobs = cutCard.rank == Rank.jack;

    _state = _state.copyWith(
      cutCard: cutCard,
      stage: GameStage.pegging,
      currentPlayerId: playerId,
      handsForCounting: handsForCounting,
    );

    if (dealerScoredNobs) {
      final dealerIdx = _dealerIndex();
      final updatedPlayers = List.of(_state.players);
      final dealer = updatedPlayers[dealerIdx];
      updatedPlayers[dealerIdx] =
          dealer.copyWith(score: dealer.score + 2);
      _state = _state.copyWith(players: updatedPlayers);
    }

    _addEvent(GameHistoryEvent.deckCut(
      timestamp: _now(),
      cutCard: cutCard,
      cuttingPlayerId: playerId,
      dealerScoredNobs: dealerScoredNobs,
    ));
  }

  // ── Pegging ───────────────────────────────────────────────────────────

  void _playCard(String playerId, PlayingCard card) {
    assert(_state.stage == GameStage.pegging);
    assert(playerId == _state.currentPlayerId);

    final playerIndex = _playerIndex(playerId);
    final player = _state.players[playerIndex];
    assert(player.hand.contains(card));

    final newCount = _state.peggingCount + card.rank.peggingValue;
    assert(newCount <= 31);

    final updatedPlayer = player.copyWith(
      hand: List.of(player.hand)..remove(card),
    );
    final updatedPlayedCards = [..._state.playedCards, card];

    final scoreEarned =
        _calculatePeggingScore(updatedPlayedCards, newCount);
    final playerWithScore =
        updatedPlayer.copyWith(score: updatedPlayer.score + scoreEarned);
    final updatedPlayers = List.of(_state.players)
      ..[playerIndex] = playerWithScore;

    // Scoring reason for history
    String? scoringReason;
    if (newCount == 31) {
      scoringReason = 'Thirty-one';
    } else if (newCount == 15) {
      scoringReason = 'Fifteen';
    } else if (scoreEarned > 0 && updatedPlayedCards.length >= 2) {
      final lastCard = updatedPlayedCards.last;
      var sameFaceCount = 0;
      for (final c in updatedPlayedCards.reversed) {
        if (c.rank == lastCard.rank) {
          sameFaceCount++;
        } else {
          break;
        }
      }
      scoringReason = switch (sameFaceCount) {
        2 => 'Pair',
        3 => 'Three of a kind',
        4 => 'Four of a kind',
        _ => () {
            for (var runLength = 7; runLength >= 3; runLength--) {
              if (updatedPlayedCards.length >= runLength &&
                  _isRun(updatedPlayedCards
                      .sublist(updatedPlayedCards.length - runLength))) {
                return 'Run of $runLength';
              }
            }
            return null;
          }(),
      };
    }

    final nextPlayerIndex =
        (playerIndex + 1) % _state.players.length;
    _state = _state.copyWith(
      players: updatedPlayers,
      playedCards: updatedPlayedCards,
      peggingCount: newCount,
      currentPlayerId: _state.players[nextPlayerIndex].id,
      lastPlayWasGo: false,
    );

    _addEvent(GameHistoryEvent.cardPlayed(
      timestamp: _now(),
      playerId: playerId,
      card: card,
      newCount: newCount,
      pointsScored: scoreEarned,
      scoringReason: scoringReason,
    ));

    if (_state.players.every((p) => p.hand.isEmpty)) {
      _addEvent(GameHistoryEvent.peggingEnded(timestamp: _now()));
      _transitionToHandCounting();
    }
  }

  void _announceGo(String playerId) {
    assert(_state.stage == GameStage.pegging);
    assert(playerId == _state.currentPlayerId);

    final playerIndex = _playerIndex(playerId);
    final nextPlayerIndex =
        (playerIndex + 1) % _state.players.length;
    final nextPlayerId = _state.players[nextPlayerIndex].id;

    if (_state.lastPlayWasGo) {
      final currentPlayer = _state.players[playerIndex];
      final updatedPlayer =
          currentPlayer.copyWith(score: currentPlayer.score + 1);
      final updatedPlayers = List.of(_state.players)
        ..[playerIndex] = updatedPlayer;

      _state = _state.copyWith(
        players: updatedPlayers,
        peggingCount: 0,
        playedCards: [],
        currentPlayerId: nextPlayerId,
        lastPlayWasGo: false,
      );

      _addEvent(GameHistoryEvent.goAnnounced(
        timestamp: _now(),
        playerId: playerId,
        pointsScored: 1,
      ));

      if (_state.players.every((p) => p.hand.isEmpty)) {
        _addEvent(GameHistoryEvent.peggingEnded(timestamp: _now()));
        _transitionToHandCounting();
      }
    } else {
      _state = _state.copyWith(
        currentPlayerId: nextPlayerId,
        lastPlayWasGo: true,
      );

      _addEvent(GameHistoryEvent.goAnnounced(
        timestamp: _now(),
        playerId: playerId,
        pointsScored: 0,
      ));
    }
  }

  int _calculatePeggingScore(
    List<PlayingCard> playedCards,
    int count,
  ) {
    var score = 0;

    if (count == 15 || count == 31) score += 2;

    final lastCard = playedCards.last;
    var sameFaceCount = 0;
    for (final c in playedCards.reversed) {
      if (c.rank == lastCard.rank) {
        sameFaceCount++;
      } else {
        break;
      }
    }
    score += switch (sameFaceCount) {
      2 => 2,
      3 => 6,
      4 => 12,
      _ => 0,
    };

    for (var runLength = 7; runLength >= 3; runLength--) {
      if (playedCards.length >= runLength &&
          _isRun(
              playedCards.sublist(playedCards.length - runLength))) {
        score += runLength;
        break;
      }
    }

    return score;
  }

  bool _isRun(List<PlayingCard> cards) {
    if (cards.length < 3) return false;
    final sortedRanks = cards.map((c) => c.rank.index).toList()..sort();
    for (var i = 1; i < sortedRanks.length; i++) {
      if (sortedRanks[i] - sortedRanks[i - 1] != 1) return false;
    }
    return true;
  }

  void _transitionToHandCounting() {
    final nonDealerIndex = _nonDealerIndex();
    _state = _state.copyWith(
      stage: GameStage.counting,
      currentPlayerId: _state.players[nonDealerIndex].id,
      peggingCount: 0,
      playedCards: [],
    );
  }

  // ── Counting ──────────────────────────────────────────────────────────

  void _countHand(String playerId) {
    assert(_state.stage == GameStage.counting);
    assert(playerId == _state.currentPlayerId);

    final playerIndex = _playerIndex(playerId);
    final player = _state.players[playerIndex];
    final handToCount = _state.handsForCounting[playerId] ?? [];
    assert(handToCount.isNotEmpty);

    final handScore =
        HandCounting.calculateHandScore(handToCount, _state.cutCard!);
    final scoreBreakdown =
        ScoreBreakdownCalculator.calculate(handToCount, _state.cutCard!);
    final updatedPlayer =
        player.copyWith(score: player.score + handScore);
    final updatedPlayers = List.of(_state.players)
      ..[playerIndex] = updatedPlayer;

    _addEvent(GameHistoryEvent.handCounted(
      timestamp: _now(),
      playerId: playerId,
      hand: handToCount,
      totalPoints: handScore,
      scoreBreakdown: scoreBreakdown,
    ));

    if (updatedPlayer.score >= _winScore) {
      _state = _state.copyWith(
        players: updatedPlayers,
        stage: GameStage.gameOver,
      );
      _addEvent(GameHistoryEvent.gameEnded(
        timestamp: _now(),
        winnerPlayerId: playerId,
        finalScore: updatedPlayer.score,
      ));
      return;
    }

    if (playerIndex == _dealerIndex()) {
      // Dealer counted, now count crib
      final dealerIndex = _dealerIndex();
      final dealer = updatedPlayers[dealerIndex];
      final cribScore = HandCounting.calculateHandScore(
        _state.crib,
        _state.cutCard!,
        isCrib: true,
      );
      final cribBreakdown = ScoreBreakdownCalculator.calculate(
        _state.crib,
        _state.cutCard!,
        isCrib: true,
      );
      final updatedDealer =
          dealer.copyWith(score: dealer.score + cribScore);
      updatedPlayers[dealerIndex] = updatedDealer;

      _addEvent(GameHistoryEvent.cribCounted(
        timestamp: _now(),
        dealerPlayerId: dealer.id,
        totalPoints: cribScore,
        scoreBreakdown: cribBreakdown,
        cribCards: _state.crib,
      ));

      if (updatedDealer.score >= _winScore) {
        _state = _state.copyWith(
          players: updatedPlayers,
          stage: GameStage.gameOver,
        );
        _addEvent(GameHistoryEvent.gameEnded(
          timestamp: _now(),
          winnerPlayerId: dealer.id,
          finalScore: updatedDealer.score,
        ));
        return;
      }

      _startNewRound(updatedPlayers);
    } else {
      // Non-dealer counted, now dealer counts
      final dealerIdx = _dealerIndex();
      _state = _state.copyWith(
        players: updatedPlayers,
        currentPlayerId: _state.players[dealerIdx].id,
      );
    }
  }

  void _startNewRound(List<Player> updatedPlayers) {
    _deck.reset();
    _currentRound++;

    final newDealerIndex =
        (_state.dealerIndex + 1) % _state.players.length;

    _state = _state.copyWith(
      players: updatedPlayers
          .map((p) => p.copyWith(hand: _deck.drawN(_cardsPerHand)))
          .toList(),
      crib: [],
      cutCard: null,
      currentPlayerId: updatedPlayers.first.id,
      stage: GameStage.dealing,
      playedCards: [],
      peggingCount: 0,
      lastPlayWasGo: false,
      handsForCounting: {},
      dealerIndex: newDealerIndex,
    );

    _addEvent(GameHistoryEvent.roundStarted(
      timestamp: _now(),
      roundNumber: _currentRound,
    ));
    _addEvent(GameHistoryEvent.cardsDealt(
      timestamp: _now(),
      dealtHands: {for (final p in _state.players) p.id: p.hand},
    ));

    _state = _state.copyWith(stage: GameStage.discardingToCrib);
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  int _playerIndex(String playerId) {
    final idx = _state.players.indexWhere((p) => p.id == playerId);
    assert(idx != -1, 'Player not found: $playerId');
    return idx;
  }

  int _dealerIndex() => _state.dealerIndex;
  int _nonDealerIndex() =>
      (_state.dealerIndex + 1) % _state.players.length;

  void _addEvent(GameHistoryEvent event) => _history.add(event);

  static String _now() => DateTime.now().toIso8601String();
}
