import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';

/// Vertical cribbage board for tablet landscape — a tall narrow strip with
/// two parallel tracks running bottom→top, hairpin turn, then top→bottom.
class VerticalCribbageBoard extends StatefulWidget {
  static const double boardWidth = 90.0;

  final int playerScore;
  final int opponentScore;

  const VerticalCribbageBoard({
    super.key,
    required this.playerScore,
    required this.opponentScore,
  });

  @override
  State<VerticalCribbageBoard> createState() => _VerticalCribbageBoardState();
}

class _VerticalCribbageBoardState extends State<VerticalCribbageBoard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _playerAnim;
  late Animation<double> _opponentAnim;
  int _oldPlayerScore = 0;
  int _oldOpponentScore = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _oldPlayerScore = widget.playerScore;
    _oldOpponentScore = widget.opponentScore;
    _playerAnim = AlwaysStoppedAnimation(widget.playerScore.toDouble());
    _opponentAnim = AlwaysStoppedAnimation(widget.opponentScore.toDouble());
  }

  @override
  void didUpdateWidget(VerticalCribbageBoard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final playerDelta = (widget.playerScore - _oldPlayerScore).abs();
    final opponentDelta = (widget.opponentScore - _oldOpponentScore).abs();
    final maxDelta = playerDelta > opponentDelta ? playerDelta : opponentDelta;

    if (maxDelta == 0) return;

    final duration = Duration(milliseconds: 50 * maxDelta);
    _controller.duration = duration;

    _playerAnim = Tween<double>(
      begin: _oldPlayerScore.toDouble(),
      end: widget.playerScore.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opponentAnim = Tween<double>(
      begin: _oldOpponentScore.toDouble(),
      end: widget.opponentScore.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _oldPlayerScore = widget.playerScore;
    _oldOpponentScore = widget.opponentScore;

    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _VerticalBoardPainter(
            playerScore: _playerAnim.value,
            opponentScore: _opponentAnim.value,
            colors: colors,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _VerticalBoardPainter extends CustomPainter {
  final double playerScore;
  final double opponentScore;
  final AppColors colors;

  static const int _totalHoles = 121;
  static const int _groupSize = 5;
  static const double _holeRadius = 1.8;
  static const double _pegRadius = 4.0;
  static const double _cornerRadius = 12.0;

  // Horizontal offsets from center of each lane
  static const double _laneSpacing = 14.0;

  _VerticalBoardPainter({
    required this.playerScore,
    required this.opponentScore,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawBorder(canvas, size);

    final playerHoles = _calculateHolePositions(size, -_laneSpacing / 2);
    final opponentHoles = _calculateHolePositions(size, _laneSpacing / 2);

    _drawHoles(canvas, playerHoles);
    _drawHoles(canvas, opponentHoles);
    _drawMilestones(canvas, size, playerHoles, opponentHoles);

    final playerPos = _scoreToPosition(playerScore, playerHoles);
    final opponentPos = _scoreToPosition(opponentScore, opponentHoles);

    _drawPeg(canvas, opponentPos, colors.pegOpponent);
    _drawPeg(canvas, playerPos, colors.pegPlayer);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(_cornerRadius),
    );
    final paint = Paint()
      ..shader = ui.Gradient.linear(Offset.zero, Offset(size.width, 0), [
        colors.boardPrimary,
        colors.boardSecondary,
      ]);
    canvas.drawRRect(rect, paint);
  }

  void _drawBorder(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(_cornerRadius),
    );
    final paint = Paint()
      ..color = colors.boardHole.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rect, paint);
  }

  /// Path: bottom→top on left lane, semicircle at top, top→bottom on right lane.
  /// Total: leftStraight + semicircle + rightStraight.
  double _totalPathLength(Size size) {
    final margin = 16.0;
    final straightLen = size.height - 2 * margin;
    final arcLen = pi * _laneSpacing / 2;
    return straightLen + arcLen + straightLen;
  }

  List<double> _segmentLengths(Size size) {
    final margin = 16.0;
    final straightLen = size.height - 2 * margin;
    final arcLen = pi * _laneSpacing / 2;
    return [straightLen, arcLen, straightLen];
  }

  Offset _pathDistanceToOffset(double d, Size size, double trackOffset) {
    final margin = 16.0;
    final centerX = size.width / 2;
    final straightLen = size.height - 2 * margin;
    final segs = _segmentLengths(size);
    double remaining = d;

    // Segment 0: left lane, bottom→top
    if (remaining <= segs[0]) {
      final t = remaining / segs[0];
      final x = centerX - _laneSpacing / 2 + trackOffset;
      final y = size.height - margin - t * straightLen;
      return Offset(x, y);
    }
    remaining -= segs[0];

    // Segment 1: semicircle at top from left lane to right lane
    if (remaining <= segs[1]) {
      final t = remaining / segs[1];
      final angle = pi + t * pi; // from pi (left) to 2*pi (right)
      final cx = centerX;
      final cy = margin;
      final r = _laneSpacing / 2;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      // Track offset perpendicular to the arc (radial direction)
      final nx = cos(angle);
      final ny = sin(angle);
      return Offset(x + nx * trackOffset, y + ny * trackOffset);
    }
    remaining -= segs[1];

    // Segment 2: right lane, top→bottom
    {
      final t = (remaining / segs[2]).clamp(0.0, 1.0);
      final x = centerX + _laneSpacing / 2 - trackOffset;
      final y = margin + t * straightLen;
      return Offset(x, y);
    }
  }

  List<Offset> _calculateHolePositions(Size size, double trackOffset) {
    final totalLen = _totalPathLength(size);

    final numGroups = (_totalHoles / _groupSize).ceil();
    const groupGap = 3.0;
    final totalGaps = _totalHoles - 1 + (numGroups - 1) * (groupGap / 2);
    final spacing = totalLen / totalGaps;

    final linearPositions = <double>[];
    double pos = 0;
    for (int i = 0; i < _totalHoles; i++) {
      linearPositions.add(pos);
      pos += spacing;
      if ((i + 1) % _groupSize == 0 && i < _totalHoles - 1) {
        pos += spacing * (groupGap / 2);
      }
    }

    if (linearPositions.isNotEmpty && linearPositions.last > 0) {
      final scale = totalLen / linearPositions.last;
      for (int i = 0; i < linearPositions.length; i++) {
        linearPositions[i] *= scale;
      }
    }

    return linearPositions
        .map((d) => _pathDistanceToOffset(d, size, trackOffset))
        .toList();
  }

  Offset _scoreToPosition(double score, List<Offset> holes) {
    if (score <= 0 || holes.isEmpty) {
      return holes.isNotEmpty ? holes[0] : Offset.zero;
    }
    final clamped = score.clamp(0.0, 121.0);
    final intScore = clamped.floor();
    final fraction = clamped - intScore;

    if (intScore >= holes.length) return holes.last;
    if (intScore == 0) return holes[0];

    final a = holes[intScore - 1];
    final b = intScore < holes.length ? holes[intScore] : holes.last;
    return Offset.lerp(a, b, fraction)!;
  }

  void _drawHoles(Canvas canvas, List<Offset> holes) {
    final paint = Paint()..color = colors.boardHole;
    for (final hole in holes) {
      canvas.drawCircle(hole, _holeRadius, paint);
    }
  }

  void _drawMilestones(
    Canvas canvas,
    Size size,
    List<Offset> playerHoles,
    List<Offset> opponentHoles,
  ) {
    final milestones = [31, 61, 91, 121];
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final m in milestones) {
      if (m - 1 >= playerHoles.length) continue;

      final p = playerHoles[m - 1];
      final o = opponentHoles[m - 1];
      final mid = Offset((p.dx + o.dx) / 2, (p.dy + o.dy) / 2);

      textPainter.text = TextSpan(
        text: '$m',
        style: TextStyle(
          color: colors.textPrimary.withValues(alpha: 0.45),
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(mid.dx - textPainter.width / 2, mid.dy - textPainter.height / 2),
      );
    }
  }

  void _drawPeg(Canvas canvas, Offset center, Color color) {
    canvas.drawCircle(
      center,
      _pegRadius + 2,
      Paint()..color = color.withValues(alpha: 0.3),
    );
    canvas.drawCircle(center, _pegRadius, Paint()..color = color);
    canvas.drawCircle(
      Offset(center.dx - 0.7, center.dy - 0.7),
      _pegRadius * 0.4,
      Paint()..color = colors.textPrimary.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_VerticalBoardPainter oldDelegate) =>
      playerScore != oldDelegate.playerScore ||
      opponentScore != oldDelegate.opponentScore ||
      colors != oldDelegate.colors;
}
