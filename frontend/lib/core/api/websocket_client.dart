import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../config/constants.dart';
import '../auth/auth_service.dart';
import '../models/game_action.dart';
import '../models/game_state.dart';
import '../models/websocket_messages.dart';

enum ConnectionStatus { disconnected, connecting, connected, reconnecting, failed }

class WebSocketClient {
  final AuthService _authService;
  StompClient? _stompClient;
  final Map<String, StompUnsubscribe> _subscriptions = {};

  // Reconnection state
  ConnectionStatus _status = ConnectionStatus.disconnected;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _maxBackoff = Duration(seconds: 30);

  // Track subscription details for re-subscribe after reconnect
  final Map<String, _SubscriptionInfo> _pendingSubscriptions = {};

  // Callbacks
  void Function()? _onConnectCallback;
  void Function(StompFrame)? _onErrorCallback;
  void Function(ConnectionStatus)? onStatusChange;

  WebSocketClient({required AuthService authService})
      : _authService = authService;

  ConnectionStatus get status => _status;
  bool get isConnected => _stompClient?.connected ?? false;

  void _setStatus(ConnectionStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      onStatusChange?.call(newStatus);
    }
  }

  Future<void> connect({
    required void Function() onConnect,
    required void Function(StompFrame) onError,
    void Function(dynamic)? onDisconnect,
  }) async {
    if (isConnected) return;

    _onConnectCallback = onConnect;
    _onErrorCallback = onError;
    _reconnectAttempts = 0;
    _setStatus(ConnectionStatus.connecting);

    await _doConnect(onConnect: onConnect, onError: onError);
  }

  Future<void> _doConnect({
    required void Function() onConnect,
    required void Function(StompFrame) onError,
  }) async {
    final token = await _authService.getToken();

    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: AppConstants.wsUrl,
        stompConnectHeaders: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
        onConnect: (frame) {
          _reconnectAttempts = 0;
          _setStatus(ConnectionStatus.connected);
          // Re-subscribe to all tracked subscriptions
          _resubscribeAll();
          onConnect();
        },
        onStompError: (frame) {
          onError(frame);
        },
        onWebSocketError: (error) {
          _handleDisconnect();
        },
        onDisconnect: (frame) {
          _handleDisconnect();
        },
      ),
    );

    _stompClient!.activate();
  }

  void _handleDisconnect() {
    // Clear active subscriptions (connection is gone)
    _subscriptions.clear();

    if (_status == ConnectionStatus.disconnected ||
        _status == ConnectionStatus.failed) {
      return; // Intentional disconnect or already gave up
    }

    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _setStatus(ConnectionStatus.failed);
      return;
    }

    _setStatus(ConnectionStatus.reconnecting);
    _reconnectAttempts++;

    // Exponential backoff: 1s, 2s, 4s, 8s, 16s, 30s, 30s...
    final delaySeconds = (1 << (_reconnectAttempts - 1)).clamp(1, _maxBackoff.inSeconds);
    final delay = Duration(seconds: delaySeconds);

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_status == ConnectionStatus.reconnecting) {
        _doConnect(
          onConnect: _onConnectCallback ?? () {},
          onError: _onErrorCallback ?? (_) {},
        );
      }
    });
  }

  void _resubscribeAll() {
    for (final entry in _pendingSubscriptions.entries) {
      final info = entry.value;
      _subscriptions[entry.key] = _stompClient!.subscribe(
        destination: info.destination,
        callback: info.callback,
      );
    }
  }

  void subscribeToGame(
    String gameId, {
    required void Function(GameState) onStateUpdate,
  }) {
    final key = 'game-$gameId';
    _subscriptions[key]?.call(unsubscribeHeaders: {});

    void callback(StompFrame frame) {
      if (frame.body == null) return;
      final json = jsonDecode(frame.body!) as Map<String, dynamic>;
      final message = GameStateUpdateMessage.fromJson(json);
      onStateUpdate(message.gameState);
    }

    _pendingSubscriptions[key] = _SubscriptionInfo(
      '/topic/game/$gameId',
      callback,
    );

    if (isConnected) {
      _subscriptions[key] = _stompClient!.subscribe(
        destination: '/topic/game/$gameId',
        callback: callback,
      );
    }
  }

  void subscribeToUserState({
    required void Function(GameState) onStateUpdate,
  }) {
    _subscriptions['user-state']?.call(unsubscribeHeaders: {});

    void callback(StompFrame frame) {
      if (frame.body == null) return;
      final json = jsonDecode(frame.body!) as Map<String, dynamic>;
      final message = GameStateUpdateMessage.fromJson(json);
      onStateUpdate(message.gameState);
    }

    _pendingSubscriptions['user-state'] = _SubscriptionInfo(
      '/user/queue/game-state',
      callback,
    );

    if (isConnected) {
      _subscriptions['user-state'] = _stompClient!.subscribe(
        destination: '/user/queue/game-state',
        callback: callback,
      );
    }
  }

  void subscribeToErrors({
    required void Function(GameErrorMessage) onError,
  }) {
    _subscriptions['user-errors']?.call(unsubscribeHeaders: {});

    void callback(StompFrame frame) {
      if (frame.body == null) return;
      final json = jsonDecode(frame.body!) as Map<String, dynamic>;
      onError(GameErrorMessage.fromJson(json));
    }

    _pendingSubscriptions['user-errors'] = _SubscriptionInfo(
      '/user/queue/errors',
      callback,
    );

    if (isConnected) {
      _subscriptions['user-errors'] = _stompClient!.subscribe(
        destination: '/user/queue/errors',
        callback: callback,
      );
    }
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
    _pendingSubscriptions.remove(key);
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    _setStatus(ConnectionStatus.disconnected);

    for (final unsub in _subscriptions.values) {
      unsub(unsubscribeHeaders: {});
    }
    _subscriptions.clear();
    _pendingSubscriptions.clear();
    _stompClient?.deactivate();
    _stompClient = null;
  }
}

class _SubscriptionInfo {
  final String destination;
  final void Function(StompFrame) callback;

  _SubscriptionInfo(this.destination, this.callback);
}
