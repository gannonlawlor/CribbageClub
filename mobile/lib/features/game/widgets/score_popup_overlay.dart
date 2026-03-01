import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/constants.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/services/settings_provider.dart';
import '../animation/animation_event.dart';
import '../state/game_providers.dart';

/// Overlay that shows animated "+N" popups when scores change.
/// Consecutive same-player events are coalesced into a single popup
/// showing all scoring components and the accumulated total.
class ScorePopupOverlay extends ConsumerStatefulWidget {
  final String gameId;
  final String playerId;
  final String opponentName;

  const ScorePopupOverlay({
    super.key,
    required this.gameId,
    required this.playerId,
    required this.opponentName,
  });

  @override
  ConsumerState<ScorePopupOverlay> createState() => _ScorePopupOverlayState();
}

class _ScorePopupOverlayState extends ConsumerState<ScorePopupOverlay>
    with TickerProviderStateMixin {
  /// Currently visible popup (only one at a time).
  _CoalescedPopup? _activePopup;

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
        // Live-merge: if active popup is for the same player, absorb the event
        final active = _activePopup;
        if (active != null && event.playerId == active.playerId) {
          _liveMerge(active, event);
          continue;
        }
        _queue.add(event);
      }
    }
    _processQueue();
  }

  /// Absorb a new event into the active popup: append component, restart animation.
  void _liveMerge(_CoalescedPopup popup, ScoreChangedEvent event) {
    popup.components.add(_ScoreComponent(
      source: event.source,
      reason: event.reason,
      points: event.points,
    ));

    // Dispose old controller, create new one with extended duration
    final oldController = popup.controller;
    final newDuration = _computeDuration(popup.components.length);
    final newController = AnimationController(
      vsync: this,
      duration: newDuration,
    );
    popup.controller = newController;
    oldController.dispose();

    // Bump ID so the widget rebuilds with fresh animations
    popup.id = _nextId++;

    setState(() {});
    newController.forward().then((_) {
      if (!mounted) return;
      _onPopupComplete(popup);
    });
  }

  void _processQueue() {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;
    _showNext();
  }

  /// Pop the first event and consume all consecutive same-player events.
  _CoalescedPopup _dequeueCoalesced() {
    final first = _queue.removeAt(0);
    final components = <_ScoreComponent>[
      _ScoreComponent(
        source: first.source,
        reason: first.reason,
        points: first.points,
      ),
    ];

    // Consume consecutive same-player events
    while (_queue.isNotEmpty && _queue.first.playerId == first.playerId) {
      final next = _queue.removeAt(0);
      components.add(_ScoreComponent(
        source: next.source,
        reason: next.reason,
        points: next.points,
      ));
    }

    return _CoalescedPopup(
      id: _nextId++,
      playerId: first.playerId,
      isPlayer: first.playerId == widget.playerId,
      opponentName: widget.opponentName,
      components: components,
    );
  }

  Duration _computeDuration(int componentCount) {
    final extraComponents = (componentCount - 1).clamp(0, 3);
    final baseDuration = AppConstants.scorePopupDuration +
        AppConstants.scorePopupExtraDuration * extraComponents;
    final settings = ref.read(settingsProvider);
    return settings.scaleDuration(baseDuration);
  }

  void _showNext() {
    if (_queue.isEmpty) {
      _isProcessing = false;
      return;
    }

    final popup = _dequeueCoalesced();
    final duration = _computeDuration(popup.components.length);

    final animController = AnimationController(
      vsync: this,
      duration: duration,
    );
    popup.controller = animController;

    setState(() {
      _activePopup = popup;
    });

    animController.forward().then((_) {
      if (!mounted) return;
      _onPopupComplete(popup);
    });
  }

  void _onPopupComplete(_CoalescedPopup popup) {
    // Only act if this popup is still the active one (not replaced by live-merge)
    if (_activePopup?.id != popup.id) return;

    setState(() {
      _activePopup = null;
    });
    popup.controller.dispose();

    final settings = ref.read(settingsProvider);
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
  }

  @override
  Widget build(BuildContext context) {
    // Keep provider listened to so initState listener stays alive
    ref.listen(gameAnimationProvider(widget.gameId), (_, controller) {});

    final popup = _activePopup;
    if (popup == null) return const SizedBox.shrink();

    return Stack(
      children: [
        _ScorePopupWidget(key: ValueKey(popup.id), popup: popup),
      ],
    );
  }
}

class _ScoreComponent {
  final ScoreSource? source;
  final String? reason;
  final int points;

  const _ScoreComponent({
    required this.source,
    required this.reason,
    required this.points,
  });
}

class _CoalescedPopup {
  int id;
  final String playerId;
  final bool isPlayer;
  final String opponentName;
  final List<_ScoreComponent> components;
  late AnimationController controller;

  _CoalescedPopup({
    required this.id,
    required this.playerId,
    required this.isPlayer,
    required this.opponentName,
    required this.components,
  });

  int get totalPoints => components.fold(0, (sum, c) => sum + c.points);
}

class _ScorePopupWidget extends StatelessWidget {
  final _CoalescedPopup popup;

  const _ScorePopupWidget({super.key, required this.popup});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final slideUp = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.5),
    ).animate(
        CurvedAnimation(parent: popup.controller, curve: Curves.easeOut));

    final fade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: popup.controller,
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
    ]).animate(popup.controller);

    // Position: player popups near bottom, opponent near top
    final baseVertical = popup.isPlayer ? 0.55 : 0.05;

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
    final pegColor = popup.isPlayer ? colors.pegPlayer : colors.pegOpponent;
    final playerLabel = popup.isPlayer ? 'You' : popup.opponentName;
    final isSingle = popup.components.length == 1;

    if (isSingle) {
      return _buildSingleContent(colors, pegColor, playerLabel);
    }
    return _buildMultiContent(colors, pegColor, playerLabel);
  }

  /// Single component: same layout as before.
  Widget _buildSingleContent(
      AppColors colors, Color pegColor, String playerLabel) {
    final comp = popup.components.first;
    final sourceLabel = _sourceLabel(comp.source);

    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            playerLabel,
            style: TextStyle(
              color: pegColor.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (sourceLabel != null)
            Text(
              sourceLabel,
              style: TextStyle(
                color: pegColor.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          Text(
            '+${comp.points}',
            style: TextStyle(
              color: pegColor,
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
          if (comp.reason != null && comp.reason!.isNotEmpty)
            Text(
              comp.reason!,
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

  /// Multiple components: total on top, then each component line below.
  Widget _buildMultiContent(
      AppColors colors, Color pegColor, String playerLabel) {
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            playerLabel,
            style: TextStyle(
              color: pegColor.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '+${popup.totalPoints}',
            style: TextStyle(
              color: pegColor,
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
          for (final comp in popup.components) _buildComponentLine(colors, pegColor, comp),
        ],
      ),
    );
  }

  Widget _buildComponentLine(
      AppColors colors, Color pegColor, _ScoreComponent comp) {
    final label = _sourceLabel(comp.source);
    final reason = comp.reason;
    final hasReason = reason != null && reason.isNotEmpty;

    // Build line text: "Hand: +8 — 2 fifteens, 1 pair" or "+3 — pair" or "+2"
    final buffer = StringBuffer();
    if (label != null) {
      buffer.write('$label: ');
    }
    buffer.write('+${comp.points}');
    if (hasReason) {
      buffer.write(' \u2014 $reason');
    }

    return Text(
      buffer.toString(),
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
    );
  }

  static String? _sourceLabel(ScoreSource? source) {
    if (source == null) return null;
    return switch (source) {
      ScoreSource.pegging => null,
      ScoreSource.nobs => null,
      ScoreSource.hand => 'Hand',
      ScoreSource.crib => 'Crib',
      ScoreSource.go => null,
    };
  }
}
