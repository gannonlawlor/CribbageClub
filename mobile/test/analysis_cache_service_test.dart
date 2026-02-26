import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cribbage_club/core/models/card.dart';
import 'package:cribbage_club/core/models/game_analysis.dart';
import 'package:cribbage_club/core/services/analysis_cache_service.dart';
import 'package:cribbage_club/core/api/rest_client.dart';
import 'package:cribbage_club/core/auth/auth_service.dart';

/// A [RestClient] subclass that records calls and can simulate failures.
class FakeRestClient extends RestClient {
  final List<String> uploadedGameIds = [];
  final Set<String> failGameIds;

  FakeRestClient({this.failGameIds = const {}})
      : super(authService: AuthService());

  @override
  Future<void> saveGameAnalysis(String gameId, GameAnalysis analysis) async {
    if (failGameIds.contains(gameId)) {
      throw Exception('Simulated upload failure');
    }
    uploadedGameIds.add(gameId);
  }
}

GameAnalysis _makeAnalysis(String gameId) {
  const card1 = PlayingCard(rank: Rank.ace, suit: Suit.spades);
  const card2 = PlayingCard(rank: Rank.two, suit: Suit.hearts);
  const card3 = PlayingCard(rank: Rank.three, suit: Suit.clubs);
  const card4 = PlayingCard(rank: Rank.four, suit: Suit.diamonds);
  const card5 = PlayingCard(rank: Rank.five, suit: Suit.spades);
  const card6 = PlayingCard(rank: Rank.six, suit: Suit.hearts);

  return GameAnalysis(
    gameId: gameId,
    rounds: [
      RoundAnalysis(
        roundNumber: 1,
        dealerPlayerId: 'player1',
        playerAnalyses: [
          PlayerRoundAnalysis(
            playerId: 'player1',
            isDealer: true,
            dealtHand: const [card1, card2, card3, card4, card5, card6],
            keptHand: const [card1, card2, card3, card4],
            discarded: const [card5, card6],
            actualHandScore: 4,
            optimalDiscard: const DiscardOption(
              keep: [card1, card2, card3, card4],
              discard: [card5, card6],
              expectedHandValue: 5.0,
              expectedCribValue: 2.0,
              expectedCombinedValue: 7.0,
            ),
            playerDiscard: const DiscardOption(
              keep: [card1, card2, card3, card4],
              discard: [card5, card6],
              expectedHandValue: 5.0,
              expectedCribValue: 2.0,
              expectedCombinedValue: 7.0,
            ),
            evDifference: 0.0,
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('AnalysisCacheService — pending uploads', () {
    late AnalysisCacheService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = AnalysisCacheService();
    });

    test('getPendingUploads returns empty list initially', () async {
      final pending = await service.getPendingUploads();
      expect(pending, isEmpty);
    });

    test('addPendingUpload adds a gameId', () async {
      await service.addPendingUpload('game-1');
      final pending = await service.getPendingUploads();
      expect(pending, ['game-1']);
    });

    test('addPendingUpload does not duplicate existing gameId', () async {
      await service.addPendingUpload('game-1');
      await service.addPendingUpload('game-1');
      final pending = await service.getPendingUploads();
      expect(pending, ['game-1']);
    });

    test('addPendingUpload supports multiple gameIds', () async {
      await service.addPendingUpload('game-1');
      await service.addPendingUpload('game-2');
      await service.addPendingUpload('game-3');
      final pending = await service.getPendingUploads();
      expect(pending, ['game-1', 'game-2', 'game-3']);
    });

    test('removePendingUpload removes a gameId', () async {
      await service.addPendingUpload('game-1');
      await service.addPendingUpload('game-2');
      await service.removePendingUpload('game-1');
      final pending = await service.getPendingUploads();
      expect(pending, ['game-2']);
    });

    test('removePendingUpload is a no-op for missing gameId', () async {
      await service.addPendingUpload('game-1');
      await service.removePendingUpload('game-999');
      final pending = await service.getPendingUploads();
      expect(pending, ['game-1']);
    });

    test('pending uploads persist across service instances', () async {
      await service.addPendingUpload('game-1');
      await service.addPendingUpload('game-2');

      // Create a new instance (simulates app restart, same SharedPreferences)
      final service2 = AnalysisCacheService();
      final pending = await service2.getPendingUploads();
      expect(pending, ['game-1', 'game-2']);
    });
  });

  group('AnalysisCacheService — uploadPendingAnalyses', () {
    late AnalysisCacheService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = AnalysisCacheService();
    });

    test('does nothing when no pending uploads', () async {
      final client = FakeRestClient();
      await service.uploadPendingAnalyses(client);
      expect(client.uploadedGameIds, isEmpty);
    });

    test('uploads cached analyses and clears pending list', () async {
      // Cache analyses and mark as pending
      await service.cacheAnalysis('game-1', _makeAnalysis('game-1'));
      await service.cacheAnalysis('game-2', _makeAnalysis('game-2'));
      await service.addPendingUpload('game-1');
      await service.addPendingUpload('game-2');

      final client = FakeRestClient();
      await service.uploadPendingAnalyses(client);

      expect(client.uploadedGameIds, ['game-1', 'game-2']);
      expect(await service.getPendingUploads(), isEmpty);
    });

    test('removes pending entry when no cached analysis exists', () async {
      // Mark as pending but don't cache any analysis
      await service.addPendingUpload('game-orphan');

      final client = FakeRestClient();
      await service.uploadPendingAnalyses(client);

      expect(client.uploadedGameIds, isEmpty);
      expect(await service.getPendingUploads(), isEmpty);
    });

    test('keeps pending entry on upload failure', () async {
      await service.cacheAnalysis('game-fail', _makeAnalysis('game-fail'));
      await service.addPendingUpload('game-fail');

      final client = FakeRestClient(failGameIds: {'game-fail'});
      await service.uploadPendingAnalyses(client);

      expect(client.uploadedGameIds, isEmpty);
      final pending = await service.getPendingUploads();
      expect(pending, ['game-fail']);
    });

    test('partial failure: uploads successes and keeps failures', () async {
      await service.cacheAnalysis('game-ok', _makeAnalysis('game-ok'));
      await service.cacheAnalysis('game-fail', _makeAnalysis('game-fail'));
      await service.addPendingUpload('game-ok');
      await service.addPendingUpload('game-fail');

      final client = FakeRestClient(failGameIds: {'game-fail'});
      await service.uploadPendingAnalyses(client);

      expect(client.uploadedGameIds, ['game-ok']);
      final pending = await service.getPendingUploads();
      expect(pending, ['game-fail']);
    });
  });

  group('AnalysisCacheService — caching', () {
    late AnalysisCacheService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = AnalysisCacheService();
    });

    test('getCachedAnalysis returns null for uncached game', () async {
      final result = await service.getCachedAnalysis('nonexistent');
      expect(result, isNull);
    });

    test('cacheAnalysis and getCachedAnalysis round-trip', () async {
      final analysis = _makeAnalysis('game-rt');
      await service.cacheAnalysis('game-rt', analysis);

      final cached = await service.getCachedAnalysis('game-rt');
      expect(cached, isNotNull);
      expect(cached!.gameId, 'game-rt');
      expect(cached.rounds.length, 1);
      expect(cached.rounds[0].roundNumber, 1);
      expect(cached.rounds[0].playerAnalyses[0].evDifference, 0.0);
    });
  });
}
