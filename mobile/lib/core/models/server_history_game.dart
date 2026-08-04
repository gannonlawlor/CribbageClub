import 'game_state.dart';

/// One completed server game plus the viewer's rating outcome.
///
/// The history payload is a GameState's fields with the rating keys flattened
/// alongside (a compatibility shape — older clients parse it as a plain
/// GameState), so this parses the same map twice rather than nesting.
class ServerHistoryGame {
  final GameState gameState;

  /// How much this game moved the viewer's rating. Null for unrated games
  /// and games recorded before rating history existed.
  final double? myRatingDelta;

  /// The opponent's rating as of this game's end. Null when unrated/unknown.
  final double? opponentRating;

  const ServerHistoryGame({
    required this.gameState,
    this.myRatingDelta,
    this.opponentRating,
  });

  factory ServerHistoryGame.fromJson(Map<String, dynamic> json) {
    return ServerHistoryGame(
      gameState: GameState.fromJson(json),
      myRatingDelta: (json['myRatingDelta'] as num?)?.toDouble(),
      opponentRating: (json['opponentRating'] as num?)?.toDouble(),
    );
  }
}
