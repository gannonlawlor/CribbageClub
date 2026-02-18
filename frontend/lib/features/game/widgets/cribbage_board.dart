import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class CribbageBoard extends StatefulWidget {
  final int playerScore;
  final int opponentScore;
  final bool isDealer;

  const CribbageBoard({
    super.key,
    required this.playerScore,
    required this.opponentScore,
    this.isDealer = false,
  });

  @override
  State<CribbageBoard> createState() => _CribbageBoardState();
}

class _CribbageBoardState extends State<CribbageBoard>
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
  void didUpdateWidget(CribbageBoard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final playerDelta = (widget.playerScore - _oldPlayerScore).abs();
    final opponentDelta = (widget.opponentScore - _oldOpponentScore).abs();
    final maxDelta = playerDelta > opponentDelta ? playerDelta : opponentDelta;

    if (maxDelta == 0) return;

    // Duration: 50ms per hole for the largest move
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 36),
          painter: _CribbageBoardPainter(
            playerScore: _playerAnim.value,
            opponentScore: _opponentAnim.value,
          ),
        );
      },
    );
  }
}

class _CribbageBoardPainter extends CustomPainter {
  final double playerScore;
  final double opponentScore;

  static const int _totalHoles = 121;
  static const int _groupSize = 5;
  static const double _holeRadius = 1.5;
  static const double _pegRadius = 3.0;
  static const double _trackPadding = 14.0;
  static const double _trackSpacing = 5.0;

  _CribbageBoardPainter({
    required this.playerScore,
    required this.opponentScore,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boardRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw board background
    final boardPaint = Paint()
      ..shader = ui.Gradient.linear(Offset(0, 0), Offset(0, size.height), [
        AppTheme.boardBrownLight,
        AppTheme.boardBrown,
      ]);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, const Radius.circular(8)),
      boardPaint,
    );

    // Draw subtle border
    final borderPaint = Paint()
      ..color = AppTheme.boardHole.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, const Radius.circular(8)),
      borderPaint,
    );

    final trackWidth = size.width - 2 * _trackPadding;
    final centerY = size.height / 2;
    final opponentTrackY = centerY - _trackSpacing;
    final playerTrackY = centerY + _trackSpacing;

    // Calculate hole positions
    final positions = _calculateHolePositions(trackWidth);

    // Draw holes for both tracks
    final holePaint = Paint()..color = AppTheme.boardHole;
    for (final pos in positions) {
      final x = _trackPadding + pos;
      canvas.drawCircle(Offset(x, opponentTrackY), _holeRadius, holePaint);
      canvas.drawCircle(Offset(x, playerTrackY), _holeRadius, holePaint);
    }

    // Draw milestone markers (31, 61, 91, 121)
    final milestones = [31, 61, 91, 121];
    final markerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final m in milestones) {
      if (m - 1 < positions.length) {
        final x = _trackPadding + positions[m - 1];
        // Small tick above/below tracks
        canvas.drawLine(
          Offset(x, opponentTrackY - 4),
          Offset(x, opponentTrackY - 2),
          markerPaint,
        );
        canvas.drawLine(
          Offset(x, playerTrackY + 2),
          Offset(x, playerTrackY + 4),
          markerPaint,
        );
        // Label below the board
        textPainter.text = TextSpan(
          text: '$m',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 6,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, playerTrackY + 5),
        );
      }
    }

    // Draw start label
    textPainter.text = TextSpan(
      text: '0',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.35),
        fontSize: 6,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(_trackPadding - textPainter.width / 2, playerTrackY + 5),
    );

    // Draw pegs
    final opponentPegPos = _scoreToPosition(opponentScore, positions);
    final playerPegPos = _scoreToPosition(playerScore, positions);

    // Opponent peg (white)
    _drawPeg(
      canvas,
      Offset(_trackPadding + opponentPegPos, opponentTrackY),
      AppTheme.pegWhite,
    );

    // Player peg (gold)
    _drawPeg(
      canvas,
      Offset(_trackPadding + playerPegPos, playerTrackY),
      AppTheme.pegGold,
    );

    // Draw track labels
    textPainter.text = TextSpan(
      text: 'You',
      style: TextStyle(
        color: AppTheme.pegGold.withValues(alpha: 0.7),
        fontSize: 7,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(2, playerTrackY - textPainter.height / 2));

    textPainter.text = TextSpan(
      text: 'Opp',
      style: TextStyle(
        color: AppTheme.pegWhite.withValues(alpha: 0.7),
        fontSize: 7,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(2, opponentTrackY - textPainter.height / 2),
    );
  }

  List<double> _calculateHolePositions(double trackWidth) {
    // 121 holes with grouping every 5
    final positions = <double>[];
    final numGroups = (_totalHoles / _groupSize).ceil();
    final groupGap = 3.0; // extra space between groups of 5
    final totalGaps = _totalHoles - 1 + (numGroups - 1) * (groupGap / 2);
    final spacing = trackWidth / totalGaps;

    double x = 0;
    for (int i = 0; i < _totalHoles; i++) {
      positions.add(x);
      x += spacing;
      if ((i + 1) % _groupSize == 0 && i < _totalHoles - 1) {
        x += spacing * (groupGap / 2);
      }
    }

    // Normalize to fit within trackWidth
    if (positions.isNotEmpty && positions.last > 0) {
      final scale = trackWidth / positions.last;
      for (int i = 0; i < positions.length; i++) {
        positions[i] *= scale;
      }
    }

    return positions;
  }

  double _scoreToPosition(double score, List<double> positions) {
    if (score <= 0 || positions.isEmpty) return 0;
    final clampedScore = score.clamp(0.0, 121.0);
    final intScore = clampedScore.floor();
    final fraction = clampedScore - intScore;

    if (intScore >= positions.length) return positions.last;
    if (intScore == 0) return positions[0] * fraction;

    final posA = positions[intScore - 1];
    final posB = intScore < positions.length
        ? positions[intScore]
        : positions.last;
    return posA + (posB - posA) * fraction;
  }

  void _drawPeg(Canvas canvas, Offset center, Color color) {
    // Glow
    canvas.drawCircle(
      center,
      _pegRadius + 2,
      Paint()..color = color.withValues(alpha: 0.3),
    );
    // Peg body
    canvas.drawCircle(center, _pegRadius, Paint()..color = color);
    // Highlight
    canvas.drawCircle(
      Offset(center.dx - 1, center.dy - 1),
      _pegRadius * 0.4,
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_CribbageBoardPainter oldDelegate) =>
      playerScore != oldDelegate.playerScore ||
      opponentScore != oldDelegate.opponentScore;
}
