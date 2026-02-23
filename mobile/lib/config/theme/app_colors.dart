import 'package:flutter/material.dart';

/// Semantic color palette for the app, registered as a [ThemeExtension].
/// Access via `context.appColors`.
class AppColors extends ThemeExtension<AppColors> {
  // Background
  final Color scaffoldBg;
  final Color gameGradientTop;
  final Color gameGradientMid;
  final Color gameGradientBottom;

  // Surface
  final Color surfacePrimary;
  final Color surfaceDim;

  // Cards
  final Color cardFace;
  final Color cardBackPrimary;
  final Color cardBackSecondary;
  final Color cardBackDetail;
  final Color suitRed;
  final Color suitBlack;
  final Color selectedBorder;

  // Board
  final Color boardPrimary;
  final Color boardSecondary;
  final Color boardHole;
  final Color pegPlayer;
  final Color pegOpponent;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;

  // Interactive
  final Color accent;
  final Color accentOnSurface;
  final Color buttonPrimary;

  // Status
  final Color success;
  final Color error;
  final Color warning;

  // EV analysis
  final Color evOptimal;
  final Color evGood;
  final Color evPoor;
  final Color highlight;
  final Color streak;

  // Medals
  final Color medalGold;
  final Color medalSilver;
  final Color medalBronze;

  const AppColors({
    required this.scaffoldBg,
    required this.gameGradientTop,
    required this.gameGradientMid,
    required this.gameGradientBottom,
    required this.surfacePrimary,
    required this.surfaceDim,
    required this.cardFace,
    required this.cardBackPrimary,
    required this.cardBackSecondary,
    required this.cardBackDetail,
    required this.suitRed,
    required this.suitBlack,
    required this.selectedBorder,
    required this.boardPrimary,
    required this.boardSecondary,
    required this.boardHole,
    required this.pegPlayer,
    required this.pegOpponent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.accent,
    required this.accentOnSurface,
    required this.buttonPrimary,
    required this.success,
    required this.error,
    required this.warning,
    required this.evOptimal,
    required this.evGood,
    required this.evPoor,
    required this.highlight,
    required this.streak,
    required this.medalGold,
    required this.medalSilver,
    required this.medalBronze,
  });

  // ── Computed getters ──────────────────────────────────────

  Color get selectedGlow => accent.withValues(alpha: 0.5);
  Color get accentSubtle => accent.withValues(alpha: 0.2);
  Color get accentBorder => accent.withValues(alpha: 0.5);
  Color get scrim => Colors.black54;
  Color get divider => textDisabled.withValues(alpha: 0.3);

  LinearGradient get gameGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [gameGradientTop, gameGradientMid, gameGradientBottom],
        stops: const [0.0, 0.5, 1.0],
      );

  // ── Theme variants ────────────────────────────────────────

  static const classicLight = AppColors(
    scaffoldBg: Color(0xFFF0F1F5),
    gameGradientTop: Color(0xFFECEDF1),
    gameGradientMid: Color(0xFFECEDF1),
    gameGradientBottom: Color(0xFFECEDF1),
    surfacePrimary: Color(0xFFFFFFFF),
    surfaceDim: Color(0xFFE8E9ED),
    cardFace: Color(0xFFFFFFFF),
    cardBackPrimary: Color(0xFF3D4559),
    cardBackSecondary: Color(0xFF2D3346),
    cardBackDetail: Color(0x2EFFFFFF), // white @ 0.18
    suitRed: Color(0xFFC85A5A),
    suitBlack: Color(0xFF2D3142),
    selectedBorder: Color(0xFF3D4559),
    boardPrimary: Color(0xFF8D6E63),
    boardSecondary: Color(0xFF6D4C41),
    boardHole: Color(0xFF4E342E),
    pegPlayer: Color(0xFF3D4559),
    pegOpponent: Color(0xFF9E9E9E),
    textPrimary: Color(0xFF1E2130),
    textSecondary: Color(0xFF6B7085),
    textTertiary: Color(0xFF9498AB),
    textDisabled: Color(0xFFB8BCCA),
    accent: Color(0xFF3D4559),
    accentOnSurface: Color(0xFFFFFFFF),
    buttonPrimary: Color(0xFF3D4559),
    success: Color(0xFF2E7D32),
    error: Color(0xFFC62828),
    warning: Color(0xFFE65100),
    evOptimal: Color(0xFF2E7D32),
    evGood: Color(0xFFE65100),
    evPoor: Color(0xFFC62828),
    highlight: Color(0xFF1565C0),
    streak: Color(0xFFE65100),
    medalGold: Color(0xFFFFD700),
    medalSilver: Color(0xFFC0C0C0),
    medalBronze: Color(0xFFCD7F32),
  );

  static const classicDark = AppColors(
    scaffoldBg: Color(0xFF111116),
    gameGradientTop: Color(0xFF111116),
    gameGradientMid: Color(0xFF181820),
    gameGradientBottom: Color(0xFF111116),
    surfacePrimary: Color(0xFF1A1A22),
    surfaceDim: Color(0x14FFFFFF), // white @ 8%
    cardFace: Color(0xFFFAFAF5),
    cardBackPrimary: Color(0xFF2B3A58),
    cardBackSecondary: Color(0xFF1D2940),
    cardBackDetail: Color(0x1FFFFFFF), // white @ 12%
    suitRed: Color(0xFFE54B4B),
    suitBlack: Color(0xFFC8C8D0),
    selectedBorder: Color(0xFFD4A843),
    boardPrimary: Color(0xFF795548),
    boardSecondary: Color(0xFF5D4037),
    boardHole: Color(0xFF3E2723),
    pegPlayer: Color(0xFFD4A843),
    pegOpponent: Color(0xFFB0B0B8),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xB3FFFFFF), // white70
    textTertiary: Color(0x8AFFFFFF), // white54
    textDisabled: Color(0x61FFFFFF), // white38
    accent: Color(0xFFD4A843),
    accentOnSurface: Color(0xFF111116),
    buttonPrimary: Color(0xFFD4A843),
    success: Color(0xFF4ADE80),
    error: Color(0xFFF87171),
    warning: Color(0xFFFBBF24),
    evOptimal: Color(0xFF4ADE80),
    evGood: Color(0xFFFB923C),
    evPoor: Color(0xFFF87171),
    highlight: Color(0xFF60A5FA),
    streak: Color(0xFFFB923C),
    medalGold: Color(0xFFFFD700),
    medalSilver: Color(0xFFC0C0C0),
    medalBronze: Color(0xFFCD7F32),
  );

  // ── ThemeExtension overrides ──────────────────────────────

  @override
  AppColors copyWith({
    Color? scaffoldBg,
    Color? gameGradientTop,
    Color? gameGradientMid,
    Color? gameGradientBottom,
    Color? surfacePrimary,
    Color? surfaceDim,
    Color? cardFace,
    Color? cardBackPrimary,
    Color? cardBackSecondary,
    Color? cardBackDetail,
    Color? suitRed,
    Color? suitBlack,
    Color? selectedBorder,
    Color? boardPrimary,
    Color? boardSecondary,
    Color? boardHole,
    Color? pegPlayer,
    Color? pegOpponent,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? accent,
    Color? accentOnSurface,
    Color? buttonPrimary,
    Color? success,
    Color? error,
    Color? warning,
    Color? evOptimal,
    Color? evGood,
    Color? evPoor,
    Color? highlight,
    Color? streak,
    Color? medalGold,
    Color? medalSilver,
    Color? medalBronze,
  }) {
    return AppColors(
      scaffoldBg: scaffoldBg ?? this.scaffoldBg,
      gameGradientTop: gameGradientTop ?? this.gameGradientTop,
      gameGradientMid: gameGradientMid ?? this.gameGradientMid,
      gameGradientBottom: gameGradientBottom ?? this.gameGradientBottom,
      surfacePrimary: surfacePrimary ?? this.surfacePrimary,
      surfaceDim: surfaceDim ?? this.surfaceDim,
      cardFace: cardFace ?? this.cardFace,
      cardBackPrimary: cardBackPrimary ?? this.cardBackPrimary,
      cardBackSecondary: cardBackSecondary ?? this.cardBackSecondary,
      cardBackDetail: cardBackDetail ?? this.cardBackDetail,
      suitRed: suitRed ?? this.suitRed,
      suitBlack: suitBlack ?? this.suitBlack,
      selectedBorder: selectedBorder ?? this.selectedBorder,
      boardPrimary: boardPrimary ?? this.boardPrimary,
      boardSecondary: boardSecondary ?? this.boardSecondary,
      boardHole: boardHole ?? this.boardHole,
      pegPlayer: pegPlayer ?? this.pegPlayer,
      pegOpponent: pegOpponent ?? this.pegOpponent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      accent: accent ?? this.accent,
      accentOnSurface: accentOnSurface ?? this.accentOnSurface,
      buttonPrimary: buttonPrimary ?? this.buttonPrimary,
      success: success ?? this.success,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      evOptimal: evOptimal ?? this.evOptimal,
      evGood: evGood ?? this.evGood,
      evPoor: evPoor ?? this.evPoor,
      highlight: highlight ?? this.highlight,
      streak: streak ?? this.streak,
      medalGold: medalGold ?? this.medalGold,
      medalSilver: medalSilver ?? this.medalSilver,
      medalBronze: medalBronze ?? this.medalBronze,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      scaffoldBg: Color.lerp(scaffoldBg, other.scaffoldBg, t)!,
      gameGradientTop: Color.lerp(gameGradientTop, other.gameGradientTop, t)!,
      gameGradientMid: Color.lerp(gameGradientMid, other.gameGradientMid, t)!,
      gameGradientBottom:
          Color.lerp(gameGradientBottom, other.gameGradientBottom, t)!,
      surfacePrimary: Color.lerp(surfacePrimary, other.surfacePrimary, t)!,
      surfaceDim: Color.lerp(surfaceDim, other.surfaceDim, t)!,
      cardFace: Color.lerp(cardFace, other.cardFace, t)!,
      cardBackPrimary: Color.lerp(cardBackPrimary, other.cardBackPrimary, t)!,
      cardBackSecondary:
          Color.lerp(cardBackSecondary, other.cardBackSecondary, t)!,
      cardBackDetail: Color.lerp(cardBackDetail, other.cardBackDetail, t)!,
      suitRed: Color.lerp(suitRed, other.suitRed, t)!,
      suitBlack: Color.lerp(suitBlack, other.suitBlack, t)!,
      selectedBorder: Color.lerp(selectedBorder, other.selectedBorder, t)!,
      boardPrimary: Color.lerp(boardPrimary, other.boardPrimary, t)!,
      boardSecondary: Color.lerp(boardSecondary, other.boardSecondary, t)!,
      boardHole: Color.lerp(boardHole, other.boardHole, t)!,
      pegPlayer: Color.lerp(pegPlayer, other.pegPlayer, t)!,
      pegOpponent: Color.lerp(pegOpponent, other.pegOpponent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentOnSurface: Color.lerp(accentOnSurface, other.accentOnSurface, t)!,
      buttonPrimary: Color.lerp(buttonPrimary, other.buttonPrimary, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      evOptimal: Color.lerp(evOptimal, other.evOptimal, t)!,
      evGood: Color.lerp(evGood, other.evGood, t)!,
      evPoor: Color.lerp(evPoor, other.evPoor, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      streak: Color.lerp(streak, other.streak, t)!,
      medalGold: Color.lerp(medalGold, other.medalGold, t)!,
      medalSilver: Color.lerp(medalSilver, other.medalSilver, t)!,
      medalBronze: Color.lerp(medalBronze, other.medalBronze, t)!,
    );
  }
}

/// Convenience extension on [BuildContext].
extension AppColorsExtension on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
