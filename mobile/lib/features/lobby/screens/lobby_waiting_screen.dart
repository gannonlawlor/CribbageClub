import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/lobby.dart';
import '../../../shared/widgets/cc_buttons.dart';
import '../../../shared/widgets/cc_screen.dart';
import '../../../shared/widgets/cc_swipe_back.dart';

class LobbyWaitingScreen extends ConsumerStatefulWidget {
  final String lobbyId;

  const LobbyWaitingScreen({super.key, required this.lobbyId});

  @override
  ConsumerState<LobbyWaitingScreen> createState() => _LobbyWaitingScreenState();
}

class _LobbyWaitingScreenState extends ConsumerState<LobbyWaitingScreen> {
  Timer? _pollTimer;
  Lobby? _lobby;
  bool _isLoading = true;
  String? _error;

  /// Flashes the invite card green for 400ms after a copy (design §4).
  bool _justCopied = false;
  Timer? _copyTimer;

  @override
  void initState() {
    super.initState();
    _fetchLobby();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _fetchLobby(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _copyTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLobby() async {
    try {
      final restClient = ref.read(restClientProvider);
      final lobby = await restClient.getLobby(widget.lobbyId);
      if (!mounted) return;
      setState(() {
        _lobby = lobby;
        _isLoading = false;
        _error = null;
      });
      if (lobby.status == LobbyStatus.inGame && lobby.gameId != null) {
        _pollTimer?.cancel();
        context.go('/game/${lobby.gameId}');
      }
    } catch (e) {
      debugPrint('[Lobby] Failed to fetch lobby ${widget.lobbyId}: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _leaveLobby() async {
    try {
      final restClient = ref.read(restClientProvider);
      await restClient.leaveLobby(widget.lobbyId);
    } catch (e) {
      debugPrint('[Lobby] Failed to leave lobby ${widget.lobbyId}: $e');
    }
    if (mounted) context.go('/');
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _justCopied = true);
    _copyTimer?.cancel();
    _copyTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _justCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final lobby = _lobby;
    final isPrivate = lobby?.inviteCode != null;

    return CcSwipeBack(
      onBack: _leaveLobby,
      child: Scaffold(
        backgroundColor: colors.scaffoldBg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  CcScreenHeader(
                    title: isPrivate ? 'Private game' : 'Finding a game',
                    onBack: _leaveLobby,
                  ),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                        ? CcMessage(
                            title: 'This lobby is unavailable',
                            detail: _error,
                            action: 'Back to home',
                            onAction: () => context.go('/'),
                          )
                        : _buildLobbyContent(lobby!),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLobbyContent(Lobby lobby) {
    final colors = context.appColors;
    final auth = ref.read(authProvider);
    final open = lobby.maxPlayers - lobby.players.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        if (lobby.inviteCode != null) ...[
          const CcSectionCaption('Invite code'),
          _InviteCode(
            code: lobby.inviteCode!,
            flash: _justCopied,
            onCopy: () => _copyCode(lobby.inviteCode!),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CcSecondaryButton(
                  label: _justCopied ? 'Copied' : 'Copy code',
                  icon: Icons.copy,
                  height: 40,
                  fontSize: 13,
                  onPressed: () => _copyCode(lobby.inviteCode!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CcSecondaryButton(
                  label: 'Share',
                  icon: Icons.ios_share,
                  height: 40,
                  fontSize: 13,
                  onPressed: () => Share.share(
                    'Join my Cribbage Club game. Code: ${lobby.inviteCode!}',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
        ],

        const CcSectionCaption('Table'),
        CcPanel(
          rows: [
            for (final player in lobby.players)
              _PlayerRow(
                name: player.name,
                isYou: player.id == auth.userId,
                seated: true,
              ),
            for (var i = 0; i < open; i++)
              const _PlayerRow(name: '', isYou: false, seated: false),
          ],
        ),
        const SizedBox(height: 22),

        // Status line — states the fact, no cheerleading (§8).
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.textTertiary,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                lobby.inviteCode != null
                    ? 'Waiting for someone to join with your code.'
                    : 'Looking for an opponent.',
                style: TextStyle(color: colors.textTertiary, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Center(
          child: SizedBox(
            width: 200,
            child: CcSecondaryButton(
              label: 'Leave',
              height: 40,
              fontSize: 13,
              filled: false,
              labelColor: colors.error,
              onPressed: _leaveLobby,
            ),
          ),
        ),
      ],
    );
  }
}

/// Invite-code display (design language §4): chrome surface, 1px **dashed**
/// border to signal "share me", monospace with wide tracking, and the whole
/// card is the copy target.
class _InviteCode extends StatelessWidget {
  final String code;
  final bool flash;
  final VoidCallback onCopy;

  const _InviteCode({
    required this.code,
    required this.flash,
    required this.onCopy,
  });

  /// Grouped in fours, the way a code meant to be read aloud should be.
  String get _grouped {
    final clean = code.replaceAll('-', '');
    final chunks = <String>[];
    for (var i = 0; i < clean.length; i += 4) {
      chunks.add(clean.substring(i, (i + 4).clamp(0, clean.length)));
    }
    return chunks.join('-');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onCopy,
      child: CustomPaint(
        // A foreground painter is sized to the whole card, so the dashes
        // trace the border rather than the text inside it.
        foregroundPainter: _DashedBorder(
          color: flash ? colors.accent : colors.borderStrong,
          radius: 8,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colors.surfaceChrome,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              _grouped,
              style: TextStyle(
                color: flash ? colors.accent : colors.textPrimary,
                fontSize: 20,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                letterSpacing: 3.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorder({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Inset by half the stroke so neither edge of the line is clipped.
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}

/// One seat at the table — taken, or still open.
class _PlayerRow extends StatelessWidget {
  final String name;
  final bool isYou;
  final bool seated;

  const _PlayerRow({
    required this.name,
    required this.isYou,
    required this.seated,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          if (seated)
            CcAvatar(name: name, size: 32)
          else
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.borderStrong),
              ),
              child: Icon(
                Icons.person_outline,
                size: 17,
                color: colors.textDisabled,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              seated ? name : 'Open seat',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: seated ? colors.textPrimary : colors.textDisabled,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (seated && isYou) const CcChip(label: 'YOU'),
        ],
      ),
    );
  }
}
