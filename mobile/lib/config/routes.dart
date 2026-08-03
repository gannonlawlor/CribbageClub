import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/auth/auth_provider.dart';
import '../features/analysis/screens/analysis_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/upgrade_screen.dart';
import '../features/game/screens/game_screen.dart';
import '../features/home/screens/game_history_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/leaderboard_screen.dart';
import '../features/friends/screens/friends_screen.dart';
import '../features/daily_puzzle/screens/daily_puzzle_screen.dart';
import '../features/daily_puzzle/screens/practice_puzzle_screen.dart';
import '../features/lobby/screens/lobby_browser_screen.dart';
import '../features/lobby/screens/lobby_waiting_screen.dart';
import '../features/profile/screens/my_profile_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/replay/screens/replay_screen.dart';
import '../features/settings/screens/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = auth.isLoggedIn;
      final isLoginRoute = state.matchedLocation == '/login';
      final isUpgradeRoute = state.matchedLocation == '/upgrade';

      // Only redirect: logged-in users away from login, non-guests away from upgrade
      if (isLoggedIn && isLoginRoute) return '/';
      if (isLoggedIn && !auth.isGuest && isUpgradeRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginScreen()),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: HomeScreen()),
      ),
      GoRoute(
        path: '/game/:gameId',
        pageBuilder: (context, state) {
          final gameId = state.pathParameters['gameId']!;
          return NoTransitionPage(child: GameScreen(gameId: gameId));
        },
      ),
      // Everything below is pushed onto the tab root, so it gets a MaterialPage
      // rather than a NoTransitionPage: the page transition is what carries the
      // interactive pop gesture (edge swipe on iOS, predictive back on
      // Android). A NoTransitionPage has no transition to drive, so there's no
      // gesture either.
      GoRoute(
        path: '/upgrade',
        pageBuilder: (context, state) =>
            const MaterialPage(child: UpgradeScreen()),
      ),
      GoRoute(
        path: '/history',
        pageBuilder: (context, state) =>
            const MaterialPage(child: GameHistoryScreen()),
      ),
      GoRoute(
        path: '/leaderboard',
        pageBuilder: (context, state) =>
            const MaterialPage(child: LeaderboardScreen()),
      ),
      GoRoute(
        path: '/friends',
        pageBuilder: (context, state) =>
            const MaterialPage(child: FriendsScreen()),
      ),
      GoRoute(
        path: '/lobbies',
        pageBuilder: (context, state) =>
            const MaterialPage(child: LobbyBrowserScreen()),
      ),
      GoRoute(
        path: '/lobby/:lobbyId',
        pageBuilder: (context, state) {
          final lobbyId = state.pathParameters['lobbyId']!;
          return MaterialPage(child: LobbyWaitingScreen(lobbyId: lobbyId));
        },
      ),
      GoRoute(
        path: '/me',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: MyProfileScreen()),
      ),
      GoRoute(
        path: '/profile/:userId',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return MaterialPage(child: ProfileScreen(userId: userId));
        },
      ),
      GoRoute(
        path: '/analysis/:gameId',
        pageBuilder: (context, state) {
          final gameId = state.pathParameters['gameId']!;
          return MaterialPage(child: AnalysisScreen(gameId: gameId));
        },
      ),
      GoRoute(
        path: '/replay/:gameId',
        pageBuilder: (context, state) {
          final gameId = state.pathParameters['gameId']!;
          return MaterialPage(child: ReplayScreen(gameId: gameId));
        },
      ),
      GoRoute(
        path: '/daily-puzzle',
        pageBuilder: (context, state) =>
            const MaterialPage(child: DailyPuzzleScreen()),
      ),
      GoRoute(
        path: '/practice-puzzle',
        pageBuilder: (context, state) =>
            const MaterialPage(child: PracticePuzzleScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SettingsScreen()),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );
});
