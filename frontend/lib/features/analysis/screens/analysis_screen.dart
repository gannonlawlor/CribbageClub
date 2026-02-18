import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/engine/local_analysis_service.dart';
import '../../../core/models/card.dart';
import '../../../core/models/game_analysis.dart';
import '../../../core/models/game_state.dart';
import '../../../core/services/analysis_cache_service.dart';
import '../../../core/services/local_game_history_provider.dart';
import '../../../src/rust/api/simple.dart' as rust;
import '../../daily_puzzle/models/keep_explanation.dart';
import '../../daily_puzzle/services/insight_generator.dart';
import '../../daily_puzzle/widgets/explain_bottom_sheet.dart';
import '../../game/state/game_providers.dart';
import '../../game/widgets/card_widget.dart';

/// Provider: checks local cache → server cache → computes on-device → caches everywhere.
final analysisProvider = FutureProvider.family
    .autoDispose<GameAnalysis, String>((ref, gameId) async {
      final cache = ref.read(analysisCacheServiceProvider);

      // 1. Check local cache
      final cached = await cache.getCachedAnalysis(gameId);
      if (cached != null) return cached;

      // 2. For server games, try server cache
      if (!isLocalGame(gameId)) {
        try {
          final restClient = ref.read(restClientProvider);
          final serverCached = await restClient.getGameAnalysis(gameId);
          await cache.cacheAnalysis(gameId, serverCached);
          return serverCached;
        } catch (_) {
          // Not cached on server, will compute below
        }
      }

      // 3. Get game state (history) for on-device computation
      final GameState state;
      if (isLocalGame(gameId)) {
        final notifierState = ref.read(localGameNotifierProvider(gameId));
        var s = notifierState.gameState;
        s ??= await ref.read(persistedGameStateProvider(gameId).future);
        if (s == null) throw Exception('Game not found');
        state = s;
      } else {
        final restClient = ref.read(restClientProvider);
        state = (await restClient.getGameState(gameId)).gameState;
      }

      // 4. Yield a frame so the loading UI renders before blocking FFI call
      await Future.delayed(Duration.zero);

      // 5. Compute on-device
      final analysis = LocalAnalysisService.analyzeGame(gameId, state.history);

      // 6. Cache locally
      await cache.cacheAnalysis(gameId, analysis);

      // 7. Upload to server (fire-and-forget) for server games
      if (!isLocalGame(gameId)) {
        try {
          final restClient = ref.read(restClientProvider);
          await restClient.saveGameAnalysis(gameId, analysis);
        } catch (_) {}
      }

      return analysis;
    });

class AnalysisScreen extends ConsumerWidget {
  final String gameId;

  const AnalysisScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(analysisProvider(gameId));
    final auth = ref.watch(authProvider);
    final playerId = auth.userId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discard Analysis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.replay),
            tooltip: 'Replay',
            onPressed: () => context.go('/replay/$gameId'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: analysis.when(
            data: (data) => _AnalysisContent(
              analysis: data,
              playerId: playerId,
              isLocal: isLocalGame(gameId),
            ),
            loading: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Analyzing discards...',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Analysis unavailable: $error',
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Back to Home'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalysisContent extends StatelessWidget {
  final GameAnalysis analysis;
  final String playerId;
  final bool isLocal;

  const _AnalysisContent({
    required this.analysis,
    required this.playerId,
    required this.isLocal,
  });

  @override
  Widget build(BuildContext context) {
    if (analysis.rounds.isEmpty) {
      return const Center(
        child: Text(
          'No rounds with analysis data available.',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    // Compute summary stats
    final myAnalyses = analysis.rounds
        .expand((r) => r.playerAnalyses)
        .where(
          (a) =>
              isLocal ? !a.playerId.startsWith('ai_') : a.playerId == playerId,
        )
        .toList();
    final totalEvLost = myAnalyses.fold(0.0, (sum, a) => sum + a.evDifference);
    final optimalCount = myAnalyses.where((a) => a.evDifference < 0.01).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text(
                'Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SummaryChip(
                    label: 'Rounds',
                    value: '${analysis.rounds.length}',
                  ),
                  _SummaryChip(
                    label: 'Optimal',
                    value: '$optimalCount/${myAnalyses.length}',
                  ),
                  _SummaryChip(
                    label: 'Avg Pts Lost',
                    value: totalEvLost.toStringAsFixed(1),
                    color: totalEvLost < 2.0
                        ? Colors.greenAccent
                        : totalEvLost < 5.0
                        ? Colors.orangeAccent
                        : Colors.redAccent,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Round cards
        for (final round in analysis.rounds) ...[
          _RoundCard(round: round, playerId: playerId, isLocal: isLocal),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _SummaryChip({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}

class _RoundCard extends StatefulWidget {
  final RoundAnalysis round;
  final String playerId;
  final bool isLocal;

  const _RoundCard({
    required this.round,
    required this.playerId,
    required this.isLocal,
  });

  @override
  State<_RoundCard> createState() => _RoundCardState();
}

class _RoundCardState extends State<_RoundCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Find the player's analysis (for local games, pick the non-AI player)
    final myAnalysis = widget.round.playerAnalyses
        .where(
          (a) => widget.isLocal
              ? !a.playerId.startsWith('ai_')
              : a.playerId == widget.playerId,
        )
        .firstOrNull;
    if (myAnalysis == null) return const SizedBox.shrink();

    final evDiff = myAnalysis.evDifference;
    final evColor = evDiff < 0.5
        ? Colors.greenAccent
        : evDiff < 2.0
        ? Colors.orangeAccent
        : Colors.redAccent;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(
                  'Round ${widget.round.roundNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (myAnalysis.isDealer)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.goldAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Dealer',
                      style: TextStyle(
                        color: AppTheme.goldAccent,
                        fontSize: 11,
                      ),
                    ),
                  ),
                const Spacer(),
                if (widget.round.cutCard != null) ...[
                  const Text(
                    'Cut: ',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  SizedBox(
                    width: 30,
                    height: 42,
                    child: CardWidget(
                      card: widget.round.cutCard,
                      width: 30,
                      height: 42,
                      enabled: false,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Dealt hand
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dealt Hand',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: myAnalysis.dealtHand.map((card) {
                    final isDiscarded = myAnalysis.discarded.contains(card);
                    return Opacity(
                      opacity: isDiscarded ? 0.4 : 1.0,
                      child: CardWidget(
                        card: card,
                        width: 40,
                        height: 56,
                        enabled: false,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Discard comparison
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: _DiscardComparison(
                    label: 'Your Discard',
                    option: myAnalysis.playerDiscard,
                    isDealer: myAnalysis.isDealer,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DiscardComparison(
                    label: 'Optimal',
                    option: myAnalysis.optimalDiscard,
                    isDealer: myAnalysis.isDealer,
                    isOptimal: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // EV difference
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  evDiff < 0.5 ? Icons.check_circle : Icons.info_outline,
                  color: evColor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  evDiff < 0.01
                      ? 'Optimal play!'
                      : '${evDiff.toStringAsFixed(2)} avg pts below optimal',
                  style: TextStyle(color: evColor, fontWeight: FontWeight.w600),
                ),
                if (myAnalysis.actualHandScore > 0) ...[
                  const Spacer(),
                  Text(
                    'Hand: ${myAnalysis.actualHandScore} pts',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
                if (myAnalysis.actualCribScore != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Crib: ${myAnalysis.actualCribScore} pts',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),

          // Expandable: all 15 options
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text(
                    _expanded ? 'Hide all options' : 'Show all 15 options',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white54,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_expanded)
            _AllOptionsExpanded(
              gameId: '',
              round: widget.round,
              playerId: widget.playerId,
              isLocal: widget.isLocal,
            ),
        ],
      ),
    );
  }
}

class _DiscardComparison extends StatelessWidget {
  final String label;
  final DiscardOption option;
  final bool isDealer;
  final bool isOptimal;

  const _DiscardComparison({
    required this.label,
    required this.option,
    required this.isDealer,
    this.isOptimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isOptimal
            ? Colors.greenAccent.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: isOptimal
            ? Border.all(color: Colors.greenAccent.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isOptimal ? Colors.greenAccent : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: option.discard
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: CardWidget(
                      card: card,
                      width: 32,
                      height: 45,
                      enabled: false,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          Text(
            '${option.expectedCombinedValue.toStringAsFixed(2)} avg pts',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'hand ${option.expectedHandValue.toStringAsFixed(1)}  crib ${option.expectedCribValue > 0 ? '+' : ''}${option.expectedCribValue.toStringAsFixed(1)}',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _AllOptionsExpanded extends ConsumerWidget {
  final String gameId;
  final RoundAnalysis round;
  final String playerId;
  final bool isLocal;

  const _AllOptionsExpanded({
    required this.gameId,
    required this.round,
    required this.playerId,
    required this.isLocal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myAnalysis = round.playerAnalyses
        .where(
          (a) =>
              isLocal ? !a.playerId.startsWith('ai_') : a.playerId == playerId,
        )
        .firstOrNull;
    if (myAnalysis == null) return const SizedBox.shrink();

    // We need to fetch all 15 options. They're embedded in the analysis via
    // optimalDiscard (rank 1) and playerDiscard. For full listing, we'd need
    // to re-analyze. For now, show what we have — optimal and player discards.
    // A full re-analysis provider could be added here.
    return _FullOptionsList(analysis: myAnalysis, round: round);
  }
}

class _FullOptionsList extends StatelessWidget {
  final PlayerRoundAnalysis analysis;
  final RoundAnalysis round;

  const _FullOptionsList({required this.analysis, required this.round});

  @override
  Widget build(BuildContext context) {
    // Show the two key options we have
    final options = [analysis.optimalDiscard, analysis.playerDiscard];
    // Deduplicate if they're the same
    final unique = options.toSet().toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Colors.white12),
          for (var i = 0; i < unique.length; i++)
            _OptionRow(
              rank: i + 1,
              option: unique[i],
              isPlayerChoice: unique[i] == analysis.playerDiscard,
              isOptimal: i == 0,
              dealtHand: analysis.dealtHand,
              isDealer: analysis.isDealer,
            ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final int rank;
  final DiscardOption option;
  final bool isPlayerChoice;
  final bool isOptimal;
  final List<PlayingCard> dealtHand;
  final bool isDealer;

  const _OptionRow({
    required this.rank,
    required this.option,
    required this.isPlayerChoice,
    required this.isOptimal,
    required this.dealtHand,
    required this.isDealer,
  });

  void _showExplain(BuildContext context) {
    final handJson = jsonEncode(dealtHand.map((c) => c.toJson()).toList());
    final keepJson = jsonEncode(option.keep.map((c) => c.toJson()).toList());
    final resultJson = rust.explainKeepJson(
      handJson: handJson,
      keepJson: keepJson,
      isDealer: isDealer,
    );
    final explanation = KeepExplanation.fromJson(
      jsonDecode(resultJson) as Map<String, dynamic>,
    );
    final insights = InsightGenerator.generateInsights(
      explanation,
      option.keep,
      option.discard,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ExplainBottomSheet(
        rank: rank,
        keep: option.keep,
        explanation: explanation,
        insights: insights,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showExplain(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: isOptimal ? Colors.greenAccent : Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            ...option.discard.map(
              (card) => Padding(
                padding: const EdgeInsets.only(right: 2),
                child: CardWidget(
                  card: card,
                  width: 26,
                  height: 36,
                  enabled: false,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${option.expectedCombinedValue.toStringAsFixed(2)} avg pts',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            if (isPlayerChoice)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'You',
                  style: TextStyle(color: Colors.blueAccent, fontSize: 10),
                ),
              ),
            if (isOptimal)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Best',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 10),
                ),
              ),
            const SizedBox(width: 4),
            const Icon(
              Icons.info_outline,
              color: Colors.white38,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
