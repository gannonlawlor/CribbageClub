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

  /// Distance from the top of the stack to the underside of the opponent's
  /// bar — their bubble hangs from there. Null falls back to [alignmentY].
  final double? opponentTop;

  /// Distance from the bottom of the stack to the top of the player's bar —
  /// their bubble sits on there. Null falls back to [alignmentY].
  final double? playerBottom;

  /// Inset from the right edge, so the bubble lines up with the score it
  /// belongs to rather than the middle of the bar.
  final double rightInset;

  /// Fallback position when the caller doesn't know where the bars are (the
  /// tablet layout), as a stack alignment y (-1 top, 0 middle, 1 bottom).
  final double alignmentY;

  const ScorePopupOverlay({
    super.key,
    required this.gameId,
    required this.playerId,
    required this.opponentName,
    this.opponentTop,
    this.playerBottom,
    this.rightInset = 12,
    this.alignmentY = 0,
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
    // Without this the animation controller keeps calling back into a dead
    // widget, and the callback reads `ref` — "Cannot use ref after the widget
    // was disposed" every time a game update lands after you navigate away.
    ref
        .read(gameAnimationProvider(widget.gameId))
        .removeListener(_onAnimationEvent);
    _activePopup?.controller.dispose();
    super.dispose();
  }

  void _onAnimationEvent() {
    final controller = ref.read(gameAnimationProvider(widget.gameId));
    for (final event in controller.events) {
      if (event is ScoreChangedEvent) {
        // Live-merge: same player absorbs into the active popup — but a hand
        // and a crib count are separate scores and each keep their own pill,
        // so the crib total never rides along on the hand's.
        final active = _activePopup;
        if (active != null &&
            event.playerId == active.playerId &&
            !_isCount(event.source) &&
            !active.hasCount) {
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
    popup.components.add(
      _ScoreComponent(
        source: event.source,
        reason: event.reason,
        points: event.points,
      ),
    );

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

  /// A hand or crib count stands on its own; pegging scores in a burst
  /// coalesce.
  static bool _isCount(ScoreSource? source) =>
      source == ScoreSource.hand || source == ScoreSource.crib;

  /// Pop the first event and consume consecutive same-player events — unless
  /// this one is a count, which always gets its own pill.
  _CoalescedPopup _dequeueCoalesced() {
    final first = _queue.removeAt(0);
    final components = <_ScoreComponent>[
      _ScoreComponent(
        source: first.source,
        reason: first.reason,
        points: first.points,
      ),
    ];

    // Consume consecutive same-player pegging events; a count breaks the run.
    while (!_isCount(first.source) &&
        _queue.isNotEmpty &&
        _queue.first.playerId == first.playerId &&
        !_isCount(_queue.first.source)) {
      final next = _queue.removeAt(0);
      components.add(
        _ScoreComponent(
          source: next.source,
          reason: next.reason,
          points: next.points,
        ),
      );
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
    final baseDuration =
        AppConstants.scorePopupDuration +
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

    final animController = AnimationController(vsync: this, duration: duration);
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

    // A real beat between two pills, or a run of pegging scores reads as one
    // blur rather than separate things that happened.
    final settings = ref.read(settingsProvider);
    final gapDuration = _queue.isNotEmpty
        ? settings.scaleDuration(AppConstants.scorePopupGap)
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
        _ScoreBubble(
          key: ValueKey(popup.id),
          popup: popup,
          opponentTop: widget.opponentTop,
          playerBottom: widget.playerBottom,
          rightInset: widget.rightInset,
          alignmentY: widget.alignmentY,
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

  /// True once this pill holds a hand or crib count — nothing else joins it.
  bool get hasCount => components.any(
    (c) => c.source == ScoreSource.hand || c.source == ScoreSource.crib,
  );
}

/// Score bubble (design language §4): the points land beside the score they
/// changed — hanging under the opponent's bar, sitting on top of yours — with
/// a tail pointing at that bar. The number leads; the reason sits small
/// underneath it.
class _ScoreBubble extends StatelessWidget {
  final _CoalescedPopup popup;
  final double? opponentTop;
  final double? playerBottom;
  final double rightInset;
  final double alignmentY;

  /// How far in from the bubble's right edge the tail sits. With the bubble's
  /// right edge flush to the bar's, this puts the tail over the score, which
  /// sits 12pt inside the bar and runs 26pt wide at two digits.
  static const double _tailInset = 17;

  const _ScoreBubble({
    super.key,
    required this.popup,
    required this.opponentTop,
    required this.playerBottom,
    required this.rightInset,
    required this.alignmentY,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final anchor = popup.isPlayer ? playerBottom : opponentTop;

    // Each bubble grows out of its own bar: yours pushes up off it, the
    // opponent's drops down from theirs.
    final from = popup.isPlayer
        ? const Offset(0, 0.45)
        : const Offset(0, -0.45);
    final slide = Tween<Offset>(begin: from, end: Offset.zero).animate(
      CurvedAnimation(
        parent: popup.controller,
        curve: const Interval(0, 0.2, curve: Curves.easeOutBack),
      ),
    );

    final fade =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 12),
          TweenSequenceItem(tween: ConstantTween(1.0), weight: 68),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
        ]).animate(
          CurvedAnimation(parent: popup.controller, curve: Curves.easeInOut),
        );

    final bubble = SlideTransition(
      position: slide,
      child: FadeTransition(opacity: fade, child: _buildBubble(colors)),
    );

    // No anchor (tablet layout) — fall back to a free-floating position.
    if (anchor == null) {
      return Positioned.fill(
        child: Align(alignment: Alignment(0, alignmentY), child: bubble),
      );
    }

    return Positioned(
      right: rightInset,
      top: popup.isPlayer ? null : anchor,
      bottom: popup.isPlayer ? anchor : null,
      child: bubble,
    );
  }

  Widget _buildBubble(AppColors colors) {
    final fill = popup.isPlayer ? colors.pegPlayer : colors.pegOpponent;
    const onFill = Color(0xFF16240C);
    const onFillOpp = Color(0xFF26221E);
    final textColor = popup.isPlayer ? onFill : onFillOpp;
    final detail = _detailText();
    // The opponent's bubble hangs below their bar, so its tail points up.
    final tailUp = !popup.isPlayer;

    final body = Container(
      constraints: const BoxConstraints(minWidth: 64, maxWidth: 200),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 9),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+${popup.totalPoints}',
            style: TextStyle(
              color: textColor,
              fontSize: 26,
              height: 1,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: 3),
            Text(
              detail,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.72),
                fontSize: 10.5,
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );

    final tail = Padding(
      padding: const EdgeInsets.only(right: _tailInset),
      child: CustomPaint(
        size: const Size(16, 7),
        painter: _BubbleTail(color: fill, pointsUp: tailUp),
      ),
    );

    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: tailUp ? [tail, body] : [body, tail],
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

/// The little pointer that ties a bubble to the score bar it came from.
class _BubbleTail extends CustomPainter {
  final Color color;
  final bool pointsUp;

  const _BubbleTail({required this.color, required this.pointsUp});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointsUp) {
      path.moveTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BubbleTail old) =>
      old.color != color || old.pointsUp != pointsUp;
}
