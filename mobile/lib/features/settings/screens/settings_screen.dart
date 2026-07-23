import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/theme_provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/services/settings_provider.dart';
import '../../../shared/widgets/cc_bottom_nav.dart';
import '../../game/widgets/game_settings_sheet.dart';

/// Settings tab (design comp 3d): grouped sections with caption headers.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final settings = ref.watch(settingsProvider);
    final auth = ref.watch(authProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                const _SectionCaption('Account'),
                _Group(
                  children: [
                    if (auth.isLoggedIn) ...[
                      _ValueRow(
                        label: 'Username',
                        value: auth.username ?? '—',
                        onTap: () => context.go('/me'),
                      ),
                      if (auth.isGuest)
                        _ValueRow(
                          label: 'Account',
                          value: 'Guest — upgrade',
                          valueColor: colors.accent,
                          onTap: () => context.go('/upgrade'),
                        ),
                    ] else
                      _ValueRow(
                        label: 'Account',
                        value: 'Sign in',
                        valueColor: colors.accent,
                        onTap: () => context.go('/login'),
                      ),
                  ],
                ),
                const SizedBox(height: 18),

                const _SectionCaption('Gameplay'),
                _Group(
                  children: [
                    _ValueRow(
                      label: 'Game settings',
                      value: gameSettingsSummary(settings),
                      onTap: () => showGameSettingsDialog(context),
                    ),
                    _ToggleRow(
                      label: 'Sounds',
                      value: settings.soundEnabled,
                      onChanged: (v) => notifier.setSoundEnabled(v),
                    ),
                    _ToggleRow(
                      label: 'Haptics',
                      value: settings.hapticsEnabled,
                      onChanged: (v) => notifier.setHapticsEnabled(v),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                const _SectionCaption('Puzzles'),
                _Group(
                  children: [
                    _ToggleRow(
                      label: 'Pick the discard',
                      // Same question either way — this is which half of it
                      // the puzzle asks you for.
                      description: settings.puzzlePickDiscards
                          ? 'Choose the two cards you would throw'
                          : 'Choose the four cards you would keep',
                      value: settings.puzzlePickDiscards,
                      onChanged: (v) => notifier.setPuzzlePickDiscards(v),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                const _SectionCaption('Appearance'),
                _Group(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Theme',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          _ThemeSegmented(
                            mode: settings.themeMode,
                            onChanged: (m) => notifier.setThemeMode(m),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (auth.isLoggedIn) ...[
                  const SizedBox(height: 22),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        ref.read(authProvider.notifier).logout();
                        context.go('/');
                      },
                      child: Text(
                        'Sign out',
                        style: TextStyle(
                          color: colors.error,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CcBottomNav(active: CcTab.settings),
    );
  }
}

class _SectionCaption extends StatelessWidget {
  final String text;

  const _SectionCaption(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: colors.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

/// Grouped rows card: surface-2 fill, hairline border, dividers between rows.
class _Group extends StatelessWidget {
  final List<Widget> children;

  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final rows = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) rows.add(Divider(height: 1, color: colors.border));
      rows.add(children[i]);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border),
        ),
        child: Column(children: rows),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;

  const _ValueRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: valueColor ?? colors.textTertiary,
                  fontSize: 13.5,
                ),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 17, color: colors.textDisabled),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;

  /// One line under the label saying what the switch currently means.
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeTrackColor: colors.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ThemeSegmented extends StatelessWidget {
  final AppThemeMode mode;
  final ValueChanged<AppThemeMode> onChanged;

  const _ThemeSegmented({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final options = [
      (AppThemeMode.classicDark, 'Dark'),
      (AppThemeMode.classicLight, 'Light'),
      (AppThemeMode.system, 'Auto'),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surfaceChrome,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (value, label) in options)
            GestureDetector(
              onTap: () => onChanged(value),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: mode == value ? colors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: mode == value
                        ? colors.accentOnSurface
                        : colors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
