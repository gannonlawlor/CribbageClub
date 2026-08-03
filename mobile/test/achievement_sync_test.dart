import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cribbage_club/core/auth/auth_provider.dart';
import 'package:cribbage_club/core/auth/auth_service.dart';
import 'package:cribbage_club/core/api/rest_client.dart';
import 'package:cribbage_club/core/models/achievement.dart';
import 'package:cribbage_club/core/services/achievement_service.dart';
import 'package:cribbage_club/core/services/platform_achievements.dart';
import 'package:cribbage_club/shared/widgets/achievement_banner.dart';

/// Catalog keys the backend serves — mirrors the Achievement enum.
const _allKeys = [
  'FIRST_GAME', 'FIRST_WIN', 'WINS_10', 'WINS_50', 'WINS_100',
  'STREAK_5', 'STREAK_10', 'BEAT_AI_MEDIUM', 'BEAT_AI_HARD', 'SKUNK',
  'DOUBLE_SKUNK', 'SKUNK_AI_HARD', 'COMEBACK', 'HAND_20', 'HAND_24',
  'HAND_29', 'CRIB_12', 'HIS_HEELS', 'PEG_31', 'PEG_12_ROUND',
  'FIRST_ONLINE_WIN', 'RATING_1600', 'FRIEND_ADDED', 'PUZZLE_FIRST',
  'PUZZLE_OPTIMAL_10',
];

AchievementStatus _status(String key, {bool unlocked = false, int sort = 0}) =>
    AchievementStatus(
      key: key,
      name: key,
      description: 'desc $key',
      tier: AchievementTier.bronze,
      unlocked: unlocked,
      sortOrder: sort,
    );

class _FakeRestClient extends RestClient {
  AchievementsResponse response;

  _FakeRestClient(this.response) : super(authService: AuthService());

  @override
  Future<AchievementsResponse> getAchievements(String userId) async =>
      response;
}

/// Platform layer that records instead of talking to Game Center.
class _RecordingPlatform extends PlatformAchievements {
  final unlockedKeys = <String>[];

  @override
  Future<void> signIn() async {}

  @override
  Future<void> unlockAll(Iterable<String> keys) async {
    unlockedKeys.addAll(keys);
  }
}

final _refProvider = Provider<Ref>((ref) => ref);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer container(_FakeRestClient client) {
    final c = ProviderContainer(
      overrides: [
        restClientProvider.overrideWithValue(client),
        authProvider.overrideWith(
          (ref) => AuthNotifier(
            AuthService(),
            client,
            initialAuth: const AuthData(
              token: 't',
              userId: 'user1',
              username: 'Me',
            ),
          ),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('platform achievement ID map', () {
    test('covers every catalog key exactly', () {
      expect(platformAchievementIds.keys.toSet(), _allKeys.toSet());
    });

    test('iOS IDs are all configured', () {
      for (final entry in platformAchievementIds.entries) {
        expect(entry.value.ios, isNotEmpty, reason: entry.key);
      }
    });
  });

  group('AchievementSyncService.sync', () {
    test('banners a fresh unlock once and persists it as celebrated',
        () async {
      SharedPreferences.setMockInitialValues({
        // An earlier sync has already celebrated FIRST_GAME.
        'celebrated_achievements_user1': ['FIRST_GAME'],
      });
      final client = _FakeRestClient(
        AchievementsResponse(
          achievements: [
            _status('FIRST_GAME', unlocked: true),
            _status('FIRST_WIN', unlocked: true, sort: 1),
            _status('SKUNK'),
          ],
          unlockedCount: 2,
          totalCount: 3,
        ),
      );
      final c = container(client);
      final platform = _RecordingPlatform();
      final service = AchievementSyncService(c.read(_refProvider), platform);

      await service.sync();

      // Only the not-yet-celebrated unlock banners.
      expect(
        c.read(achievementBannerQueueProvider).map((a) => a.key),
        ['FIRST_WIN'],
      );
      // Every unlock mirrors to the platform, celebrated or not.
      expect(platform.unlockedKeys, ['FIRST_GAME', 'FIRST_WIN']);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getStringList('celebrated_achievements_user1')!.toSet(),
        {'FIRST_GAME', 'FIRST_WIN'},
      );

      // A second sync with the same server state banners nothing new.
      c.read(achievementBannerQueueProvider.notifier).popCurrent();
      await service.sync();
      expect(c.read(achievementBannerQueueProvider), isEmpty);
    });

    test('a large first-ever sync celebrates silently', () async {
      SharedPreferences.setMockInitialValues({});
      final client = _FakeRestClient(
        AchievementsResponse(
          achievements: [
            for (var i = 0; i < 6; i++)
              _status(_allKeys[i], unlocked: true, sort: i),
          ],
          unlockedCount: 6,
          totalCount: 25,
        ),
      );
      final c = container(client);
      final platform = _RecordingPlatform();
      final service = AchievementSyncService(c.read(_refProvider), platform);

      await service.sync();

      // No banner flood on device catch-up — but everything is persisted
      // and mirrored.
      expect(c.read(achievementBannerQueueProvider), isEmpty);
      expect(platform.unlockedKeys.length, 6);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getStringList('celebrated_achievements_user1')!.length,
        6,
      );
    });
  });

  group('AchievementBannerQueue', () {
    test('enqueues in order, dedupes pending, pops from the front', () {
      final queue = AchievementBannerQueue();
      queue.enqueue([_status('A'), _status('B')]);
      queue.enqueue([_status('B'), _status('C')]);

      expect(queue.state.map((a) => a.key), ['A', 'B', 'C']);

      queue.popCurrent();
      expect(queue.state.map((a) => a.key), ['B', 'C']);

      queue.popCurrent();
      queue.popCurrent();
      queue.popCurrent(); // popping empty is a no-op
      expect(queue.state, isEmpty);
    });
  });
}
