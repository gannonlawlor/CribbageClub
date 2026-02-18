class AppConstants {
  AppConstants._();

  // API
  static const String apiBaseUrl = 'http://localhost:8080';
  static const String wsUrl = '$apiBaseUrl/ws';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Game
  static const int winningScore = 121;
  static const int maxHandSize = 6;
  static const int discardCount = 2;
  static const int peggingMax = 31;

  // Storage keys
  static const String tokenKey = 'jwt_token';
  static const String userIdKey = 'user_id';
  static const String usernameKey = 'username';
  static const String isGuestKey = 'is_guest';
}
