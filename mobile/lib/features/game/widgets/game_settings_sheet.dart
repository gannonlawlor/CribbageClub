import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/services/settings_provider.dart';
import '../../../shared/widgets/cc_dialog.dart';
import '../../../shared/widgets/cc_list.dart';
import '../../../shared/widgets/cc_screen.dart';

/// Opens the shared game-settings dialog (auto-play toggles + animation
/// speed). Reachable in-game, from the Play tab, and from Settings.
///
/// In-game the dialog carries the two exits at its foot — the game screen has
/// no chrome of its own.
void showGameSettingsDialog(
  BuildContext context, {
  VoidCallback? onLeave,
  VoidCallback? onResign,
}) {
  showCcDialog(
    context: context,
    builder: (_) => GameSettingsDialog(onLeave: onLeave, onResign: onResign),
  );
}

class GameSettingsDialog extends ConsumerWidget {
  /// Steps away and keeps the game open to resume. Null outside a game.
  final VoidCallback? onLeave;

  /// Ends the game on the spot as a loss. Null once the game is over.
  final VoidCallback? onResign;

  const GameSettingsDialog({super.key, this.onLeave, this.onResign});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    // In-game exits lead the dialog: they act on this game, everything below
    // is app-wide preferences.
    final exits = <Widget>[
      if (onLeave != null)
        _ExitTile(
          icon: Icons.pause_circle_outline,
          label: 'Leave',
          caption: 'Resume it later',
          tint: colors.textTertiary,
          onTap: () {
            Navigator.of(context).pop();
            onLeave!();
          },
        ),
      if (onResign != null)
        _ExitTile(
          icon: Icons.flag_outlined,
          label: 'Resign',
          caption: 'Counts as a loss',
          tint: colors.error,
          onTap: () {
            Navigator.of(context).pop();
            onResign!();
          },
        ),
    ];

    return CcDialog(
      title: 'Game settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (exits.isNotEmpty) ...[
            const _SectionCaption('This game'),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < exits.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: exits[i]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Divider(color: colors.border, height: 1),
            const SizedBox(height: 16),
          ],
          Text(
            'Applies to all games. Change anytime, even mid-game.',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          CcGroup(
            children: [
              CcToggleRow(
                title: 'Auto-deal',
                value: settings.autoDeal,
                onChanged: notifier.setAutoDeal,
              ),
              CcToggleRow(
                title: 'Auto-cut deck',
                value: settings.autoCut,
                onChanged: notifier.setAutoCut,
              ),
              CcToggleRow(
                title: 'Auto-go',
                value: settings.autoGo,
                onChanged: notifier.setAutoGo,
              ),
              CcToggleRow(
                title: 'Auto-play all',
                value: settings.autoPlayAll,
                onChanged: notifier.setAutoPlayAll,
              ),
              CcToggleRow(
                title: 'Auto-play pegging',
                value: settings.autoPlayPegging,
                onChanged: settings.autoPlayAll
                    ? null
                    : notifier.setAutoPlayPegging,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionCaption("Opponent's hand"),
          const SizedBox(height: 8),
          CcSegmented(
            labels: const ['Cards', 'Card count'],
            selected: settings.opponentHandDisplay.index,
            onChanged: (i) =>
                notifier.setOpponentHandDisplay(OpponentHandDisplay.values[i]),
          ),
          const SizedBox(height: 6),
          Text(
            settings.opponentHandDisplay == OpponentHandDisplay.cards
                ? 'Their cards sit face down across the table from yours.'
                : 'Just how many cards they have left, on one chip.',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          const _SectionCaption('Animation speed'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            decoration: BoxDecoration(
              color: colors.surfaceDim,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Text(
                  '0.5x',
                  style: TextStyle(color: colors.textTertiary, fontSize: 11),
                ),
                Expanded(
                  child: Slider(
                    value: settings.animationSpeed,
                    min: 0.5,
                    max: 2.0,
                    divisions: 6,
                    activeColor: colors.accent,
                    onChanged: notifier.setAnimationSpeed,
                  ),
                ),
                Text(
                  '2.0x',
                  style: TextStyle(color: colors.textTertiary, fontSize: 11),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 34,
                  child: Text(
                    '${settings.animationSpeed.toStringAsFixed(1)}x',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A [CcOptionRow] turned on its side: icon chip over label over caption, so
/// two of them sit side by side in the dialog without the captions crowding.
class _ExitTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String caption;
  final Color tint;
  final VoidCallback onTap;

  const _ExitTile({
    required this.icon,
    required this.label,
    required this.caption,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: colors.surfaceDim,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: tint, size: 19),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 12.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCaption extends StatelessWidget {
  final String text;

  const _SectionCaption(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: colors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.7,
      ),
    );
  }
}

/// One-line summary of the enabled auto-play options, for settings rows.
String gameSettingsSummary(SettingsState s) {
  final parts = <String>[
    if (s.autoDeal) 'Auto deal',
    if (s.autoCut) 'auto cut',
    if (s.autoGo) 'auto go',
    if (s.autoPlayAll) 'auto play',
  ];
  if (parts.isEmpty) return 'All manual';
  final joined = parts.join(', ');
  return joined[0].toUpperCase() + joined.substring(1);
}
