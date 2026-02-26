import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../api/rest_client.dart';

class PushNotificationService {
  final RestClient _restClient;
  final GoRouter Function() _routerGetter;
  String? _currentToken;

  PushNotificationService({
    required RestClient restClient,
    required GoRouter Function() routerGetter,
  })  : _restClient = restClient,
        _routerGetter = routerGetter;

  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    // Request permission (shows dialog on iOS)
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[Push] Permission denied');
      return;
    }

    // Get FCM token and register with backend
    final token = await messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    // Listen for token refresh
    messaging.onTokenRefresh.listen(_registerToken);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification that launched the app from terminated state
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  Future<void> _registerToken(String token) async {
    _currentToken = token;
    final platform = Platform.isIOS ? 'IOS' : 'ANDROID';
    try {
      await _restClient.registerDeviceToken(token, platform);
      debugPrint('[Push] Device token registered');
    } catch (e) {
      debugPrint('[Push] Failed to register device token: $e');
    }
  }

  /// Re-registers the current FCM token with the backend if one exists.
  /// Handles the case where initial registration failed due to no connectivity.
  Future<void> reRegisterTokenIfNeeded() async {
    if (_currentToken != null) {
      await _registerToken(_currentToken!);
    }
  }

  Future<void> unregisterToken() async {
    if (_currentToken != null) {
      try {
        await _restClient.unregisterDeviceToken(_currentToken!);
        debugPrint('[Push] Device token unregistered');
      } catch (e) {
        debugPrint('[Push] Failed to unregister device token: $e');
      }
      _currentToken = null;
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    final router = _routerGetter();

    switch (type) {
      case 'FRIEND_REQUEST':
      case 'CHALLENGE_RECEIVED':
        router.go('/friends');
      case 'GAME_FOUND':
        final gameId = data['gameId'];
        if (gameId != null) {
          router.go('/game/$gameId');
        }
    }
  }
}
