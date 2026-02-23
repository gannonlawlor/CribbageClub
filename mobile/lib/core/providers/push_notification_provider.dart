import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/rest_client.dart';
import '../auth/auth_provider.dart';
import '../services/push_notification_service.dart';
import '../../config/routes.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(
    restClient: ref.read(restClientProvider),
    routerGetter: () => ref.read(routerProvider),
  );
});

/// Side-effect provider: initializes push on login, tears down on logout.
final pushNotificationSyncProvider = Provider<void>((ref) {
  ref.listen<AuthState>(authProvider, (previous, next) {
    final wasLoggedIn = previous?.isLoggedIn ?? false;
    final isNowLoggedIn = next.isLoggedIn;

    if (!wasLoggedIn && isNowLoggedIn) {
      ref.read(pushNotificationServiceProvider).initialize();
    }
    if (wasLoggedIn && !isNowLoggedIn) {
      ref.read(pushNotificationServiceProvider).unregisterToken();
    }
  });
});
