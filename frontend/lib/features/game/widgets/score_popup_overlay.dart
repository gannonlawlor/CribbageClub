import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../animation/animation_event.dart';
import '../state/game_providers.dart';

/// Overlay that shows animated "+N" popups when scores change.
/// Player scores appear near the bottom, opponent scores near the top.
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
  final List<_PopupEntry> _activePopups = [];
  int _nextId = 0;

  @override
  void initState() {
    super.initState();
    final controller = ref.read(gameAnimationProvider(widget.gameId));
    controller.addListener(_onAnimationEvent);
  }

  @override
  void dispose() {
    // Dispose all active animation controllers
    for (final popup in _activePopups) {
      popup.controller.dispose();
    }
    super.dispose();
  }

  void _onAnimationEvent() {
    final controller = ref.read(gameAnimationProvider(widget.gameId));
    for (final event in controller.events) {
      if (event is ScoreChangedEvent) {
        _addPopup(event);
      }
    }
  }

  void _addPopup(ScoreChangedEvent event) {
    final id = _nextId++;
    final isPlayer = event.playerId == widget.playerId;

    // Count existing popups in the same zone for stacking
    final sameZoneCount = _activePopups
        .where((p) => p.isPlayer == isPlayer)
        .length;

    final animController = AnimationController(
      vsync: this,
      duration: AppTheme.scorePopupDuration,
    );

    final entry = _PopupEntry(
      id: id,
      event: event,
      isPlayer: isPlayer,
      controller: animController,
      stackOffset: sameZoneCount,
    );

    setState(() {
      _activePopups.add(entry);
    });

    animController.forward().then((_) {
      if (mounted) {
        setState(() {
          _activePopups.removeWhere((p) => p.id == id);
        });
        animController.dispose();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to animation controller changes
    ref.listen(gameAnimationProvider(widget.gameId), (_, controller) {
      // The listener is already attached in initState
    });

    return Stack(
      children: _activePopups.map((popup) {
        return _ScorePopupWidget(
          key: ValueKey(popup.id),
          entry: popup,
        );
      }).toList(),
    );
  }
}

class _PopupEntry {
  final int id;
  final ScoreChangedEvent event;
  final bool isPlayer;
  final AnimationController controller;
  final int stackOffset;

  const _PopupEntry({
    required this.id,
    required this.event,
    required this.isPlayer,
    required this.controller,
    required this.stackOffset,
  });
}

class _ScorePopupWidget extends StatelessWidget {
  final _PopupEntry entry;

  const _ScorePopupWidget({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final slideUp = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.5),
    ).animate(CurvedAnimation(
      parent: entry.controller,
      curve: Curves.easeOut,
    ));

    final fade = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: entry.controller,
      // Hold fully visible for first 60%, then fade out
      curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
    ));

    final scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.5, end: 1.2).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 50,
      ),
    ]).animate(entry.controller);

    // Position: player popups near bottom, opponent near top
    final baseVertical = entry.isPlayer ? 0.55 : 0.05;
    final stackShift = entry.stackOffset * 0.06;

    return Positioned.fill(
      child: Align(
        alignment: Alignment(0, baseVertical - stackShift),
        child: SlideTransition(
          position: slideUp,
          child: FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: scale,
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
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
                color: AppTheme.goldAccent.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          Text(
            '+$points',
            style: const TextStyle(
              color: AppTheme.goldAccent,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(1, 1)),
              ],
            ),
          ),
          if (reason != null && reason.isNotEmpty)
            Text(
              reason,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                shadows: const [
                  Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(1, 1)),
                ],
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
