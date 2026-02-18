import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../models/friend.dart';

final notificationCountProvider = FutureProvider.autoDispose<NotificationCount>(
  (ref) async {
    final restClient = ref.read(restClientProvider);
    return restClient.getNotificationCount();
  },
);
