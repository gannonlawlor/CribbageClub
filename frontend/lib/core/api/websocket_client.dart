import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../config/constants.dart';
import '../auth/auth_service.dart';
import '../models/game_action.dart';
import '../models/game_state.dart';
import '../models/websocket_messages.dart';

class WebSocketClient {
  final AuthService _authService;
  StompClient? _stompClient;
  final Map<String, StompUnsubscribe> _subscriptions = {};

  WebSocketClient({required AuthService authService})
      : _authService = authService;

  bool get isConnected => _stompClient?.connected ?? false;

  Future<void> connect({
    required void Function() onConnect,
    required void Function(StompFrame) onError,
    void Function(dynamic)? onDisconnect,
  }) async {
    if (isConnected) return;

    final token = await _authService.getToken();

    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: AppConstants.wsUrl,
        stompConnectHeaders: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
        onConnect: (frame) => onConnect(),
        onStompError: onError,
        onWebSocketError: (error) => onDisconnect?.call(error),
        onDisconnect: (frame) => onDisconnect?.call(frame),
      ),
    );

    _stompClient!.activate();
  }

  void subscribeToGame(
    String gameId, {
    required void Function(GameState) onStateUpdate,
  }) {
    final key = 'game-$gameId';
    _subscriptions[key]?.call(unsubscribeHeaders: {});

    _subscriptions[key] = _stompClient!.subscribe(
      destination: '/topic/game/$gameId',
      callback: (frame) {
        if (frame.body == null) return;
        final json = jsonDecode(frame.body!) as Map<String, dynamic>;
        final message = GameStateUpdateMessage.fromJson(json);
        onStateUpdate(message.gameState);
      },
    );
  }

  void subscribeToUserState({
    required void Function(GameState) onStateUpdate,
  }) {
    _subscriptions['user-state']?.call(unsubscribeHeaders: {});

    _subscriptions['user-state'] = _stompClient!.subscribe(
      destination: '/user/queue/game-state',
      callback: (frame) {
        if (frame.body == null) return;
        final json = jsonDecode(frame.body!) as Map<String, dynamic>;
        final message = GameStateUpdateMessage.fromJson(json);
        onStateUpdate(message.gameState);
      },
    );
  }

  void subscribeToErrors({
    required void Function(GameErrorMessage) onError,
  }) {
    _subscriptions['user-errors']?.call(unsubscribeHeaders: {});

    _subscriptions['user-errors'] = _stompClient!.subscribe(
      destination: '/user/queue/errors',
      callback: (frame) {
        if (frame.body == null) return;
        final json = jsonDecode(frame.body!) as Map<String, dynamic>;
        onError(GameErrorMessage.fromJson(json));
      },
    );
  }

  void sendAction(String gameId, GameAction action) {
    _stompClient?.send(
      destination: '/app/game/action',
      body: jsonEncode(GameActionMessage(
        gameId: gameId,
        action: action,
      ).toJson()),
    );
  }

  void joinGame(String gameId) {
    _stompClient?.send(
      destination: '/app/game/join',
      body: jsonEncode({'gameId': gameId}),
    );
  }

  void leaveGame(String gameId) {
    _stompClient?.send(
      destination: '/app/game/leave',
      body: jsonEncode({'gameId': gameId}),
    );
  }

  void unsubscribeFromGame(String gameId) {
    final key = 'game-$gameId';
    _subscriptions[key]?.call(unsubscribeHeaders: {});
    _subscriptions.remove(key);
  }

  void disconnect() {
    for (final unsub in _subscriptions.values) {
      unsub(unsubscribeHeaders: {});
    }
    _subscriptions.clear();
    _stompClient?.deactivate();
    _stompClient = null;
  }
}
