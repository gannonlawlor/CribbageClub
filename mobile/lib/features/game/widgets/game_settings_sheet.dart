import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/services/settings_provider.dart';
import '../../../shared/widgets/cc_dialog.dart';
import '../../../shared/widgets/cc_list.dart';

/// Opens the shared game-settings dialog (auto-play toggles + animation
/// speed). Reachable in-game, from the Play tab, and from Settings.
///
/// In-game the dialog carries the exits at its foot — the game screen has no
/// chrome of its own.
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
  /// Leaves the game. Null outside a game.
  final VoidCallback? onLeave;

  /// Forfeits then leaves. Null for local games and once the game is over.
  final VoidCallback? onResign;

  const GameSettingsDialog({super.key, this.onLeave, this.onResign});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return CcDialog(
      title: 'Game settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
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
          if (onResign != null || onLeave != null) ...[
            const SizedBox(height: 18),
            const _SectionCaption('Leave'),
            const SizedBox(height: 8),
            if (onResign != null) ...[
              CcOptionRow(
                icon: Icons.flag_outlined,
                iconColor: colors.error,
                title: 'Forfeit & leave',
                subtitle: 'It counts as a loss.',
                showChevron: false,
                onTap: () {
                  Navigator.of(context).pop();
                  onResign!();
                },
              ),
              const SizedBox(height: 8),
            ],
            if (onLeave != null)
              CcOptionRow(
                icon: Icons.arrow_back,
                iconColor: colors.textTertiary,
                title: 'Leave game',
                showChevron: false,
                onTap: () {
                  Navigator.of(context).pop();
                  onLeave!();
                },
              ),
          ],
        ],
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
