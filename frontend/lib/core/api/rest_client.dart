import 'package:dio/dio.dart';
import '../../config/constants.dart';
import '../auth/auth_service.dart';
import '../models/auth.dart';
import '../models/card.dart';
import '../models/friend.dart';
import '../models/game_action.dart';
import '../models/game_analysis.dart';
import '../models/game_state.dart';
import '../models/join_by_code_result.dart';
import '../models/leaderboard_entry.dart';
import '../models/lobby.dart';
import '../models/puzzle.dart';
import '../models/stats_response.dart';

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
          handler.next(options);
        },
        onError: (error, handler) {
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

  Future<GameState> getGameState(String gameId) async {
    final response = await _dio.get('/api/games/$gameId');
    return GameState.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GameState> applyAction(String gameId, GameAction action) async {
    final response = await _dio.post(
      '/api/games/$gameId/actions',
      data: action.toJson(),
    );
    return GameState.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<GameState>> listGames() async {
    final response = await _dio.get('/api/games');
    final list = response.data as List<dynamic>;
    return list
        .map((json) => GameState.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteGame(String gameId) async {
    await _dio.delete('/api/games/$gameId');
  }

  Future<List<GameState>> getMyActiveGames() async {
    final response = await _dio.get('/api/games/me');
    final list = response.data as List<dynamic>;
    return list
        .map((json) => GameState.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<GameState>> getMyGameHistory() async {
    final response = await _dio.get('/api/games/me/history');
    final list = response.data as List<dynamic>;
    return list
        .map((json) => GameState.fromJson(json as Map<String, dynamic>))
        .toList();
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

  Future<void> cancelChallenge(String lobbyId) async {
    await _dio.post('/api/challenges/$lobbyId/cancel');
  }

  // Analysis

  Future<GameAnalysis> getGameAnalysis(String gameId) async {
    final response = await _dio.get('/api/games/$gameId/analysis');
    return GameAnalysis.fromJson(response.data as Map<String, dynamic>);
  }

  // Stats

  Future<StatsResponse> getMyStats() async {
    final response = await _dio.get('/api/stats/me');
    return StatsResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // Puzzles

  Future<PuzzleResponse> getDailyPuzzle() async {
    final response = await _dio.get('/api/puzzles/daily');
    return PuzzleResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PuzzleSolveResponse> solvePuzzle(
    String puzzleId,
    List<PlayingCard> chosenDiscard,
  ) async {
    final response = await _dio.post(
      '/api/puzzles/$puzzleId/solve',
      data: {'chosenDiscard': chosenDiscard.map((c) => c.toJson()).toList()},
    );
    return PuzzleSolveResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
