import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/lobby.dart';
import '../../../shared/utils/text_utils.dart';

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
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load lobby: $e';
      });
    }
  }

  Future<void> _leaveLobby() async {
    try {
      final restClient = ref.read(restClientProvider);
      await restClient.leaveLobby(widget.lobbyId);
    } catch (_) {
      // Best-effort leave
    }
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waiting Room'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _leaveLobby,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: _isLoading
                ? const CircularProgressIndicator()
                : _error != null
                ? Text(_error!, style: TextStyle(color: colors.error))
                : _buildLobbyContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildLobbyContent() {
    final colors = context.appColors;
    final lobby = _lobby!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Invite Code section
        if (lobby.inviteCode != null) ...[
          Text(
            'INVITE CODE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: colors.surfaceDim,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.accent,
                width: 2,
              ),
            ),
            child: Text(
              lobby.inviteCode!,
              style: TextStyle(
                color: colors.accent,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: lobby.inviteCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invite code copied!')),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  Share.share(
                    'Join my Cribbage Club game! Code: ${lobby.inviteCode!}',
                  );
                },
                icon: const Icon(Icons.share, size: 16),
                label: const Text('Share'),
              ),
            ],
          ),
        ],

        const SizedBox(height: 32),

        // Players section
        Text(
          'PLAYERS',
          style: TextStyle(
            color: colors.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        ...lobby.players.map(
          (p) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surfaceDim,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colors.accent.withValues(alpha: 0.15),
                  child: Text(
                    initials(p.name),
                    style: TextStyle(
                      color: colors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  p.name,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(Icons.check_circle, color: colors.success, size: 20),
              ],
            ),
          ),
        ),
        // Empty slots
        for (var i = lobby.players.length; i < lobby.maxPlayers; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surfaceDim,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.divider,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colors.divider,
                  child: Icon(
                    Icons.person_outline,
                    color: colors.textDisabled,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Waiting for opponent...',
                  style: TextStyle(
                    color: colors.textDisabled,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),

        // Spinner
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(height: 8),
        Text(
          'Waiting for opponent to join...',
          style: TextStyle(color: colors.textTertiary),
        ),

        const SizedBox(height: 32),

        OutlinedButton(
          onPressed: _leaveLobby,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.error,
            side: BorderSide(color: colors.error),
          ),
          child: const Text('Leave'),
        ),
      ],
    );
  }
}
