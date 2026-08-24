import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'riverpod/onboarding/onboarding_notifier.dart';

/// Decides the first screen the app shows: a brief loading state while the
/// onboarding flag loads from disk, then either Onboarding (first run) or
/// Home. The camera is never the landing screen — it only opens when the
/// user taps "Scan Item".
class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingProvider);

    if (onboardingState.isLoading) {
      return const _SplashView();
    }

    return onboardingState.isCompleted ? const HomeScreen() : const OnboardingScreen();
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: const Center(
        child: Icon(Icons.recycling_rounded, size: 64, color: AppTheme.primaryEmerald),
      ),
    );
  }
}
