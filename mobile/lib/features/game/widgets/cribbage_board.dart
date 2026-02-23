import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';

/// Perimeter cribbage board that wraps around three edges (left, top, right)
/// of its child content. The path runs from bottom-left → up → across top →
/// down to bottom-right. Two parallel tracks: outer (player/gold) and
/// inner (opponent/white).
class PerimeterCribbageBoard extends StatefulWidget {
  static const double boardWidth = 34.0;

  final int playerScore;
  final int opponentScore;
  final bool isDealer;
  final Widget child;

  const PerimeterCribbageBoard({
    super.key,
    required this.playerScore,
    required this.opponentScore,
    this.isDealer = false,
    required this.child,
  });

  @override
  State<PerimeterCribbageBoard> createState() => _PerimeterCribbageBoardState();
}

class _PerimeterCribbageBoardState extends State<PerimeterCribbageBoard>
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
  void didUpdateWidget(PerimeterCribbageBoard oldWidget) {
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
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: _PerimeterBoardPainter(
            playerScore: _playerAnim.value,
            opponentScore: _opponentAnim.value,
            colors: colors,
          ),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(
          left: PerimeterCribbageBoard.boardWidth,
          top: PerimeterCribbageBoard.boardWidth,
          right: PerimeterCribbageBoard.boardWidth,
        ),
        child: widget.child,
      ),
    );
  }
}

class _PerimeterBoardPainter extends CustomPainter {
  final double playerScore;
  final double opponentScore;
  final AppColors colors;

  static const int _totalHoles = 121;
  static const int _groupSize = 5;
  static const double _holeRadius = 1.8;
  static const double _pegRadius = 4.0;
  static const double _boardWidth = PerimeterCribbageBoard.boardWidth;
  static const double _cornerRadius = 17.0;

  // Track offsets from strip center line
  static const double _outerTrackOffset = 6.5; // player — closer to edge
  static const double _innerTrackOffset = -6.5; // opponent — closer to content

  _PerimeterBoardPainter({
    required this.playerScore,
    required this.opponentScore,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBoardBackground(canvas, size);
    _drawBoardBorder(canvas, size);

    final outerHoles = _calculateHolePositions(size, _outerTrackOffset);
    final innerHoles = _calculateHolePositions(size, _innerTrackOffset);

    _drawHoles(canvas, outerHoles);
    _drawHoles(canvas, innerHoles);
    _drawMilestones(canvas, size, outerHoles, innerHoles);

    // Draw pegs
    final playerPos = _scoreToPosition(playerScore, outerHoles);
    final opponentPos = _scoreToPosition(opponentScore, innerHoles);

    _drawPeg(canvas, opponentPos, colors.pegOpponent);
    _drawPeg(canvas, playerPos, colors.pegPlayer);
  }

  /// Draws the three-sided board frame (left, top, right) with rounded top corners.
  void _drawBoardBackground(Canvas canvas, Size size) {
    final path = _buildFramePath(size);

    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, _boardWidth),
        [colors.boardPrimary, colors.boardSecondary],
      );
    canvas.drawPath(path, paint);
  }

  void _drawBoardBorder(Canvas canvas, Size size) {
    final path = _buildFramePath(size);

    final paint = Paint()
      ..color = colors.boardHole.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, paint);
  }

  /// Three-sided open frame: left strip, top strip (with rounded corners), right strip.
  Path _buildFramePath(Size size) {
    final w = size.width;
    final h = size.height;
    final bw = _boardWidth;
    final r = _cornerRadius;
    final ir = r - bw; // inner corner radius (may be <= 0)

    final path = Path();

    // Outer edge: start bottom-left, go up, arc top-left, across top, arc top-right, down
    path.moveTo(0, h);
    path.lineTo(0, r);
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));
    path.lineTo(w - r, 0);
    path.arcToPoint(Offset(w, r), radius: Radius.circular(r));
    path.lineTo(w, h);

    // Inner edge: bottom-right inner, up, arc top-right inner, across, arc top-left inner, down
    path.lineTo(w - bw, h);
    if (ir > 0) {
      path.lineTo(w - bw, r);
      path.arcToPoint(
        Offset(w - r, bw),
        radius: Radius.circular(ir),
        clockwise: false,
      );
      path.lineTo(r, bw);
      path.arcToPoint(
        Offset(bw, r),
        radius: Radius.circular(ir),
        clockwise: false,
      );
    } else {
      path.lineTo(w - bw, bw);
      path.lineTo(bw, bw);
    }
    path.lineTo(bw, h);
    path.close();

    return path;
  }

  /// Total path length across all 5 segments.
  double _totalPathLength(Size size) {
    final segs = _segmentLengths(size);
    return segs.fold(0.0, (a, b) => a + b);
  }

  /// Returns lengths of [leftEdge, topLeftArc, topEdge, topRightArc, rightEdge].
  List<double> _segmentLengths(Size size) {
    final w = size.width;
    final h = size.height;
    final r = _cornerRadius;

    final leftLen = h - r; // bottom of left strip to start of arc
    final arcLen = (pi / 2) * r; // quarter circle
    final topLen = w - 2 * r; // between arcs
    final rightLen = h - r; // end of arc to bottom of right strip

    return [leftLen, arcLen, topLen, arcLen, rightLen];
  }

  /// Maps a linear distance along the path to a 2D offset on the center line
  /// of the board strip, shifted by [trackOffset] perpendicular to the path.
  Offset _pathDistanceToOffset(double d, Size size, double trackOffset) {
    final w = size.width;
    final h = size.height;
    final bw = _boardWidth;
    final r = _cornerRadius;
    final center = bw / 2; // center of strip

    final segs = _segmentLengths(size);
    double remaining = d;

    // Segment 0: Left edge — going up from (0, h) to (0, r)
    if (remaining <= segs[0]) {
      final t = remaining / segs[0];
      final y = h - t * (h - r);
      return Offset(center + trackOffset, y);
    }
    remaining -= segs[0];

    // Segment 1: Top-left arc — quarter circle from (0, r) to (r, 0)
    if (remaining <= segs[1]) {
      final t = remaining / segs[1];
      final angle = pi + t * (pi / 2); // from pi (left) to 3pi/2 (top)
      final cx = r; // arc center
      final cy = r;
      final pathX = cx + r * cos(angle);
      final pathY = cy + r * sin(angle);
      final nx = cos(angle);
      final ny = sin(angle);
      return Offset(
        pathX + nx * (center - r) + nx * trackOffset,
        pathY + ny * (center - r) + ny * trackOffset,
      );
    }
    remaining -= segs[1];

    // Segment 2: Top edge — going right from (r, 0) to (w-r, 0)
    if (remaining <= segs[2]) {
      final t = remaining / segs[2];
      final x = r + t * (w - 2 * r);
      return Offset(x, center + trackOffset);
    }
    remaining -= segs[2];

    // Segment 3: Top-right arc — quarter circle from (w-r, 0) to (w, r)
    if (remaining <= segs[3]) {
      final t = remaining / segs[3];
      final angle = (3 * pi / 2) + t * (pi / 2); // from 3pi/2 to 2pi
      final cx = w - r;
      final cy = r;
      final pathX = cx + r * cos(angle);
      final pathY = cy + r * sin(angle);
      final nx = cos(angle);
      final ny = sin(angle);
      return Offset(
        pathX + nx * (center - r) + nx * trackOffset,
        pathY + ny * (center - r) + ny * trackOffset,
      );
    }
    remaining -= segs[3];

    // Segment 4: Right edge — going down from (w, r) to (w, h)
    {
      final t = (remaining / segs[4]).clamp(0.0, 1.0);
      final y = r + t * (h - r);
      return Offset(w - center + trackOffset, y);
    }
  }

  /// Distribute 121 holes along the path with 5-hole group gaps.
  List<Offset> _calculateHolePositions(Size size, double trackOffset) {
    final totalLen = _totalPathLength(size);

    // Calculate spacing with group gaps
    final numGroups = (_totalHoles / _groupSize).ceil();
    const groupGap = 3.0;
    final totalGaps = _totalHoles - 1 + (numGroups - 1) * (groupGap / 2);
    final spacing = totalLen / totalGaps;

    // Build linear positions first
    final linearPositions = <double>[];
    double pos = 0;
    for (int i = 0; i < _totalHoles; i++) {
      linearPositions.add(pos);
      pos += spacing;
      if ((i + 1) % _groupSize == 0 && i < _totalHoles - 1) {
        pos += spacing * (groupGap / 2);
      }
    }

    // Normalize to fit total path length
    if (linearPositions.isNotEmpty && linearPositions.last > 0) {
      final scale = totalLen / linearPositions.last;
      for (int i = 0; i < linearPositions.length; i++) {
        linearPositions[i] *= scale;
      }
    }

    // Map to 2D offsets
    return linearPositions
        .map((d) => _pathDistanceToOffset(d, size, trackOffset))
        .toList();
  }

  Offset _scoreToPosition(double score, List<Offset> holes) {
    if (score <= 0 || holes.isEmpty) return holes.isNotEmpty ? holes[0] : Offset.zero;
    final clamped = score.clamp(0.0, 121.0);
    final intScore = clamped.floor();
    final fraction = clamped - intScore;

    if (intScore >= holes.length) return holes.last;
    if (intScore == 0) return Offset.lerp(holes[0], holes[0], fraction)!;

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
    List<Offset> outerHoles,
    List<Offset> innerHoles,
  ) {
    final milestones = [31, 61, 91, 121];
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final m in milestones) {
      if (m - 1 >= outerHoles.length) continue;

      // Use the midpoint between outer and inner hole for label placement
      final outerPt = outerHoles[m - 1];
      final innerPt = innerHoles[m - 1];
      final mid = Offset(
        (outerPt.dx + innerPt.dx) / 2,
        (outerPt.dy + innerPt.dy) / 2,
      );

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
    // Glow
    canvas.drawCircle(
      center,
      _pegRadius + 2,
      Paint()..color = color.withValues(alpha: 0.3),
    );
    // Body
    canvas.drawCircle(center, _pegRadius, Paint()..color = color);
    // Highlight
    canvas.drawCircle(
      Offset(center.dx - 0.7, center.dy - 0.7),
      _pegRadius * 0.4,
      Paint()..color = colors.textPrimary.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_PerimeterBoardPainter oldDelegate) =>
      playerScore != oldDelegate.playerScore ||
      opponentScore != oldDelegate.opponentScore ||
      colors != oldDelegate.colors;
}
