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
  static const String puzzlePickDiscardsKey = 'puzzle_pick_discards';
  static const String opponentHandDisplayKey = 'opponent_hand_display';

  // Card dimensions
  static const double cardAspectRatio = 2.5 / 3.5;

  // Animation durations
  static const Duration scorePopupDuration = Duration(milliseconds: 1800);
  static const Duration scorePopupExtraDuration = Duration(milliseconds: 500);
  static const Duration stageTransitionDuration = Duration(milliseconds: 400);

  /// Beat before the engine's first move, and between each of its moves —
  /// long enough to read the card that just landed.
  static const Duration aiThinkingDelay = Duration(milliseconds: 750);

  /// Added on top when the move that just happened scored, so the "+N" pill
  /// gets read before the next card lands on it.
  static const Duration aiScorePause = Duration(milliseconds: 650);

  /// The engine's discards and cut aren't moves to read one at a time, so
  /// setting up a round keeps moving.
  static const Duration aiSetupDelay = Duration(milliseconds: 260);

  /// Held on the final pegging play before the count takes over, so the last
  /// card and count register before the pile clears.
  static const Duration peggingEndPause = Duration(milliseconds: 500);

  /// Gap between two score pills that queued up behind each other.
  static const Duration scorePopupGap = Duration(milliseconds: 450);
}
