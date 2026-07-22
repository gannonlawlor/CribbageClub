import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/engine/local_analysis_service.dart';
import '../../../core/models/card.dart';
import '../../../core/models/game_analysis.dart';
import '../../../core/models/game_state.dart';
import '../../../core/services/analysis_cache_service.dart';
import '../../../core/services/local_game_history_provider.dart';
import '../../../shared/widgets/cc_buttons.dart';
import '../../../shared/widgets/cc_dialog.dart';
import '../../daily_puzzle/widgets/explain_dialog.dart';
import '../../game/state/game_providers.dart';
import '../../game/widgets/card_widget.dart';

/// Provider: checks local cache → server cache → computes on-device → caches everywhere.
final analysisProvider = FutureProvider.family.autoDispose<GameAnalysis, String>((
  ref,
  gameId,
) async {
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
    } catch (e) {
      debugPrint('[Analysis] Server cache miss for $gameId: $e');
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

  // 4. Yield multiple frames so the loading UI fully renders before blocking FFI call.
  // Duration.zero only schedules a microtask (before paint); we need actual frames.
  await Future.delayed(const Duration(milliseconds: 100));

  // 5. Compute on-device (synchronous FFI — blocks main thread)
  final analysis = LocalAnalysisService.analyzeGame(gameId, state.history);

  // 6. Cache locally
  await cache.cacheAnalysis(gameId, analysis);

  // 7. Upload to server (fire-and-forget) for server games
  if (!isLocalGame(gameId)) {
    try {
      final restClient = ref.read(restClientProvider);
      await restClient.saveGameAnalysis(gameId, analysis);
    } catch (e) {
      debugPrint('[Analysis] Failed to upload analysis for $gameId: $e');
      ref.read(analysisCacheServiceProvider).addPendingUpload(gameId);
    }
  }

  return analysis;
});

/// Card sizes used across the screen — one scale so every hand reads the same.
const double _handCardWidth = 40;
const double _discardCardWidth = 34;
const double _optionCardWidth = 26;
const double _cardAspect = 2.5 / 3.5;

double _cardHeight(double width) => width / _cardAspect;

class AnalysisScreen extends ConsumerWidget {
  final String gameId;

  const AnalysisScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final analysis = ref.watch(analysisProvider(gameId));
    final auth = ref.watch(authProvider);
    final playerId = auth.userId ?? '';

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                _Header(
                  onBack: () => context.go('/'),
                  onReplay: () => context.go('/replay/$gameId'),
                ),
                Expanded(
                  child: analysis.when(
                    data: (data) => _AnalysisContent(
                      analysis: data,
                      playerId: playerId,
                      isLocal: isLocalGame(gameId),
                    ),
                    loading: () => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Working through your discards',
                            style: TextStyle(
                              color: colors.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    error: (error, _) => _Message(
                      title: 'Analysis unavailable',
                      detail: '$error',
                      action: 'Back to home',
                      onAction: () => context.go('/'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen chrome: back, title, and the jump across to the replay.
class _Header extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onReplay;

  const _Header({required this.onBack, required this.onReplay});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, size: 20, color: colors.textSecondary),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              'Analysis',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.play_circle_outline,
              size: 20,
              color: colors.textTertiary,
            ),
            tooltip: 'Replay',
            onPressed: onReplay,
          ),
        ],
      ),
    );
  }
}

/// Centred title + detail + one surface button — used for the error and
/// nothing-to-analyse states.
class _Message extends StatelessWidget {
  final String title;
  final String? detail;
  final String? action;
  final VoidCallback? onAction;

  const _Message({
    required this.title,
    this.detail,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textTertiary, fontSize: 13),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: CcSecondaryButton(label: action!, onPressed: onAction),
              ),
            ],
          ],
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

  bool _isMine(PlayerRoundAnalysis a) =>
      isLocal ? !a.playerId.startsWith('ai_') : a.playerId == playerId;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (analysis.rounds.isEmpty) {
      return const _Message(
        title: 'Nothing to analyse yet',
        detail: 'This game ended before a crib was thrown.',
      );
    }

    final myAnalyses = analysis.rounds
        .expand((r) => r.playerAnalyses)
        .where(_isMine)
        .toList();
    final pointsLost = myAnalyses.fold(0.0, (sum, a) => sum + a.evDifference);
    final optimalCount = myAnalyses.where((a) => a.evDifference < 0.01).length;
    final lostColor = pointsLost < 2.0
        ? colors.evOptimal
        : pointsLost < 5.0
        ? colors.evGood
        : colors.evPoor;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        const _SectionCaption('Your discards'),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Rounds',
                value: '${analysis.rounds.length}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Best pick',
                value: '$optimalCount/${myAnalyses.length}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Points lost',
                value: pointsLost.toStringAsFixed(1),
                valueColor: lostColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        const _SectionCaption('Round by round'),
        for (final round in analysis.rounds) ...[
          _RoundCard(round: round, playerId: playerId, isLocal: isLocal),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// Section label — 11/600 uppercase, matching the settings and home screens.
class _SectionCaption extends StatelessWidget {
  final String text;

  const _SectionCaption(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: colors.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

/// Stat card (design language §4): surface panel, caption label over a large
/// tabular value.
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatCard({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? colors.textPrimary,
                fontSize: 24,
                height: 1,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
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
    final colors = context.appColors;

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
    final foundBest = evDiff < 0.01;
    final evColor = evDiff < 0.5
        ? colors.evOptimal
        : evDiff < 2.0
        ? colors.evGood
        : colors.evPoor;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Round ${widget.round.roundNumber}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (myAnalysis.isDealer) ...[
                            const SizedBox(width: 8),
                            const _Chip(label: 'DEALER'),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      const _MicroCaption('You kept'),
                      const SizedBox(height: 5),
                      _CardRow(
                        cards: myAnalysis.keptHand,
                        cardWidth: _handCardWidth,
                      ),
                    ],
                  ),
                ),
                if (widget.round.cutCard != null) ...[
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      CardWidget(
                        card: widget.round.cutCard,
                        width: _discardCardWidth,
                        height: _cardHeight(_discardCardWidth),
                        enabled: false,
                      ),
                      const SizedBox(height: 5),
                      const _MicroCaption('Starter'),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: foundBest
                // Your pick was the best one — one panel says it all.
                ? _DiscardPanel(
                    label: 'Your discard · best',
                    option: myAnalysis.playerDiscard,
                    isBest: true,
                  )
                : IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _DiscardPanel(
                            label: 'Your discard',
                            option: myAnalysis.playerDiscard,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DiscardPanel(
                            label: 'Best discard',
                            option: myAnalysis.optimalDiscard,
                            isBest: true,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 12),

          // Verdict. Kept on its own line so a long number can never push the
          // scored results off the right edge.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      foundBest ? Icons.check_circle : Icons.info_outline,
                      color: evColor,
                      size: 16,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        foundBest
                            ? 'You found the best discard'
                            : '${evDiff.toStringAsFixed(2)} points below the best discard',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: evColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
                if (myAnalysis.actualHandScore > 0 ||
                    myAnalysis.actualCribScore != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 23),
                    child: Text(
                      _scoredLine(myAnalysis),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 12,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Divider(height: 21, thickness: 1, color: colors.border),

          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                children: [
                  Text(
                    _expanded ? 'Hide the other options' : 'All 15 options',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: colors.textTertiary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) _OptionsList(analysis: myAnalysis),
        ],
      ),
    );
  }

  /// What the hand and crib actually came to once the starter was cut.
  static String _scoredLine(PlayerRoundAnalysis a) {
    final parts = <String>['Hand scored ${a.actualHandScore}'];
    if (a.actualCribScore != null) parts.add('crib ${a.actualCribScore}');
    return parts.join(' · ');
  }
}

/// Small uppercase label above a group of cards.
class _MicroCaption extends StatelessWidget {
  final String text;

  const _MicroCaption(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: colors.textTertiary,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    );
  }
}

/// Neutral metadata chip — surface-3 fill, like the in-game DEALER chip.
class _Chip extends StatelessWidget {
  final String label;
  final Color? color;

  const _Chip({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color == null
            ? colors.surfaceDim
            : color!.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color ?? colors.textSecondary,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.54,
        ),
      ),
    );
  }
}

/// A row of face-up cards at a fixed size.
class _CardRow extends StatelessWidget {
  final List<PlayingCard> cards;
  final double cardWidth;

  const _CardRow({required this.cards, required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < cards.length; i++)
          Padding(
            padding: EdgeInsets.only(right: i == cards.length - 1 ? 0 : 4),
            child: CardWidget(
              card: cards[i],
              width: cardWidth,
              height: _cardHeight(cardWidth),
              enabled: false,
            ),
          ),
      ],
    );
  }
}

/// The four cards this option keeps, then the two it throws at 40% — the
/// same keep-then-dimmed-discard reading as the puzzle explain dialog.
class _KeepDiscardRow extends StatelessWidget {
  final List<PlayingCard> keep;
  final List<PlayingCard> discard;
  final double cardWidth;

  const _KeepDiscardRow({
    required this.keep,
    required this.discard,
    required this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CardRow(cards: keep, cardWidth: cardWidth),
        SizedBox(width: cardWidth * 0.32),
        Opacity(
          opacity: 0.4,
          child: _CardRow(cards: discard, cardWidth: cardWidth),
        ),
      ],
    );
  }
}

/// One side of the discard comparison: the two cards thrown and what they
/// were worth on average.
class _DiscardPanel extends StatelessWidget {
  final String label;
  final DiscardOption option;
  final bool isBest;

  const _DiscardPanel({
    required this.label,
    required this.option,
    this.isBest = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final crib = option.expectedCribValue;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isBest
            ? colors.evOptimal.withValues(alpha: 0.08)
            : colors.surfaceDim,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isBest
              ? colors.evOptimal.withValues(alpha: 0.35)
              : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isBest ? colors.evOptimal : colors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 7),
          _CardRow(cards: option.discard, cardWidth: _discardCardWidth),
          const SizedBox(height: 8),
          Text(
            '${option.expectedCombinedValue.toStringAsFixed(2)} avg',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'hand ${option.expectedHandValue.toStringAsFixed(1)} · '
            'crib ${crib > 0 ? '+' : ''}${crib.toStringAsFixed(1)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Every discard ranked, as a data table (design language §4): hairline
/// separators, right-aligned tabular values, tap a row for the reasoning.
class _OptionsList extends StatelessWidget {
  final PlayerRoundAnalysis analysis;

  const _OptionsList({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    // Use all 15 ranked options when available, otherwise fall back to optimal + player
    final List<DiscardOption> options;
    if (analysis.allOptions != null && analysis.allOptions!.isNotEmpty) {
      options = analysis.allOptions!;
    } else {
      options = {analysis.optimalDiscard, analysis.playerDiscard}.toList();
    }

    final mine = analysis.discarded.toSet();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Column(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: colors.border),
            _OptionRow(
              rank: i + 1,
              option: options[i],
              isPlayerChoice:
                  options[i].discard.toSet().length == mine.length &&
                  options[i].discard.toSet().containsAll(mine),
              isOptimal: i == 0,
              dealtHand: analysis.dealtHand,
              isDealer: analysis.isDealer,
            ),
          ],
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
    showCcDialog(
      context: context,
      builder: (_) => ExplainDialog(
        rank: rank,
        keep: option.keep,
        discard: option.discard,
        hand: dealtHand,
        isDealer: isDealer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: () => _showExplain(context),
      child: Container(
        // Your own row gets the "you" wash from the data-table spec.
        color: isPlayerChoice
            ? colors.pegPlayer.withValues(alpha: 0.08)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$rank',
                style: TextStyle(
                  color: isOptimal ? colors.evOptimal : colors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            // Scales down rather than overflowing on a narrow phone.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: _KeepDiscardRow(
                  keep: option.keep,
                  discard: option.discard,
                  cardWidth: _optionCardWidth,
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (isOptimal)
              _Chip(label: 'BEST', color: colors.evOptimal)
            else if (isPlayerChoice)
              const _Chip(label: 'YOU'),
            const SizedBox(width: 8),
            Text(
              option.expectedCombinedValue.toStringAsFixed(2),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.info_outline, color: colors.textDisabled, size: 15),
          ],
        ),
      ),
    );
  }
}
