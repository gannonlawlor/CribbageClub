import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension AppNavigation on BuildContext {
  /// Goes back one screen, falling back to the Play tab when there's nothing
  /// to pop.
  ///
  /// Most screens are pushed, so this pops. But a push-notification tap or a
  /// deep link can land you on a screen that was never pushed from anywhere,
  /// and popping an empty stack drops you out of the app entirely.
  void backOrHome() {
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}
