class AppConstants {
  AppConstants._();

  // API
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
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
  static const String soundEnabledKey = 'sound_enabled';
  static const String hapticsEnabledKey = 'haptics_enabled';
  static const String themeModeKey = 'theme_mode';
  static const String autoDealKey = 'auto_deal';
  static const String autoCutKey = 'auto_cut';
  static const String autoGoKey = 'auto_go';
  static const String autoPlayAllKey = 'auto_play_all';
  static const String autoPlayPeggingKey = 'auto_play_pegging';
  static const String animationSpeedKey = 'animation_speed';

  // Card dimensions
  static const double cardAspectRatio = 2.5 / 3.5;

  // Animation durations
  static const Duration cardFlipDuration = Duration(milliseconds: 400);
  static const Duration cardDealDuration = Duration(milliseconds: 300);
  static const Duration cardPlayDuration = Duration(milliseconds: 250);
  static const Duration scalBounceDuration = Duration(milliseconds: 200);
  static const Duration cribStaggerDelay = Duration(milliseconds: 100);
  static const Duration pegMovePerHole = Duration(milliseconds: 50);
  static const Duration scorePopupDuration = Duration(milliseconds: 1800);
  static const Duration stageTransitionDuration = Duration(milliseconds: 400);
  static const Duration aiThinkingDelay = Duration(milliseconds: 200);
}
