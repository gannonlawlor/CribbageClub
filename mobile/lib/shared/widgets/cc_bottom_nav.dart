import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';

enum CcTab { play, profile, settings }

/// 3-tab bottom navigation (design comp 3a): Play · Profile · Settings.
class CcBottomNav extends StatelessWidget {
  final CcTab active;

  const CcBottomNav({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceChrome,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.play_arrow_rounded,
                label: 'Play',
                active: active == CcTab.play,
                onTap: () {
                  if (active != CcTab.play) context.go('/');
                },
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                active: active == CcTab.profile,
                onTap: () {
                  if (active != CcTab.profile) context.go('/me');
                },
              ),
              _NavItem(
                icon: Icons.tune,
                label: 'Settings',
                active: active == CcTab.settings,
                onTap: () {
                  if (active != CcTab.settings) context.go('/settings');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = active ? colors.accent : colors.textTertiary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
