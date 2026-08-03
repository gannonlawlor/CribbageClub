import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

bool _available = false;

/// Whether Firebase came up at startup.
///
/// Android's `google-services.json` isn't in the repo, so a checkout builds and
/// runs without Firebase. Push notifications are the only thing that needs it,
/// so an unconfigured build degrades to "no push" instead of failing to start.
bool get isFirebaseAvailable => _available;

/// Initializes Firebase, tolerating a build with no Firebase config.
Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    _available = true;
  } catch (e) {
    _available = false;
    debugPrint('[Firebase] Not configured; push notifications disabled: $e');
  }
}
