import '../../config/theme.dart';

/// Responsive card sizing based on screen width.
/// Use via LayoutBuilder or MediaQuery to get the available width.
class CardDimensions {
  final double screenWidth;

  CardDimensions(this.screenWidth);

  // Hand cards: ~18% screen width
  double get handCardWidth => screenWidth * 0.18;
  double get handCardHeight => handCardWidth / AppTheme.cardAspectRatio;

  // Play/cut/crib cards: 85% of hand card size
  double get playCardWidth => handCardWidth * 0.85;
  double get playCardHeight => playCardWidth / AppTheme.cardAspectRatio;

  // Opponent/crib cards (face-down): ~11% screen width
  double get smallCardWidth => screenWidth * 0.11;
  double get smallCardHeight => smallCardWidth / AppTheme.cardAspectRatio;

  // Overlap ratios
  double get handOverlap => 0.55; // 55% overlap for hand
  double get playOverlap => 0.50; // 50% overlap for play area
  double get opponentOverlap => 0.60; // 60% overlap for opponent
  double get cribOverlap => 0.55; // 55% overlap for crib

  // Visible width of each overlapping card (except the last)
  double get handCardVisible => handCardWidth * (1 - handOverlap);
  double get playCardVisible => playCardWidth * (1 - playOverlap);
  double get opponentCardVisible => smallCardWidth * (1 - opponentOverlap);
  double get cribCardVisible => playCardWidth * (1 - cribOverlap);

  // Total width of an overlapping stack of n cards
  double handStackWidth(int n) =>
      n <= 0 ? 0 : handCardWidth + (n - 1) * handCardVisible;
  double playStackWidth(int n) =>
      n <= 0 ? 0 : playCardWidth + (n - 1) * playCardVisible;
  double opponentStackWidth(int n) =>
      n <= 0 ? 0 : smallCardWidth + (n - 1) * opponentCardVisible;
  double cribStackWidth(int n) =>
      n <= 0 ? 0 : playCardWidth + (n - 1) * cribCardVisible;
}
