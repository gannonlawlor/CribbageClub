import 'dart:async';
import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';

class TurnTimer extends StatefulWidget {
  final DateTime? turnStartedAt;
  final int turnTimeLimitMs;
  final int timeBankMs;
  final bool isActivePlayer;
  final bool isTimed;

  const TurnTimer({
    super.key,
    required this.turnStartedAt,
    required this.turnTimeLimitMs,
    required this.timeBankMs,
    required this.isActivePlayer,
    required this.isTimed,
  });

  @override
  State<TurnTimer> createState() => _TurnTimerState();
}

class _TurnTimerState extends State<TurnTimer> {
  Timer? _timer;
  int _remainingMs = 0;
  bool _inTimeBank = false;

  @override
  void initState() {
    super.initState();
    _computeRemaining();
    if (widget.isActivePlayer && widget.isTimed) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(TurnTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.turnStartedAt != oldWidget.turnStartedAt ||
        widget.isActivePlayer != oldWidget.isActivePlayer ||
        widget.timeBankMs != oldWidget.timeBankMs) {
      _computeRemaining();
      _timer?.cancel();
      if (widget.isActivePlayer && widget.isTimed) {
        _startTimer();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _computeRemaining();
    });
  }

  void _computeRemaining() {
    if (widget.turnStartedAt == null || !widget.isTimed) {
      setState(() {
        _remainingMs = widget.turnTimeLimitMs;
        _inTimeBank = false;
      });
      return;
    }

    final elapsed =
        DateTime.now().difference(widget.turnStartedAt!).inMilliseconds;

    if (!widget.isActivePlayer) {
      // Not counting down when it's not this player's turn
      setState(() {
        _remainingMs = widget.turnTimeLimitMs;
        _inTimeBank = false;
      });
      return;
    }

    final turnRemaining = widget.turnTimeLimitMs - elapsed;
    if (turnRemaining > 0) {
      setState(() {
        _remainingMs = turnRemaining;
        _inTimeBank = false;
      });
    } else {
      // In time bank
      final overtime = -turnRemaining;
      final bankRemaining = widget.timeBankMs - overtime;
      setState(() {
        _remainingMs = bankRemaining.clamp(0, widget.timeBankMs);
        _inTimeBank = true;
      });
    }
  }

  Color _getColor(AppColors colors) {
    if (!widget.isActivePlayer) return colors.textDisabled;
    if (_inTimeBank) return colors.error;
    final seconds = _remainingMs / 1000;
    if (seconds <= 5) return colors.error;
    if (seconds <= 15) return colors.warning;
    return colors.success;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isTimed) return const SizedBox.shrink();

    final colors = context.appColors;
    final seconds = (_remainingMs / 1000).ceil().clamp(0, 999);
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final displayTime = minutes > 0
        ? '$minutes:${secs.toString().padLeft(2, '0')}'
        : '${secs}s';
    final color = _getColor(colors);
    final label = _inTimeBank ? 'BANK' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: widget.isActivePlayer
            ? color.withValues(alpha: 0.2)
            : colors.surfaceDim,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: widget.isActivePlayer
              ? color.withValues(alpha: 0.6)
              : colors.divider,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            displayTime,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight:
                  widget.isActivePlayer ? FontWeight.bold : FontWeight.normal,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
