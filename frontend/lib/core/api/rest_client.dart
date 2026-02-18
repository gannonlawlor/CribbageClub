import 'package:dio/dio.dart';
import '../../config/constants.dart';
import '../auth/auth_service.dart';
import '../models/auth.dart';
import '../models/game_action.dart';
import '../models/game_state.dart';

class RestClient {
  final Dio _dio;
  final AuthService _authService;

  RestClient({required AuthService authService})
      : _authService = authService,
        _dio = Dio(BaseOptions(
          baseUrl: AppConstants.apiBaseUrl,
          connectTimeout: AppConstants.connectTimeout,
          receiveTimeout: AppConstants.receiveTimeout,
          headers: {'Content-Type': 'application/json'},
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  // Auth

  Future<AuthResponse> login(String username, String password) async {
    final response = await _dio.post('/api/auth/login', data: {
      'username': username,
      'password': password,
    });
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthResponse> register(
    String username,
    String password, {
    String? displayName,
  }) async {
    final response = await _dio.post('/api/auth/register', data: {
      'username': username,
      'password': password,
      'displayName': ?displayName,
    });
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // Games

  Future<GameState> createAIGame({String? playerName, String? difficulty}) async {
    final response = await _dio.post('/api/games/ai', data: {
      'playerName': ?playerName,
      'difficulty': ?difficulty,
    });
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

  Future<void> deleteGame(String gameId) async {
    await _dio.delete('/api/games/$gameId');
  }
}
