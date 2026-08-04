import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/constants.dart';
import '../auth/auth_service.dart';
import '../models/auth.dart';
import '../models/friend.dart';
import '../models/game_action.dart';
import '../models/game_analysis.dart';
import '../models/game_response.dart';
import '../models/server_history_game.dart';
import '../models/game_state.dart';
import '../models/import_games.dart';
import '../models/join_by_code_result.dart';
import '../models/leaderboard_entry.dart';
import '../models/lobby.dart';
import '../models/head_to_head_response.dart';
import '../models/achievement.dart';
import '../models/profile_response.dart';

class RestClient {
  final Dio _dio;
  final AuthService _authService;
  void Function()? _onAuthExpired;

  void setOnAuthExpired(void Function() callback) {
    _onAuthExpired = callback;
  }

  RestClient({required AuthService authService})
    : _authService = authService,
      _dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.apiBaseUrl,
          connectTimeout: AppConstants.connectTimeout,
          receiveTimeout: AppConstants.receiveTimeout,
          headers: {'Content-Type': 'application/json'},
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _authService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (kDebugMode) {
            final hasAuth = token != null ? ' [auth]' : '';
            debugPrint(
              '[REST] → ${options.method} ${options.baseUrl}${options.path}$hasAuth',
            );
            if (options.data != null) {
              debugPrint('[REST]   body: ${options.data}');
            }
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              '[REST] ← ${response.statusCode} ${response.requestOptions.method} '
              '${response.requestOptions.path} (${response.data.toString().length} chars)',
            );
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            debugPrint(
              '[REST] ✗ ${error.requestOptions.method} ${error.requestOptions.path} '
              '→ ${error.response?.statusCode ?? 'no response'}',
            );
            debugPrint('[REST]   error: ${error.message}');
            if (error.response?.data != null) {
              debugPrint('[REST]   response body: ${error.response?.data}');
            }
            if (error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.receiveTimeout) {
              debugPrint(
                '[REST]   timeout after ${error.requestOptions.connectTimeout}ms',
              );
            }
            if (error.type == DioExceptionType.connectionError) {
              debugPrint('[REST]   connection failed — is the server running?');
            }
          }
          if (error.response?.statusCode == 401) {
            final path = error.requestOptions.path;
            if (!path.startsWith('/api/auth/')) {
              _onAuthExpired?.call();
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  // Auth

  Future<AuthResponse> loginAsGuest() async {
    final response = await _dio.post('/api/auth/guest');
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthResponse> upgradeGuest(
    String username,
    String password, {
    String? displayName,
  }) async {
    final response = await _dio.post(
      '/api/auth/upgrade',
      data: {
        'username': username,
        'password': password,
        'displayName': ?displayName,
      },
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthResponse> login(String username, String password) async {
    final response = await _dio.post(
      '/api/auth/login',
      data: {'username': username, 'password': password},
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthResponse> register(
    String username,
    String password, {
    String? displayName,
  }) async {
    final response = await _dio.post(
      '/api/auth/register',
      data: {
        'username': username,
        'password': password,
        'displayName': ?displayName,
      },
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // Games

  Future<GameState> createAIGame({
    String? playerName,
    String? difficulty,
  }) async {
    final response = await _dio.post(
      '/api/games/ai',
      data: {'playerName': ?playerName, 'difficulty': ?difficulty},
    );
    return GameState.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GameResponse> getGameState(String gameId) async {
    final response = await _dio.get('/api/games/$gameId');
    return GameResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GameResponse> applyAction(String gameId, GameAction action) async {
    final response = await _dio.post(
      '/api/games/$gameId/actions',
      data: action.toJson(),
    );
    return GameResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GameResponse> resignGame(String gameId) async {
    final response = await _dio.post('/api/games/$gameId/resign');
    return GameResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<GameState>> getMyActiveGames() async {
    final response = await _dio.get('/api/games/me');
    final list = response.data as List<dynamic>;
    return list
        .map((json) => GameState.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<ServerHistoryGame>> getMyGameHistory() async {
    final response = await _dio.get('/api/games/me/history');
    final list = response.data as List<dynamic>;
    return list
        .map((json) => ServerHistoryGame.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ImportGamesResponse> importLocalGames(
    List<ImportGameRequest> games,
  ) async {
    final response = await _dio.post(
      '/api/games/import',
      data: {'games': games.map((g) => g.toJson()).toList()},
    );
    return ImportGamesResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // Leaderboard

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    final response = await _dio.get('/api/stats/leaderboard');
    final list = response.data as List<dynamic>;
    return list
        .map((json) => LeaderboardEntry.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Lobbies

  Future<Lobby> createLobby(
    String name, {
    String? creatorName,
    bool isPrivate = false,
  }) async {
    final response = await _dio.post(
      '/api/lobbies',
      data: {'name': name, 'creatorName': ?creatorName, 'isPrivate': isPrivate},
    );
    return Lobby.fromJson(response.data as Map<String, dynamic>);
  }

  Future<JoinByCodeResult> joinByCode(
    String inviteCode, {
    String? playerName,
  }) async {
    final response = await _dio.post(
      '/api/lobbies/join-by-code',
      data: {'inviteCode': inviteCode, 'playerName': ?playerName},
    );
    return JoinByCodeResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Lobby> getLobby(String lobbyId) async {
    final response = await _dio.get('/api/lobbies/$lobbyId');
    return Lobby.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> leaveLobby(String lobbyId) async {
    await _dio.post('/api/lobbies/$lobbyId/leave');
  }

  Future<JoinByCodeResult> quickMatch() async {
    final response = await _dio.post('/api/lobbies/quick-match');
    return JoinByCodeResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Lobby>> listPublicLobbies() async {
    final response = await _dio.get('/api/lobbies/public');
    final list = response.data as List<dynamic>;
    return list
        .map((json) => Lobby.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<JoinByCodeResult> joinLobby(String lobbyId) async {
    final response = await _dio.post('/api/lobbies/$lobbyId/join');
    return JoinByCodeResult.fromJson(response.data as Map<String, dynamic>);
  }

  // Friends

  Future<List<UserSearchResult>> searchUsers(String query) async {
    final response = await _dio.get(
      '/api/friends/search',
      queryParameters: {'query': query},
    );
    final list = response.data as List<dynamic>;
    return list
        .map((json) => UserSearchResult.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<FriendRequestInfo> sendFriendRequest(String username) async {
    final response = await _dio.post(
      '/api/friends/requests',
      data: {'username': username},
    );
    return FriendRequestInfo.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<FriendRequestInfo>> getIncomingFriendRequests() async {
    final response = await _dio.get('/api/friends/requests/incoming');
    final list = response.data as List<dynamic>;
    return list
        .map((json) => FriendRequestInfo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<FriendRequestInfo>> getOutgoingFriendRequests() async {
    final response = await _dio.get('/api/friends/requests/outgoing');
    final list = response.data as List<dynamic>;
    return list
        .map((json) => FriendRequestInfo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<FriendInfo> acceptFriendRequest(String id) async {
    final response = await _dio.post('/api/friends/requests/$id/accept');
    return FriendInfo.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> declineFriendRequest(String id) async {
    await _dio.post('/api/friends/requests/$id/decline');
  }

  Future<List<FriendInfo>> getFriends() async {
    final response = await _dio.get('/api/friends');
    final list = response.data as List<dynamic>;
    return list
        .map((json) => FriendInfo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> removeFriend(String id) async {
    await _dio.delete('/api/friends/$id');
  }

  Future<NotificationCount> getNotificationCount() async {
    final response = await _dio.get('/api/friends/notifications/count');
    return NotificationCount.fromJson(response.data as Map<String, dynamic>);
  }

  // Challenges

  Future<Lobby> createChallenge(String friendUserId) async {
    final response = await _dio.post(
      '/api/challenges',
      data: {'friendUserId': friendUserId},
    );
    return Lobby.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Lobby>> getIncomingChallenges() async {
    final response = await _dio.get('/api/challenges/incoming');
    final list = response.data as List<dynamic>;
    return list
        .map((json) => Lobby.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<JoinByCodeResult> acceptChallenge(String lobbyId) async {
    final response = await _dio.post('/api/challenges/$lobbyId/accept');
    return JoinByCodeResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> declineChallenge(String lobbyId) async {
    await _dio.post('/api/challenges/$lobbyId/decline');
  }

  // Analysis

  Future<GameAnalysis> getGameAnalysis(String gameId) async {
    final response = await _dio.get('/api/games/$gameId/analysis');
    return GameAnalysis.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> saveGameAnalysis(String gameId, GameAnalysis analysis) async {
    await _dio.post('/api/games/$gameId/analysis', data: analysis.toJson());
  }

  // Profiles

  Future<ProfileResponse> getProfile(String userId) async {
    final response = await _dio.get('/api/profiles/$userId');
    return ProfileResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AchievementsResponse> getAchievements(String userId) async {
    final response = await _dio.get('/api/profiles/$userId/achievements');
    return AchievementsResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AchievementStatus>> getAchievementCatalog() async {
    final response = await _dio.get('/api/achievements');
    return (response.data as List<dynamic>)
        .map((e) => AchievementStatus.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<HeadToHeadResponse> getHeadToHead(String userId) async {
    final response = await _dio.get('/api/profiles/$userId/head-to-head');
    return HeadToHeadResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // Device Tokens

  Future<void> registerDeviceToken(String token, String platform) async {
    await _dio.post(
      '/api/device-tokens',
      data: {'token': token, 'platform': platform},
    );
  }

  Future<void> unregisterDeviceToken(String token) async {
    await _dio.delete('/api/device-tokens', data: {'token': token});
  }

  // Puzzles

  /// Reports an on-device daily puzzle solve for achievement credit.
  Future<void> reportPuzzleSolved(bool optimal) async {
    await _dio.post('/api/puzzles/daily/report', data: {'optimal': optimal});
  }
}
