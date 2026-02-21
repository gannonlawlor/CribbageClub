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
  final ValueChanged<bool> onChanged;
  final AppColors colors;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: colors.accent),
      title: Text(title, style: TextStyle(color: colors.textPrimary)),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(color: colors.textTertiary, fontSize: 12),
            )
          : null,
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: colors.accent,
      ),
    );
  }
}
