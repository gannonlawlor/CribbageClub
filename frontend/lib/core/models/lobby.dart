import 'package:freezed_annotation/freezed_annotation.dart';

part 'lobby.freezed.dart';
part 'lobby.g.dart';

enum LobbyStatus {
  @JsonValue('WAITING')
  waiting,
  @JsonValue('IN_GAME')
  inGame,
  @JsonValue('COMPLETED')
  completed,
}

@freezed
class LobbyPlayer with _$LobbyPlayer {
  const factory LobbyPlayer({
    required String id,
    required String name,
    required String joinedAt,
  }) = _LobbyPlayer;

  factory LobbyPlayer.fromJson(Map<String, dynamic> json) =>
      _$LobbyPlayerFromJson(json);
}

@freezed
class Lobby with _$Lobby {
  const factory Lobby({
    required String id,
    required String name,
    @Default([]) List<LobbyPlayer> players,
    @Default(2) int maxPlayers,
    @Default(LobbyStatus.waiting) LobbyStatus status,
    required String createdAt,
    String? gameId,
    @Default(false) bool isPrivate,
    String? inviteCode,
  }) = _Lobby;

  factory Lobby.fromJson(Map<String, dynamic> json) => _$LobbyFromJson(json);
}
