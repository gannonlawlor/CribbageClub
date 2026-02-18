import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/rest_client.dart';
import 'auth_service.dart';

// Module-level initial auth data, set before runApp
AuthData? _initialAuthData;

void setInitialAuthData(AuthData? data) {
  _initialAuthData = data;
}

// Singletons
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final restClientProvider = Provider<RestClient>((ref) {
  return RestClient(authService: ref.read(authServiceProvider));
});

// Auth state
class AuthState {
  final bool isLoggedIn;
  final String? userId;
  final String? username;
  final bool isLoading;
  final String? error;
  final bool isGuest;

  const AuthState({
    this.isLoggedIn = false,
    this.userId,
    this.username,
    this.isLoading = false,
    this.error,
    this.isGuest = false,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? userId,
    String? username,
    bool? isLoading,
    String? error,
    bool? isGuest,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final RestClient _restClient;

  AuthNotifier(this._authService, this._restClient, {AuthData? initialAuth})
      : super(
          initialAuth != null
              ? AuthState(
                  isLoggedIn: true,
                  userId: initialAuth.userId,
                  username: initialAuth.username,
                  isGuest: initialAuth.isGuest,
                )
              : const AuthState(),
        ) {
    _restClient.setOnAuthExpired(() {
      _authService.clearAuth();
      state = const AuthState();
    });
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _restClient.login(username, password);
      await _authService.saveAuth(
        token: response.token,
        userId: response.userId,
        username: response.username,
      );
      state = AuthState(
        isLoggedIn: true,
        userId: response.userId,
        username: response.username,
      );
    } on DioException catch (e) {
      final message = _extractError(e);
      state = state.copyWith(isLoading: false, error: message);
    }
  }

  Future<void> register(
    String username,
    String password, {
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _restClient.register(
        username,
        password,
        displayName: displayName,
      );
      await _authService.saveAuth(
        token: response.token,
        userId: response.userId,
        username: response.username,
      );
      state = AuthState(
        isLoggedIn: true,
        userId: response.userId,
        username: response.username,
      );
    } on DioException catch (e) {
      final message = _extractError(e);
      state = state.copyWith(isLoading: false, error: message);
    }
  }

  Future<void> loginAsGuest() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _restClient.loginAsGuest();
      await _authService.saveAuth(
        token: response.token,
        userId: response.userId,
        username: response.username,
        isGuest: true,
      );
      state = AuthState(
        isLoggedIn: true,
        userId: response.userId,
        username: response.username,
        isGuest: true,
      );
    } on DioException catch (e) {
      final message = _extractError(e);
      state = state.copyWith(isLoading: false, error: message);
    }
  }

  Future<void> upgradeGuest(
    String username,
    String password, {
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _restClient.upgradeGuest(
        username,
        password,
        displayName: displayName,
      );
      await _authService.saveAuth(
        token: response.token,
        userId: response.userId,
        username: response.username,
        isGuest: false,
      );
      state = AuthState(
        isLoggedIn: true,
        userId: response.userId,
        username: response.username,
        isGuest: false,
      );
    } on DioException catch (e) {
      final message = _extractError(e);
      state = state.copyWith(isLoading: false, error: message);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> logout() async {
    await _authService.clearAuth();
    state = const AuthState();
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return (data['message'] ?? data['error'] ?? 'Request failed').toString();
    }
    return e.message ?? 'Request failed';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authServiceProvider),
    ref.read(restClientProvider),
    initialAuth: _initialAuthData,
  );
});
