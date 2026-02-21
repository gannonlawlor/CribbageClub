import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/constants.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/services/settings_provider.dart';
import '../animation/animation_event.dart';
import '../state/game_providers.dart';

/// Overlay that shows animated "+N" popups when scores change.
/// Popups are queued and displayed one at a time so each scoring event
/// is clearly readable, even when multiple scores happen in rapid succession.
class ScorePopupOverlay extends ConsumerStatefulWidget {
  final String gameId;
  final String playerId;

  const ScorePopupOverlay({
    super.key,
    required this.gameId,
    required this.playerId,
  });

  @override
  ConsumerState<ScorePopupOverlay> createState() => _ScorePopupOverlayState();
}

class _ScorePopupOverlayState extends ConsumerState<ScorePopupOverlay>
    with TickerProviderStateMixin {
  /// Currently visible popup (only one at a time).
  _PopupEntry? _activePopup;

  /// Queue of pending score events waiting to be shown.
  final List<ScoreChangedEvent> _queue = [];

  /// Whether we're currently showing a popup (or in the gap between popups).
  bool _isProcessing = false;

  int _nextId = 0;

  @override
  void initState() {
    super.initState();
    final controller = ref.read(gameAnimationProvider(widget.gameId));
    controller.addListener(_onAnimationEvent);
  }

  @override
  void dispose() {
    _activePopup?.controller.dispose();
    super.dispose();
  }

  void _onAnimationEvent() {
    final controller = ref.read(gameAnimationProvider(widget.gameId));
    for (final event in controller.events) {
      if (event is ScoreChangedEvent) {
        _queue.add(event);
      }
    }
    _processQueue();
  }

  void _processQueue() {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;
    _showNext();
  }

  void _showNext() {
    if (_queue.isEmpty) {
      _isProcessing = false;
      return;
    }

    final event = _queue.removeAt(0);
    final id = _nextId++;
    final isPlayer = event.playerId == widget.playerId;

    final settings = ref.read(settingsProvider);
    final scaledDuration =
        settings.scaleDuration(AppConstants.scorePopupDuration);

    final animController = AnimationController(
      vsync: this,
      duration: scaledDuration,
    );

    final entry = _PopupEntry(
      id: id,
      event: event,
      isPlayer: isPlayer,
      controller: animController,
    );

    setState(() {
      _activePopup = entry;
    });

    animController.forward().then((_) {
      if (!mounted) return;
      setState(() {
        _activePopup = null;
      });
      animController.dispose();

      // Brief gap before showing next popup so they don't blur together
      final gapDuration = _queue.isNotEmpty
          ? settings.scaleDuration(const Duration(milliseconds: 200))
          : Duration.zero;

      if (_queue.isNotEmpty) {
        Future.delayed(gapDuration, () {
          if (mounted) _showNext();
        });
      } else {
        _isProcessing = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Keep provider listened to so initState listener stays alive
    ref.listen(gameAnimationProvider(widget.gameId), (_, controller) {});

    final popup = _activePopup;
    if (popup == null) return const SizedBox.shrink();

    return Stack(
      children: [
        _ScorePopupWidget(key: ValueKey(popup.id), entry: popup),
      ],
    );
  }
}

class _PopupEntry {
  final int id;
  final ScoreChangedEvent event;
  final bool isPlayer;
  final AnimationController controller;

  const _PopupEntry({
    required this.id,
    required this.event,
    required this.isPlayer,
    required this.controller,
  });
}

class _ScorePopupWidget extends StatelessWidget {
  final _PopupEntry entry;

  const _ScorePopupWidget({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final slideUp = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.5),
    ).animate(CurvedAnimation(parent: entry.controller, curve: Curves.easeOut));

    final fade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: entry.controller,
        // Hold fully visible for first 60%, then fade out
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    final scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.5,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
    ]).animate(entry.controller);

    // Position: player popups near bottom, opponent near top
    final baseVertical = entry.isPlayer ? 0.55 : 0.05;

    return Positioned.fill(
      child: Align(
        alignment: Alignment(0, baseVertical),
        child: SlideTransition(
          position: slideUp,
          child: FadeTransition(
            opacity: fade,
            child: ScaleTransition(scale: scale, child: _buildContent(colors)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AppColors colors) {
    final points = entry.event.points;
    final reason = entry.event.reason;
    final source = entry.event.source;

    // Label for the source
    String? sourceLabel;
    if (source != null) {
      sourceLabel = switch (source) {
        ScoreSource.pegging => null, // reason already explains pegging
        ScoreSource.nobs => null, // reason is "His Nobs"
        ScoreSource.hand => 'Hand',
        ScoreSource.crib => 'Crib',
        ScoreSource.go => null,
      };
    }

    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sourceLabel != null)
            Text(
              sourceLabel,
              style: TextStyle(
                color: colors.accent.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          Text(
            '+$points',
            style: TextStyle(
              color: colors.accent,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 4,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
          if (reason != null && reason.isNotEmpty)
            Text(
              reason,
              style: TextStyle(
                color: colors.textPrimary.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                shadows: const [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 3,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
