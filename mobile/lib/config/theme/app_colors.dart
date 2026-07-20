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

  // Ratings — gold is reserved for skill (ratings, trophies), never actions
  final Color ratingGold;

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
    required this.ratingGold,
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

  /// Design Language v1.0 — light theme ("warm paper" mapping, spec §9).
  /// Card faces, backs, and pegs are identical in both themes.
  static const classicLight = AppColors(
    scaffoldBg: Color(0xFFF4F1EC), // --surface-1 (page)
    gameGradientTop: Color(0xFFF4F1EC),
    gameGradientMid: Color(0xFFF4F1EC),
    gameGradientBottom: Color(0xFFF4F1EC),
    surfacePrimary: Color(0xFFFFFFFF), // --surface-2 (panels)
    surfaceDim: Color(0xFFEAE6E0), // --surface-0 (chrome)
    cardFace: Color(0xFFF5F0E8), // --card-face
    cardBackPrimary: Color(0xFF4A5568), // --card-back (cool slate)
    cardBackSecondary: Color(0xFF3F4757),
    cardBackDetail: Color(0x12FFFFFF), // white @ 7% (45° hairline stripes)
    suitRed: Color(0xFFC0392B), // --card-red
    suitBlack: Color(0xFF1A1A1A), // --card-black
    selectedBorder: Color(0xFF81B64C), // --green-500 (ring needs contrast on paper)
    boardPrimary: Color(0xFFECE7DF), // --board
    boardSecondary: Color(0x12000000), // --board-track: black @ 7%
    boardHole: Color(0xFFD8D2C8), // --board-hole
    pegPlayer: Color(0xFF81B64C), // --player-self
    pegOpponent: Color(0xFFA49C90), // --player-opp (ivory would vanish on paper)
    textPrimary: Color(0xFF2A2622), // --text-1
    textSecondary: Color(0xFF57524B), // --text-2
    textTertiary: Color(0xFF767066), // --text-3
    textDisabled: Color(0xFFA8A29A), // --text-faint
    accent: Color(0xFF81B64C), // --green-500 (theme-invariant CTA)
    accentOnSurface: Color(0xFF16240C), // --on-green
    buttonPrimary: Color(0xFF81B64C),
    success: Color(0xFF4E7A2E), // --win (green as text on paper)
    error: Color(0xFFB6362A), // --loss
    warning: Color(0xFFB25A17), // --streak
    evOptimal: Color(0xFF4E7A2E),
    evGood: Color(0xFFB25A17),
    evPoor: Color(0xFFB6362A),
    highlight: Color(0xFF3B6EA5), // muted blue
    streak: Color(0xFFB25A17),
    medalGold: Color(0xFF9A7514), // --gold (light)
    medalSilver: Color(0xFFC0C0C0),
    medalBronze: Color(0xFFCD7F32),
    ratingGold: Color(0xFF9A7514), // --gold — ratings/trophies only
  );

  /// Design Language v1.0 — dark theme (primary, spec §2).
  static const classicDark = AppColors(
    scaffoldBg: Color(0xFF312E2B), // --surface-1 (page)
    gameGradientTop: Color(0xFF262421), // --surface-0
    gameGradientMid: Color(0xFF312E2B), // --surface-1
    gameGradientBottom: Color(0xFF262421), // --surface-0
    surfacePrimary: Color(0xFF3C3936), // --surface-2 (panels)
    surfaceDim: Color(0xFF47433F), // --surface-3 (hover/raised)
    cardFace: Color(0xFFF5F0E8), // --card-face
    cardBackPrimary: Color(0xFF4A5568), // --card-back (cool slate)
    cardBackSecondary: Color(0xFF3F4757),
    cardBackDetail: Color(0x12FFFFFF), // white @ 7% (45° hairline stripes)
    suitRed: Color(0xFFC0392B), // --card-red
    suitBlack: Color(0xFF1A1A1A), // --card-black (on card face)
    selectedBorder: Color(0xFFA4D372), // --green-300 (selection ring)
    boardPrimary: Color(0xFF38342F), // --board (flattened, 2 steps warmer)
    boardSecondary: Color(0xFF2F2C28), // recessed track step
    boardHole: Color(0xFF211F1D), // --board-hole
    pegPlayer: Color(0xFF81B64C), // --player-self
    pegOpponent: Color(0xFFD9D4CC), // --player-opp (card-stock ivory)
    textPrimary: Color(0xFFF0EDE8), // --text-1
    textSecondary: Color(0xFFB8B3AC), // --text-2
    textTertiary: Color(0xFF9C968E), // --text-3
    textDisabled: Color(0xFF6B6660), // --text-faint
    accent: Color(0xFF81B64C), // --green-500 — green means "act"
    accentOnSurface: Color(0xFF16240C), // --on-green
    buttonPrimary: Color(0xFF81B64C),
    success: Color(0xFF81B64C), // --win
    error: Color(0xFFE5766D), // --loss
    warning: Color(0xFFE2833F), // --streak
    evOptimal: Color(0xFF81B64C),
    evGood: Color(0xFFE2833F),
    evPoor: Color(0xFFE5766D),
    highlight: Color(0xFF7EA6D9), // muted blue
    streak: Color(0xFFE2833F),
    medalGold: Color(0xFFE3AA24), // --gold (dark)
    medalSilver: Color(0xFFC0C0C0),
    medalBronze: Color(0xFFCD7F32),
    ratingGold: Color(0xFFE3AA24), // --gold — ratings/trophies only
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
    Color? ratingGold,
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
      ratingGold: ratingGold ?? this.ratingGold,
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
      ratingGold: Color.lerp(ratingGold, other.ratingGold, t)!,
    );
  }
}

/// Convenience extension on [BuildContext].
extension AppColorsExtension on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
