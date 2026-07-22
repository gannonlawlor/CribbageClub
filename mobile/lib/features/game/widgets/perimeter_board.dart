import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';

/// Geometry for the perimeter peg board. The game screen reads these to inset
/// its own content so nothing lands on the track.
class BoardMetrics {
  BoardMetrics._();

  /// Distance from the screen edge to the outer lane.
  static const double edgeInset = 8;
  static const double holeSize = 7;

  /// Space between the two lanes.
  static const double laneGap = 5;

  /// Gap inserted after every fifth hole, like a real board.
  static const double groupGap = 4;
  static const double pegSize = 10;

  /// Horizontal inset of the top run (it clears the corners).
  static const double topRunInset = 30;

  /// The 121 hole hangs below the end of the right run.
  static const double finishDrop = 14;
  static const double finishSize = 16;

  /// Height of the two stacked rows along the top edge.
  static const double topRunHeight = holeSize * 2 + laneGap;

  /// Total width the track claims on each side.
  static const double sideRunWidth = edgeInset + holeSize * 2 + laneGap;

  /// Holes per run: 1–45 up the left, 46–75 across the top, 76–120 down the
  /// right, then the shared 121 finish hole.
  static const int leftStart = 1;
  static const int leftCount = 45;
  static const int topStart = 46;
  static const int topCount = 30;
  static const int rightStart = 76;
  static const int rightCount = 45;
  static const int skunkHole = 90;
  static const int finishHole = 121;
}

/// The 121-hole cribbage track, wrapped around the left, top and right edges
/// of the game screen (design language §5, mobile perimeter variant).
///
/// Outer lane is you (`--player-self`), inner lane the opponent
/// (`--player-opp`). The front peg is a filled dot, the back peg a ring at the
/// score before the last change. Peg movement is one 240ms slide.
class PerimeterBoard extends StatefulWidget {
  /// Y of the outer row of the top run.
  final double topY;

  /// Y where the two vertical runs begin.
  final double sideTop;

  /// Y where the two vertical runs end.
  final double sideBottom;

  final int playerScore;
  final int opponentScore;

  const PerimeterBoard({
    super.key,
    required this.topY,
    required this.sideTop,
    required this.sideBottom,
    required this.playerScore,
    required this.opponentScore,
  });

  @override
  State<PerimeterBoard> createState() => _PerimeterBoardState();
}

class _PerimeterBoardState extends State<PerimeterBoard> {
  late int _playerBack = widget.playerScore;
  late int _opponentBack = widget.opponentScore;

  @override
  void didUpdateWidget(PerimeterBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playerScore != widget.playerScore) {
      _playerBack = oldWidget.playerScore;
    }
    if (oldWidget.opponentScore != widget.opponentScore) {
      _opponentBack = oldWidget.opponentScore;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: widget.playerScore.toDouble()),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      builder: (context, playerPos, _) {
        return TweenAnimationBuilder<double>(
          tween: Tween(end: widget.opponentScore.toDouble()),
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          builder: (context, opponentPos, _) {
            return CustomPaint(
              painter: _PerimeterBoardPainter(
                topY: widget.topY,
                sideTop: widget.sideTop,
                sideBottom: widget.sideBottom,
                playerPos: playerPos,
                opponentPos: opponentPos,
                playerBack: _playerBack,
                opponentBack: _opponentBack,
                hole: colors.boardHole,
                self: colors.pegPlayer,
                opponent: colors.pegOpponent,
                gold: colors.ratingGold,
                skunk: colors.error,
              ),
            );
          },
        );
      },
    );
  }
}

/// One laid-out run of holes along a single axis.
class _Run {
  /// Hole number → centre coordinate along the run's axis.
  final Map<int, double> holes;

  /// Centre of the skunk line, when this run contains hole 90.
  final double? skunk;

  const _Run(this.holes, this.skunk);
}

class _PerimeterBoardPainter extends CustomPainter {
  final double topY;
  final double sideTop;
  final double sideBottom;
  final double playerPos;
  final double opponentPos;
  final int playerBack;
  final int opponentBack;
  final Color hole;
  final Color self;
  final Color opponent;
  final Color gold;
  final Color skunk;

  _PerimeterBoardPainter({
    required this.topY,
    required this.sideTop,
    required this.sideBottom,
    required this.playerPos,
    required this.opponentPos,
    required this.playerBack,
    required this.opponentBack,
    required this.hole,
    required this.self,
    required this.opponent,
    required this.gold,
    required this.skunk,
  });

  /// Lays a run out like `justify-content: space-between`: fixed-size holes,
  /// a group gap after every fifth, the skunk line after hole 90, and the
  /// remaining slack shared evenly between every item.
  _Run _layout(int start, int count, double from, double to) {
    const holeSize = BoardMetrics.holeSize;
    const groupGap = BoardMetrics.groupGap;
    const skunkSize = 2.0;

    final sizes = <double>[];
    final kinds = <int>[]; // >0 hole number, -1 group gap, -2 skunk line
    for (int n = start; n < start + count; n++) {
      sizes.add(holeSize);
      kinds.add(n);
      if (n % 5 == 0 && n < start + count - 1) {
        sizes.add(groupGap);
        kinds.add(-1);
      }
      if (n == BoardMetrics.skunkHole) {
        sizes.add(skunkSize);
        kinds.add(-2);
      }
    }

    final used = sizes.fold<double>(0, (a, b) => a + b);
    final span = (to - from).abs();
    final slack = sizes.length > 1 ? (span - used) / (sizes.length - 1) : 0.0;
    final sign = to >= from ? 1.0 : -1.0;

    final holes = <int, double>{};
    double? skunkCentre;
    double cursor = 0;
    for (int i = 0; i < sizes.length; i++) {
      final centre = from + sign * (cursor + sizes[i] / 2);
      if (kinds[i] > 0) {
        holes[kinds[i]] = centre;
      } else if (kinds[i] == -2) {
        skunkCentre = centre;
      }
      cursor += sizes[i] + slack;
    }
    return _Run(holes, skunkCentre);
  }

  /// Centre of every hole 0–121 for one lane. Hole 0 is the pre-start
  /// position, mirrored below hole 1 so a peg leaving 0 slides in cleanly.
  Map<int, Offset> _lane(Size size, {required bool outer}) {
    const inset = BoardMetrics.edgeInset;
    const h = BoardMetrics.holeSize;
    const gap = BoardMetrics.laneGap;

    final leftX = outer ? inset + h / 2 : inset + h + gap + h / 2;
    final rightX = outer
        ? size.width - inset - h / 2
        : size.width - inset - h - gap - h / 2;
    final topRowY = outer ? topY + h / 2 : topY + h + gap + h / 2;

    final left = _layout(
      BoardMetrics.leftStart,
      BoardMetrics.leftCount,
      sideBottom,
      sideTop,
    );
    final top = _layout(
      BoardMetrics.topStart,
      BoardMetrics.topCount,
      BoardMetrics.topRunInset,
      size.width - BoardMetrics.topRunInset,
    );
    final right = _layout(
      BoardMetrics.rightStart,
      BoardMetrics.rightCount,
      sideTop,
      sideBottom,
    );

    final out = <int, Offset>{};
    left.holes.forEach((n, y) => out[n] = Offset(leftX, y));
    top.holes.forEach((n, x) => out[n] = Offset(x, topRowY));
    right.holes.forEach((n, y) => out[n] = Offset(rightX, y));
    out[BoardMetrics.finishHole] = _finishCentre(size);

    final one = out[1]!;
    final two = out[2]!;
    out[0] = Offset(one.dx * 2 - two.dx, one.dy * 2 - two.dy);
    return out;
  }

  Offset _finishCentre(Size size) => Offset(
    size.width -
        BoardMetrics.edgeInset -
        BoardMetrics.holeSize -
        BoardMetrics.laneGap / 2,
    sideBottom + BoardMetrics.finishDrop,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final youLane = _lane(size, outer: true);
    final oppLane = _lane(size, outer: false);

    final holePaint = Paint()..color = hole;
    final holeRim = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;

    for (final lane in [youLane, oppLane]) {
      for (int n = 1; n <= 120; n++) {
        final c = lane[n];
        if (c == null) continue;
        canvas.drawCircle(c, BoardMetrics.holeSize / 2, holePaint);
        canvas.drawCircle(c, BoardMetrics.holeSize / 2, holeRim);
      }
    }

    _paintSkunk(canvas, size, youLane, oppLane);
    _paintFinish(canvas, size);

    _paintBackPeg(canvas, oppLane, opponentBack, opponent);
    _paintBackPeg(canvas, youLane, playerBack, self);
    _paintFrontPeg(canvas, oppLane, opponentPos, opponent);
    _paintFrontPeg(canvas, youLane, playerPos, self);
  }

  void _paintSkunk(
    Canvas canvas,
    Size size,
    Map<int, Offset> youLane,
    Map<int, Offset> oppLane,
  ) {
    // Hole 90 lives on the right run, so the marker is a pair of horizontal
    // dashes crossing both lanes.
    final right = _layout(
      BoardMetrics.rightStart,
      BoardMetrics.rightCount,
      sideTop,
      sideBottom,
    );
    final y = right.skunk;
    if (y == null) return;

    final paint = Paint()..color = skunk.withValues(alpha: 0.9);
    for (final lane in [youLane, oppLane]) {
      final x = lane[BoardMetrics.skunkHole]?.dx;
      if (x == null) continue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 11, height: 2),
          const Radius.circular(1),
        ),
        paint,
      );
    }
  }

  void _paintFinish(Canvas canvas, Size size) {
    final c = _finishCentre(size);
    const r = BoardMetrics.finishSize / 2;
    canvas.drawCircle(c, r, Paint()..color = hole);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = gold.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _paintBackPeg(
    Canvas canvas,
    Map<int, Offset> lane,
    int score,
    Color color,
  ) {
    if (score <= 0) return;
    final c = lane[score.clamp(0, BoardMetrics.finishHole)];
    if (c == null) return;
    canvas.drawCircle(
      c,
      BoardMetrics.holeSize / 2,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _paintFrontPeg(
    Canvas canvas,
    Map<int, Offset> lane,
    double score,
    Color color,
  ) {
    if (score <= 0) return;
    final clamped = score.clamp(0.0, BoardMetrics.finishHole.toDouble());
    final lo = clamped.floor();
    final hi = clamped.ceil();
    final a = lane[lo];
    final b = lane[hi];
    if (a == null || b == null) return;
    final c = Offset.lerp(a, b, clamped - lo)!;

    canvas.drawCircle(
      c.translate(0, 1),
      BoardMetrics.pegSize / 2,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    canvas.drawCircle(c, BoardMetrics.pegSize / 2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PerimeterBoardPainter old) =>
      old.topY != topY ||
      old.sideTop != sideTop ||
      old.sideBottom != sideBottom ||
      old.playerPos != playerPos ||
      old.opponentPos != opponentPos ||
      old.playerBack != playerBack ||
      old.opponentBack != opponentBack ||
      old.hole != hole ||
      old.self != self ||
      old.opponent != opponent;
}
