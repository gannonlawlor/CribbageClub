import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/constants.dart';
import '../../../core/api/rest_client.dart';
import '../../../core/api/websocket_client.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/engine/local_game_service.dart';
import '../../../core/models/card.dart';
import '../../../core/models/game_action.dart';
import '../../../core/models/game_response.dart';
import '../../../core/models/game_state.dart';
import '../../../core/models/websocket_messages.dart';
import '../../../core/services/game_feedback_service.dart';
import '../../../core/services/settings_provider.dart';
import '../animation/game_animation_controller.dart';
import 'local_game_notifier.dart';

// WebSocket client singleton
final webSocketClientProvider = Provider<WebSocketClient>((ref) {
  return WebSocketClient(authService: ref.read(authServiceProvider));
});

// Game state
class GameNotifierState {
  final GameState? gameState;
  final bool isLoading;
  final String? error;
  final ConnectionStatus connectionStatus;
  final bool isDiscarding;
  // Timing fields (online games only)
  final DateTime? turnStartedAt;
  final int turnTimeLimitMs;
  final int myTimeBankMs;
  final int opponentTimeBankMs;
  final bool isTimed;

  const GameNotifierState({
    this.gameState,
    this.isLoading = false,
    this.error,
    this.connectionStatus = ConnectionStatus.disconnected,
    this.isDiscarding = false,
    this.turnStartedAt,
    this.turnTimeLimitMs = 30000,
    this.myTimeBankMs = 120000,
    this.opponentTimeBankMs = 120000,
    this.isTimed = false,
  });

  GameNotifierState copyWith({
    GameState? gameState,
    bool? isLoading,
    String? error,
    ConnectionStatus? connectionStatus,
    bool? isDiscarding,
    DateTime? turnStartedAt,
    int? turnTimeLimitMs,
    int? myTimeBankMs,
    int? opponentTimeBankMs,
    bool? isTimed,
  }) {
    return GameNotifierState(
      gameState: gameState ?? this.gameState,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      isDiscarding: isDiscarding ?? this.isDiscarding,
      turnStartedAt: turnStartedAt ?? this.turnStartedAt,
      turnTimeLimitMs: turnTimeLimitMs ?? this.turnTimeLimitMs,
      myTimeBankMs: myTimeBankMs ?? this.myTimeBankMs,
      opponentTimeBankMs: opponentTimeBankMs ?? this.opponentTimeBankMs,
      isTimed: isTimed ?? this.isTimed,
    );
  }
}

class GameNotifier extends StateNotifier<GameNotifierState> {
  final String gameId;
  final RestClient _restClient;
  final WebSocketClient _wsClient;
  final String _playerId;
  final GameAnimationController animationController;
  final GameFeedbackService _feedbackService;

  GameNotifier({
    required this.gameId,
    required RestClient restClient,
    required WebSocketClient wsClient,
    required String playerId,
    required this.animationController,
    required GameFeedbackService feedbackService,
  }) : _restClient = restClient,
       _wsClient = wsClient,
       _playerId = playerId,
       _feedbackService = feedbackService,
       super(const GameNotifierState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    await _loadGameState();
    _connectWebSocket();
  }

  void _notifyAnimation(GameState newState) {
    animationController.processStateUpdate(newState);
    for (final event in animationController.events) {
      _feedbackService.onEvent(event);
    }
  }

  Future<void> _loadGameState() async {
    try {
      final response = await _restClient.getGameState(gameId);
      state = GameNotifierState(
        gameState: response.gameState,
        connectionStatus: state.connectionStatus,
        turnStartedAt: response.turnStartedAt != null
            ? DateTime.tryParse(response.turnStartedAt!)
            : null,
        turnTimeLimitMs: response.turnTimeLimitMs,
        myTimeBankMs: response.myTimeBankMs,
        opponentTimeBankMs: response.opponentTimeBankMs,
        isTimed: response.isTimed,
      );
      _notifyAnimation(response.gameState);
    } catch (e) {
      debugPrint('[Game] Failed to load game $gameId: $e');
      state = GameNotifierState(error: 'Failed to load game: $e');
    }
  }

  void _connectWebSocket() {
    // Listen to connection status changes
    _wsClient.onStatusChange = (status) {
      state = state.copyWith(connectionStatus: status);
      if (status == ConnectionStatus.connected) {
        // Re-fetch game state after reconnect to ensure consistency
        _loadGameState();
      }
    };

    if (_wsClient.isConnected) {
      state = state.copyWith(connectionStatus: ConnectionStatus.connected);
      _subscribeToGame();
      return;
    }

    _wsClient.connect(
      onConnect: () {
        _subscribeToGame();
      },
      onError: (frame) {
        state = state.copyWith(error: 'WebSocket error: ${frame.body}');
      },
    );
  }

  void _applyWsMessage(GameStateUpdateMessage msg) {
    if (_actionInFlight) return;
    final gs = msg.gameState;
    // Determine which player we are to map player1/player2 banks to my/opponent
    final isPlayer1 = gs.players.isNotEmpty && gs.players[0].id == _playerId;
    state = GameNotifierState(
      gameState: gs,
      connectionStatus: state.connectionStatus,
      turnStartedAt:
          msg.turnStartedAt != null ? DateTime.tryParse(msg.turnStartedAt!) : null,
      turnTimeLimitMs: msg.turnTimeLimitMs,
      myTimeBankMs: isPlayer1 ? msg.player1TimeBankMs : msg.player2TimeBankMs,
      opponentTimeBankMs: isPlayer1 ? msg.player2TimeBankMs : msg.player1TimeBankMs,
      isTimed: msg.isTimed,
    );
    _notifyAnimation(gs);
  }

  void _subscribeToGame() {
    _wsClient.subscribeToGame(
      gameId,
      onStateUpdate: (msg) {
        _applyWsMessage(msg);
      },
    );
    _wsClient.subscribeToUserState(
      onStateUpdate: (msg) {
        if (msg.gameId != gameId) return;
        _applyWsMessage(msg);
      },
    );
    _wsClient.subscribeToErrors(
      onError: (errorMsg) {
        if (errorMsg.gameId == gameId) {
          state = state.copyWith(error: errorMsg.error);
        }
      },
    );
    _wsClient.joinGame(gameId);
  }

  // Actions - use REST for ordering guarantees
  // Suppress WebSocket updates while REST actions are in flight
  // to prevent stale broadcasts from creating race conditions
  bool _actionInFlight = false;

  void _applyResponse(GameResponse response) {
    state = GameNotifierState(
      gameState: response.gameState,
      connectionStatus: state.connectionStatus,
      turnStartedAt: response.turnStartedAt != null
          ? DateTime.tryParse(response.turnStartedAt!)
          : null,
      turnTimeLimitMs: response.turnTimeLimitMs,
      myTimeBankMs: response.myTimeBankMs,
      opponentTimeBankMs: response.opponentTimeBankMs,
      isTimed: response.isTimed,
    );
    _notifyAnimation(response.gameState);
  }

  Future<void> discardCards(List<PlayingCard> cards) async {
    if (state.isDiscarding) return;
    _actionInFlight = true;
    state = state.copyWith(isDiscarding: true, error: null);
    try {
      GameResponse? lastResponse;
      for (final card in cards) {
        lastResponse = await _restClient.applyAction(
          gameId,
          GameAction.discardToCrib(playerId: _playerId, card: card),
        );
      }
      if (lastResponse != null) {
        _applyResponse(lastResponse);
      }
    } catch (e) {
      debugPrint('[Game] Discard failed for $gameId: $e');
      state = state.copyWith(isDiscarding: false, error: 'Discard failed: $e');
    } finally {
      _actionInFlight = false;
    }
  }

  Future<void> playCard(PlayingCard card) async {
    _actionInFlight = true;
    state = state.copyWith(error: null);
    try {
      final response = await _restClient.applyAction(
        gameId,
        GameAction.playCard(playerId: _playerId, card: card),
      );
      _applyResponse(response);
    } catch (e) {
      debugPrint('[Game] Play card failed for $gameId: $e');
      state = state.copyWith(error: 'Play card failed: $e');
    } finally {
      _actionInFlight = false;
    }
  }

  Future<void> cutDeck() async {
    _actionInFlight = true;
    state = state.copyWith(error: null);
    try {
      final response = await _restClient.applyAction(
        gameId,
        GameAction.cutDeck(playerId: _playerId),
      );
      _applyResponse(response);
    } catch (e) {
      debugPrint('[Game] Cut failed for $gameId: $e');
      state = state.copyWith(error: 'Cut failed: $e');
    } finally {
      _actionInFlight = false;
    }
  }

  Future<void> sayGo() async {
    _actionInFlight = true;
    state = state.copyWith(error: null);
    try {
      final response = await _restClient.applyAction(
        gameId,
        GameAction.go(playerId: _playerId),
      );
      _applyResponse(response);
    } catch (e) {
      debugPrint('[Game] Go failed for $gameId: $e');
      state = state.copyWith(error: 'Go failed: $e');
    } finally {
      _actionInFlight = false;
    }
  }

  Future<void> countHand() async {
    _actionInFlight = true;
    state = state.copyWith(error: null);
    try {
      final response = await _restClient.applyAction(
        gameId,
        GameAction.countHand(playerId: _playerId),
      );
      _applyResponse(response);
    } catch (e) {
      debugPrint('[Game] Count failed for $gameId: $e');
      state = state.copyWith(error: 'Count failed: $e');
    } finally {
      _actionInFlight = false;
    }
  }

  Future<void> resign() async {
    _actionInFlight = true;
    state = state.copyWith(error: null);
    try {
      final response = await _restClient.resignGame(gameId);
      _applyResponse(response);
    } catch (e) {
      debugPrint('[Game] Resign failed for $gameId: $e');
      state = state.copyWith(error: 'Resign failed: $e');
    } finally {
      _actionInFlight = false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _wsClient.onStatusChange = null;
    _wsClient.leaveGame(gameId);
    _wsClient.unsubscribeFromGame(gameId);
    animationController.dispose();
    super.dispose();
  }
}

// Animation controller per game
final gameAnimationProvider = Provider.family<GameAnimationController, String>((
  ref,
  gameId,
) {
  final controller = GameAnimationController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

// Feedback service (sound + haptics) per game
final gameFeedbackServiceProvider =
    Provider.family<GameFeedbackService, String>((ref, gameId) {
      final settings = ref.watch(settingsProvider);
      final service = GameFeedbackService(
        soundEnabled: settings.soundEnabled,
        hapticsEnabled: settings.hapticsEnabled,
      );
      ref.onDispose(() => service.dispose());
      return service;
    });

final gameNotifierProvider =
    StateNotifierProvider.family<GameNotifier, GameNotifierState, String>((
      ref,
      gameId,
    ) {
      final auth = ref.read(authProvider);
      final animController = ref.read(gameAnimationProvider(gameId));
      final feedbackService = ref.read(gameFeedbackServiceProvider(gameId));
      return GameNotifier(
        gameId: gameId,
        restClient: ref.read(restClientProvider),
        wsClient: ref.read(webSocketClientProvider),
        playerId: auth.userId ?? '',
        animationController: animController,
        feedbackService: feedbackService,
      );
    });

// Track selected cards during discard phase
final selectedCardsProvider = StateProvider.family<Set<int>, String>(
  (ref, gameId) => {},
);

// Track selected pegging card when auto-play pegging is OFF
final selectedPeggingCardProvider = StateProvider.family<PlayingCard?, String>(
  (ref, gameId) => null,
);

// ── Local (offline AI) game providers ───────────────────────────────────

bool isLocalGame(String gameId) => gameId.startsWith('local_');

/// Holds the LocalGameService instance for the active local game.
final localGameServiceProvider = Provider<LocalGameService>((ref) {
  return LocalGameService();
});

final localGameNotifierProvider =
    StateNotifierProvider.family<LocalGameNotifier, GameNotifierState, String>((
      ref,
      gameId,
    ) {
      final service = ref.read(localGameServiceProvider);
      final animController = ref.read(gameAnimationProvider(gameId));
      final feedbackService = ref.read(gameFeedbackServiceProvider(gameId));
      final auth = ref.read(authProvider);
      return LocalGameNotifier(
        gameId: gameId,
        service: service,
        playerId: auth.userId ?? 'local_player',
        animationController: animController,
        feedbackService: feedbackService,
        getAiDelay: () {
          final settings = ref.read(settingsProvider);
          return settings.scaleDuration(AppConstants.aiThinkingDelay);
        },
      );
    });
