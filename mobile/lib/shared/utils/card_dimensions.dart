import '../../config/constants.dart';

/// Responsive card sizing based on screen width.
/// Use via LayoutBuilder or MediaQuery to get the available width.
class CardDimensions {
  final double screenWidth;

  /// Cap at 500px to prevent oversized cards on wide screens (desktop browsers).
  CardDimensions(double width) : screenWidth = width.clamp(0.0, 500.0);

  // Hand cards: ~22% screen width
  double get handCardWidth => screenWidth * 0.22;
  double get handCardHeight => handCardWidth / AppConstants.cardAspectRatio;

  // Play/cut/crib cards: 85% of hand card size
  double get playCardWidth => handCardWidth * 0.85;
  double get playCardHeight => playCardWidth / AppConstants.cardAspectRatio;

  // Opponent/crib cards (face-down): ~14% screen width
  double get smallCardWidth => screenWidth * 0.14;
  double get smallCardHeight => smallCardWidth / AppConstants.cardAspectRatio;

  // Overlap ratios
  double get playOverlap => 0.50; // 50% overlap for play area
  double get opponentOverlap => 0.60; // 60% overlap for opponent
  double get cribOverlap => 0.55; // 55% overlap for crib

  /// Adaptive hand overlap based on card count and available width.
  /// Spreads cards to fill available space, clamped between 25%-50% overlap.
  double handOverlapForCount(int cardCount, double availableWidth) {
    if (cardCount <= 1) return 0.0;
    // How much overlap is needed to fit all cards in the available width:
    // stackWidth = cardWidth + (n-1) * cardWidth * (1 - overlap) = availableWidth
    // => (1 - overlap) = (availableWidth - cardWidth) / ((n-1) * cardWidth)
    // => overlap = 1 - (availableWidth - cardWidth) / ((n-1) * cardWidth)
    final needed =
        1.0 - (availableWidth - handCardWidth) / ((cardCount - 1) * handCardWidth);
    return needed.clamp(0.25, 0.50);
  }

  // Visible width of each overlapping card (except the last)
  double handCardVisibleForCount(int cardCount, double availableWidth) =>
      handCardWidth * (1 - handOverlapForCount(cardCount, availableWidth));
  double get playCardVisible => playCardWidth * (1 - playOverlap);
  double get opponentCardVisible => smallCardWidth * (1 - opponentOverlap);
  double get cribCardVisible => playCardWidth * (1 - cribOverlap);

  // Total width of an overlapping stack of n cards
  double handStackWidthForCount(int n, double availableWidth) =>
      n <= 0 ? 0 : handCardWidth + (n - 1) * handCardVisibleForCount(n, availableWidth);
  double playStackWidth(int n) =>
      n <= 0 ? 0 : playCardWidth + (n - 1) * playCardVisible;
  double opponentStackWidth(int n) =>
      n <= 0 ? 0 : smallCardWidth + (n - 1) * opponentCardVisible;
  double cribStackWidth(int n) =>
      n <= 0 ? 0 : playCardWidth + (n - 1) * cribCardVisible;
}
