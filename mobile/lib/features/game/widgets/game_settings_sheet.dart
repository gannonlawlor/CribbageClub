import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/services/settings_provider.dart';

/// Opens the shared game-settings sheet (auto-play toggles + animation
/// speed). Reachable in-game, from the Play tab, and from Settings.
///
/// In-game the sheet carries the exits at its foot — the game screen has no
/// chrome of its own.
void showGameSettingsSheet(
  BuildContext context, {
  VoidCallback? onLeave,
  VoidCallback? onResign,
}) {
  final colors = context.appColors;
  showModalBottomSheet(
    context: context,
    backgroundColor: colors.surfacePrimary,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => GameSettingsSheet(onLeave: onLeave, onResign: onResign),
  );
}

class GameSettingsSheet extends ConsumerWidget {
  final VoidCallback? onLeave;
  final VoidCallback? onResign;

  const GameSettingsSheet({super.key, this.onLeave, this.onResign});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                children: [
                  Text(
                    'Game settings',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Applies to all games. Change anytime, even mid-game.',
                    style: TextStyle(color: colors.textTertiary, fontSize: 12),
                  ),
                ],
              ),
            ),
            SwitchListTile.adaptive(
              title: Text(
                'Auto-Deal',
                style: TextStyle(color: colors.textPrimary),
              ),
              value: settings.autoDeal,
              activeTrackColor: colors.accent,
              onChanged: (val) => notifier.setAutoDeal(val),
            ),
            SwitchListTile.adaptive(
              title: Text(
                'Auto-Cut Deck',
                style: TextStyle(color: colors.textPrimary),
              ),
              value: settings.autoCut,
              activeTrackColor: colors.accent,
              onChanged: (val) => notifier.setAutoCut(val),
            ),
            SwitchListTile.adaptive(
              title: Text(
                'Auto-Go',
                style: TextStyle(color: colors.textPrimary),
              ),
              value: settings.autoGo,
              activeTrackColor: colors.accent,
              onChanged: (val) => notifier.setAutoGo(val),
            ),
            SwitchListTile.adaptive(
              title: Text(
                'Auto-Play All',
                style: TextStyle(color: colors.textPrimary),
              ),
              value: settings.autoPlayAll,
              activeTrackColor: colors.accent,
              onChanged: (val) => notifier.setAutoPlayAll(val),
            ),
            SwitchListTile.adaptive(
              title: Text(
                'Auto-Play Pegging',
                style: TextStyle(
                  color: settings.autoPlayAll
                      ? colors.textDisabled
                      : colors.textPrimary,
                ),
              ),
              value: settings.autoPlayPegging,
              activeTrackColor: colors.accent,
              onChanged: settings.autoPlayAll
                  ? null
                  : (val) => notifier.setAutoPlayPegging(val),
            ),
            ListTile(
              title: Text(
                'Animation Speed',
                style: TextStyle(color: colors.textPrimary),
              ),
              subtitle: Row(
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
                      onChanged: (val) => notifier.setAnimationSpeed(val),
                    ),
                  ),
                  Text(
                    '2.0x',
                    style: TextStyle(color: colors.textTertiary, fontSize: 11),
                  ),
                ],
              ),
              trailing: Text(
                '${settings.animationSpeed.toStringAsFixed(1)}x',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onResign != null || onLeave != null) ...[
              const SizedBox(height: 4),
              Divider(height: 1, color: colors.border),
              if (onResign != null)
                ListTile(
                  leading: Icon(
                    Icons.flag_outlined,
                    color: colors.error,
                    size: 20,
                  ),
                  title: Text(
                    'Forfeit & leave',
                    style: TextStyle(
                      color: colors.error,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'It counts as a loss.',
                    style: TextStyle(color: colors.textTertiary, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    onResign!();
                  },
                ),
              if (onLeave != null)
                ListTile(
                  leading: Icon(
                    Icons.arrow_back,
                    color: colors.textSecondary,
                    size: 20,
                  ),
                  title: Text(
                    'Leave game',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    onLeave!();
                  },
                ),
            ],
            const SizedBox(height: 8),
          ],
        ),
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
