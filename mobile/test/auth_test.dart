import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cribbage_club/core/auth/auth_service.dart';
import 'package:cribbage_club/core/auth/auth_provider.dart';
import 'package:cribbage_club/core/api/rest_client.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authService = AuthService();
    });

    test('saveAuth stores all fields and isLoggedIn returns true', () async {
      await authService.saveAuth(
        token: 'test-token',
        userId: 'user-123',
        username: 'testuser',
      );

      expect(await authService.isLoggedIn(), true);
      expect(await authService.getToken(), 'test-token');
      expect(await authService.getUserId(), 'user-123');
      expect(await authService.getUsername(), 'testuser');
      expect(await authService.getIsGuest(), false);
    });

    test('saveAuth with isGuest stores guest flag', () async {
      await authService.saveAuth(
        token: 'guest-token',
        userId: 'guest-456',
        username: 'Guest_456',
        isGuest: true,
      );

      expect(await authService.isLoggedIn(), true);
      expect(await authService.getIsGuest(), true);
    });

    test('clearAuth removes all stored data', () async {
      await authService.saveAuth(
        token: 'test-token',
        userId: 'user-123',
        username: 'testuser',
      );

      await authService.clearAuth();

      expect(await authService.isLoggedIn(), false);
      expect(await authService.getToken(), null);
      expect(await authService.getUserId(), null);
      expect(await authService.getUsername(), null);
      expect(await authService.getIsGuest(), false);
    });

    test('loadSavedAuth returns null when no token stored', () async {
      final result = await authService.loadSavedAuth();
      expect(result, isNull);
    });

    test('loadSavedAuth returns AuthData when token exists', () async {
      await authService.saveAuth(
        token: 'saved-token',
        userId: 'user-789',
        username: 'saveduser',
        isGuest: true,
      );

      final result = await authService.loadSavedAuth();

      expect(result, isNotNull);
      expect(result!.token, 'saved-token');
      expect(result.userId, 'user-789');
      expect(result.username, 'saveduser');
      expect(result.isGuest, true);
    });
  });

  group('AuthNotifier', () {
    late AuthService authService;
    late RestClient restClient;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authService = AuthService();
      restClient = RestClient(authService: authService);
    });

    test('initializes as logged out when no saved auth', () {
      final notifier = AuthNotifier(authService, restClient);

      expect(notifier.state.isLoggedIn, false);
      expect(notifier.state.userId, isNull);
      expect(notifier.state.username, isNull);
      expect(notifier.state.isGuest, false);
    });

    test('initializes as logged in when initialAuth provided', () {
      final authData = AuthData(
        token: 'init-token',
        userId: 'init-user',
        username: 'initname',
        isGuest: false,
      );
      final notifier = AuthNotifier(
        authService,
        restClient,
        initialAuth: authData,
      );

      expect(notifier.state.isLoggedIn, true);
      expect(notifier.state.userId, 'init-user');
      expect(notifier.state.username, 'initname');
      expect(notifier.state.isGuest, false);
    });

    test('initializes as guest when initialAuth has isGuest', () {
      final authData = AuthData(
        token: 'guest-token',
        userId: 'guest-user',
        username: 'Guest_123',
        isGuest: true,
      );
      final notifier = AuthNotifier(
        authService,
        restClient,
        initialAuth: authData,
      );

      expect(notifier.state.isLoggedIn, true);
      expect(notifier.state.isGuest, true);
    });

    test('logout clears state and storage', () async {
      await authService.saveAuth(
        token: 'test-token',
        userId: 'user-123',
        username: 'testuser',
      );
      final notifier = AuthNotifier(
        authService,
        restClient,
        initialAuth: AuthData(
          token: 'test-token',
          userId: 'user-123',
          username: 'testuser',
        ),
      );

      await notifier.logout();

      expect(notifier.state.isLoggedIn, false);
      expect(notifier.state.userId, isNull);
      expect(await authService.isLoggedIn(), false);
    });
  });
}
