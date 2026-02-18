import 'package:freezed_annotation/freezed_annotation.dart';
import 'card.dart';

part 'game_action.freezed.dart';
part 'game_action.g.dart';

@Freezed(unionKey: 'type')
sealed class GameAction with _$GameAction {
  @FreezedUnionValue('DiscardToCrib')
  const factory GameAction.discardToCrib({
    required String playerId,
    required PlayingCard card,
  }) = DiscardToCrib;

  @FreezedUnionValue('PlayCard')
  const factory GameAction.playCard({
    required String playerId,
    required PlayingCard card,
  }) = PlayCard;

  @FreezedUnionValue('CutDeck')
  const factory GameAction.cutDeck({required String playerId}) = CutDeck;

  @FreezedUnionValue('Go')
  const factory GameAction.go({required String playerId}) = Go;

  @FreezedUnionValue('CountHand')
  const factory GameAction.countHand({required String playerId}) = CountHand;

  factory GameAction.fromJson(Map<String, dynamic> json) =>
      _$GameActionFromJson(json);
}
