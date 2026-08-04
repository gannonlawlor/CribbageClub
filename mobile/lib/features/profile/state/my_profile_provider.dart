import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/profile_response.dart';

/// The signed-in (non-guest) user's server profile, or null when there is
/// no server identity to fetch.
// Kept alive so the header rating chip doesn't flicker on tab switches;
// re-fetches automatically when auth state changes.
final myProfileProvider = FutureProvider<ProfileResponse?>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn || auth.isGuest || auth.userId == null) return null;
  final restClient = ref.read(restClientProvider);
  return restClient.getProfile(auth.userId!);
});
