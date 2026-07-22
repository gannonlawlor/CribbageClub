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

  /// Distance from the top of the stack for opponent popups. When null the
  /// popup sits at a fraction of the height instead (tablet layout).
  final double? opponentTop;

  /// Distance from the bottom of the stack for the local player's popups.
  final double? playerBottom;

  const ScorePopupOverlay({
    super.key,
    required this.gameId,
    required this.playerId,
    required this.opponentName,
    this.opponentTop,
    this.playerBottom,
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
        _ScorePopupWidget(
          key: ValueKey(popup.id),
          popup: popup,
          top: popup.isPlayer ? null : widget.opponentTop,
          bottom: popup.isPlayer ? widget.playerBottom : null,
        ),
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

/// Score popup (design language §4): a pill filled with the scorer's identity
/// colour, dark text, anchored clear of the count. Rises 6px, holds, fades.
class _ScorePopupWidget extends StatelessWidget {
  final _CoalescedPopup popup;
  final double? top;
  final double? bottom;

  const _ScorePopupWidget({
    super.key,
    required this.popup,
    this.top,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final rise = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: popup.controller,
        curve: const Interval(0, 0.12, curve: Curves.easeOut),
      ),
    );

    final fade = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 12),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 68),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(
      CurvedAnimation(parent: popup.controller, curve: Curves.easeInOut),
    );

    final pill = SlideTransition(
      position: rise,
      child: FadeTransition(opacity: fade, child: _buildPill(colors)),
    );

    // Explicit anchor when the caller knows where the free bands are;
    // otherwise fall back to a fraction of the available height.
    if (top != null || bottom != null) {
      return Positioned(
        left: 0,
        right: 0,
        top: top,
        bottom: bottom,
        child: Align(alignment: Alignment.center, child: pill),
      );
    }

    return Positioned.fill(
      child: Align(
        alignment: Alignment(0, popup.isPlayer ? 0.55 : -0.55),
        child: pill,
      ),
    );
  }

  Widget _buildPill(AppColors colors) {
    final fill = popup.isPlayer ? colors.pegPlayer : colors.pegOpponent;
    const onFill = Color(0xFF16240C);
    const onFillOpp = Color(0xFF26221E);
    final textColor = popup.isPlayer ? onFill : onFillOpp;
    final detail = _detailText();

    return IgnorePointer(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x59000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+${popup.totalPoints}',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (detail != null) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.75),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// "fifteen", "Hand · 2 fifteens, 1 pair" — the why behind the number.
  String? _detailText() {
    final parts = <String>[];
    for (final comp in popup.components) {
      final label = _sourceLabel(comp.source);
      final reason = comp.reason;
      final hasReason = reason != null && reason.isNotEmpty;
      if (label != null && hasReason) {
        parts.add('$label · $reason');
      } else if (label != null) {
        parts.add(label);
      } else if (hasReason) {
        parts.add(reason);
      }
    }
    if (parts.isEmpty) return null;
    return parts.join(', ');
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
