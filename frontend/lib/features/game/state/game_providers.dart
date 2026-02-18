import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/rest_client.dart';
import '../../../core/api/websocket_client.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/card.dart';
import '../../../core/models/game_action.dart';
import '../../../core/models/game_state.dart';

// WebSocket client singleton
final webSocketClientProvider = Provider<WebSocketClient>((ref) {
  return WebSocketClient(authService: ref.read(authServiceProvider));
});

// Game state
class GameNotifierState {
  final GameState? gameState;
  final bool isLoading;
  final String? error;

  const GameNotifierState({
    this.gameState,
    this.isLoading = false,
    this.error,
  });

  GameNotifierState copyWith({
    GameState? gameState,
    bool? isLoading,
    String? error,
  }) {
    return GameNotifierState(
      gameState: gameState ?? this.gameState,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class GameNotifier extends StateNotifier<GameNotifierState> {
  final String gameId;
  final RestClient _restClient;
  final WebSocketClient _wsClient;
  final String _playerId;

  GameNotifier({
    required this.gameId,
    required RestClient restClient,
    required WebSocketClient wsClient,
    required String playerId,
  })  : _restClient = restClient,
        _wsClient = wsClient,
        _playerId = playerId,
        super(const GameNotifierState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    await _loadGameState();
    _connectWebSocket();
  }

  Future<void> _loadGameState() async {
    try {
      final gameState = await _restClient.getGameState(gameId);
      state = GameNotifierState(gameState: gameState);
    } catch (e) {
      state = GameNotifierState(error: 'Failed to load game: $e');
    }
  }

  void _connectWebSocket() {
    if (_wsClient.isConnected) {
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

  void _subscribeToGame() {
    _wsClient.subscribeToGame(
      gameId,
      onStateUpdate: (newState) {
        state = GameNotifierState(gameState: newState);
      },
    );
    _wsClient.subscribeToUserState(
      onStateUpdate: (newState) {
        if (newState.gameId == gameId) {
          state = GameNotifierState(gameState: newState);
        }
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

  Future<void> discardCard(PlayingCard card) async {
    state = state.copyWith(error: null);
    try {
      final newState = await _restClient.applyAction(
        gameId,
        GameAction.discardToCrib(playerId: _playerId, card: card),
      );
      state = GameNotifierState(gameState: newState);
    } catch (e) {
      state = state.copyWith(error: 'Discard failed: $e');
    }
  }

  Future<void> playCard(PlayingCard card) async {
    state = state.copyWith(error: null);
    try {
      final newState = await _restClient.applyAction(
        gameId,
        GameAction.playCard(playerId: _playerId, card: card),
      );
      state = GameNotifierState(gameState: newState);
    } catch (e) {
      state = state.copyWith(error: 'Play card failed: $e');
    }
  }

  Future<void> cutDeck() async {
    state = state.copyWith(error: null);
    try {
      final newState = await _restClient.applyAction(
        gameId,
        GameAction.cutDeck(playerId: _playerId),
      );
      state = GameNotifierState(gameState: newState);
    } catch (e) {
      state = state.copyWith(error: 'Cut failed: $e');
    }
  }

  Future<void> sayGo() async {
    state = state.copyWith(error: null);
    try {
      final newState = await _restClient.applyAction(
        gameId,
        GameAction.go(playerId: _playerId),
      );
      state = GameNotifierState(gameState: newState);
    } catch (e) {
      state = state.copyWith(error: 'Go failed: $e');
    }
  }

  Future<void> countHand() async {
    state = state.copyWith(error: null);
    try {
      final newState = await _restClient.applyAction(
        gameId,
        GameAction.countHand(playerId: _playerId),
      );
      state = GameNotifierState(gameState: newState);
    } catch (e) {
      state = state.copyWith(error: 'Count failed: $e');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _wsClient.leaveGame(gameId);
    _wsClient.unsubscribeFromGame(gameId);
    super.dispose();
  }
}

final gameNotifierProvider =
    StateNotifierProvider.family<GameNotifier, GameNotifierState, String>(
  (ref, gameId) {
    final auth = ref.read(authProvider);
    return GameNotifier(
      gameId: gameId,
      restClient: ref.read(restClientProvider),
      wsClient: ref.read(webSocketClientProvider),
      playerId: auth.userId ?? '',
    );
  },
);

// Track selected cards during discard phase
final selectedCardsProvider =
    StateProvider.family<Set<int>, String>((ref, gameId) => {});
