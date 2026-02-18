import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/auth/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/upgrade_screen.dart';
import '../features/game/screens/game_screen.dart';
import '../features/home/screens/game_history_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/leaderboard_screen.dart';
import '../features/lobby/screens/lobby_waiting_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = auth.isLoggedIn;
      final isLoginRoute = state.matchedLocation == '/login';
      final isUpgradeRoute = state.matchedLocation == '/upgrade';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/';
      if (isLoggedIn && !auth.isGuest && isUpgradeRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/game/:gameId',
        builder: (context, state) {
          final gameId = state.pathParameters['gameId']!;
          return GameScreen(gameId: gameId);
        },
      ),
      GoRoute(
        path: '/upgrade',
        builder: (context, state) => const UpgradeScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const GameHistoryScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/lobby/:lobbyId',
        builder: (context, state) {
          final lobbyId = state.pathParameters['lobbyId']!;
          return LobbyWaitingScreen(lobbyId: lobbyId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
