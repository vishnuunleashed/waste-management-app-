import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../common/theme_notifier.dart';
import '../../riverpod/onboarding/onboarding_notifier.dart';
import 'change_council_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final council = ref.watch(onboardingProvider).selectedCouncil.name;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionLabel('General'),
          _SettingsTile(
            icon: Icons.location_city_rounded,
            title: 'Council',
            subtitle: council,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChangeCouncilScreen()),
            ),
          ),
          SwitchListTile.adaptive(
            value: themeMode == ThemeMode.dark,
            onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
            activeColor: AppTheme.primaryEmerald,
            title: Text('Dark theme', style: Theme.of(context).textTheme.bodyLarge),
            secondary: const Icon(Icons.dark_mode_rounded, color: AppTheme.accentMint),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(icon, color: AppTheme.accentMint),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: onTap == null
          ? null
          : Icon(Icons.chevron_right_rounded, color: context.colors.textMuted),
    );
  }
}
