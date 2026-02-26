import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cribbage_club/core/api/rest_client.dart';
import 'package:cribbage_club/core/auth/auth_service.dart';
import 'package:cribbage_club/core/services/push_notification_service.dart';
import 'package:go_router/go_router.dart';

/// A [RestClient] subclass that tracks device token registrations.
class FakeRestClient extends RestClient {
  final List<(String token, String platform)> registeredTokens = [];
  bool shouldFail = false;

  FakeRestClient() : super(authService: AuthService());

  @override
  Future<void> registerDeviceToken(String token, String platform) async {
    if (shouldFail) {
      throw Exception('Simulated registration failure');
    }
    registeredTokens.add((token, platform));
  }

  @override
  Future<void> unregisterDeviceToken(String token) async {
    // no-op for tests
  }
}

void main() {
  group('PushNotificationService.reRegisterTokenIfNeeded', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('does nothing when no token has been set', () async {
      final client = FakeRestClient();
      final service = PushNotificationService(
        restClient: client,
        routerGetter: () => GoRouter(routes: []),
      );

      // No initialize() called, so _currentToken is null
      await service.reRegisterTokenIfNeeded();

      expect(client.registeredTokens, isEmpty);
    });

    test('unregisterToken is a no-op when no token has been set', () async {
      final client = FakeRestClient();
      final service = PushNotificationService(
        restClient: client,
        routerGetter: () => GoRouter(routes: []),
      );

      // Should not throw
      await service.unregisterToken();
    });
  });
}
