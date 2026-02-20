import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/lobby.dart';

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
        title: const Text('Waiting for Opponent'),
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
        Icon(Icons.hourglass_top, size: 64, color: colors.accent),
        const SizedBox(height: 24),
        Text(
          lobby.name,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        if (lobby.inviteCode != null) ...[
          Text(
            'Invite Code',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: colors.surfaceDim,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.accent.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lobby.inviteCode!,
                  style: TextStyle(
                    color: colors.accent,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.copy, color: colors.textTertiary),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: lobby.inviteCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invite code copied!')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share this code with a friend',
            style: TextStyle(color: colors.textDisabled, fontSize: 12),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Players: ${lobby.players.length} / ${lobby.maxPlayers}',
          style: TextStyle(color: colors.textSecondary, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ...lobby.players.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              p.name,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 32),
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
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
