import '../../config/constants.dart';

/// Responsive card sizing based on screen width.
/// Use via LayoutBuilder or MediaQuery to get the available width.
class CardDimensions {
  final double screenWidth;

  /// Cap at 500px to prevent oversized cards on wide screens (desktop browsers).
  CardDimensions(double width) : screenWidth = width.clamp(0.0, 500.0);

  /// Tablet constructor: clamps at 800px for wider landscape panels.
  CardDimensions.tablet(double width) : screenWidth = width.clamp(0.0, 800.0);

  // Hand cards: ~25% screen width
  double get handCardWidth => screenWidth * 0.25;

  // Play/cut/crib cards: 85% of hand card size
  double get playCardWidth => handCardWidth * 0.85;
  double get playCardHeight => playCardWidth / AppConstants.cardAspectRatio;

  // Opponent/crib cards (face-down): ~14% screen width
  double get smallCardWidth => screenWidth * 0.14;

  // Overlap ratios
  double get playOverlap => 0.50; // 50% overlap for play area
  double get opponentOverlap => 0.60; // 60% overlap for opponent
  double get cribOverlap => 0.55; // 55% overlap for crib

  // Visible width of each overlapping card (except the last)
  double get playCardVisible => playCardWidth * (1 - playOverlap);
  double get cribCardVisible => playCardWidth * (1 - cribOverlap);

  // Total width of an overlapping stack of n cards
  double playStackWidth(int n) =>
      n <= 0 ? 0 : playCardWidth + (n - 1) * playCardVisible;
  double cribStackWidth(int n) =>
      n <= 0 ? 0 : playCardWidth + (n - 1) * cribCardVisible;
}
