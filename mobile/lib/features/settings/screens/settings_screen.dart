import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/theme_provider.dart';
import '../../../core/services/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader(title: 'APPEARANCE', colors: colors),
          _SettingsTile(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            subtitle: 'Casino felt theme',
            value: settings.themeMode == AppThemeMode.classicDark,
            onChanged: (val) {
              final mode = val
                  ? AppThemeMode.classicDark
                  : AppThemeMode.classicLight;
              ref.read(settingsProvider.notifier).setThemeMode(mode);
            },
            colors: colors,
          ),
          const Divider(height: 1, indent: 56),
          _SectionHeader(title: 'PLAY STYLE', colors: colors),
          _SettingsTile(
            icon: Icons.style,
            title: 'Auto-Deal',
            subtitle: 'Automatically deal cards',
            value: settings.autoDeal,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setAutoDeal(val);
            },
            colors: colors,
          ),
          const Divider(height: 1, indent: 56),
          _SettingsTile(
            icon: Icons.content_cut,
            title: 'Auto-Cut Deck',
            subtitle: 'Automatically cut the deck',
            value: settings.autoCut,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setAutoCut(val);
            },
            colors: colors,
          ),
          const Divider(height: 1, indent: 56),
          _SettingsTile(
            icon: Icons.front_hand,
            title: 'Auto-Go',
            subtitle: 'Automatically say Go when needed',
            value: settings.autoGo,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setAutoGo(val);
            },
            colors: colors,
          ),
          const Divider(height: 1, indent: 56),
          _SettingsTile(
            icon: Icons.touch_app,
            title: 'Auto-Play All Cards',
            subtitle: 'Tap to play or discard instantly',
            value: settings.autoPlayAll,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setAutoPlayAll(val);
            },
            colors: colors,
          ),
          const Divider(height: 1, indent: 56),
          _SettingsTile(
            icon: Icons.play_arrow,
            title: 'Auto-Play During Pegging',
            subtitle: 'Tap to play cards during pegging',
            value: settings.autoPlayPegging,
            enabled: !settings.autoPlayAll,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setAutoPlayPegging(val);
            },
            colors: colors,
          ),
          const Divider(height: 1, indent: 56),
          _SliderTile(
            icon: Icons.speed,
            title: 'Animation Speed',
            value: settings.animationSpeed,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setAnimationSpeed(val);
            },
            colors: colors,
          ),
          const Divider(height: 1, indent: 56),
          _SectionHeader(title: 'AUDIO & FEEDBACK', colors: colors),
          _SettingsTile(
            icon: Icons.volume_up,
            title: 'Sound Effects',
            subtitle: 'Card, score, and game sounds',
            value: settings.soundEnabled,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setSoundEnabled(val);
            },
            colors: colors,
          ),
          const Divider(height: 1, indent: 56),
          _SettingsTile(
            icon: Icons.vibration,
            title: 'Haptic Feedback',
            subtitle: 'Vibration on card play and scoring',
            value: settings.hapticsEnabled,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setHapticsEnabled(val);
            },
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final AppColors colors;

  const _SectionHeader({required this.title, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: colors.textTertiary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final AppColors colors;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    this.enabled = true,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: enabled ? colors.accent : colors.textDisabled),
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? colors.textPrimary : colors.textDisabled,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: enabled ? colors.textTertiary : colors.textDisabled,
                fontSize: 12,
              ),
            )
          : null,
      trailing: Switch.adaptive(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeTrackColor: colors.accent,
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final double value;
  final ValueChanged<double> onChanged;
  final AppColors colors;

  const _SliderTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: colors.accent),
      title: Text(title, style: TextStyle(color: colors.textPrimary)),
      subtitle: Row(
        children: [
          Text(
            '0.5x',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: 0.5,
              max: 2.0,
              divisions: 6,
              activeColor: colors.accent,
              onChanged: onChanged,
            ),
          ),
          Text(
            '2.0x',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
      trailing: Text(
        '${value.toStringAsFixed(1)}x',
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
