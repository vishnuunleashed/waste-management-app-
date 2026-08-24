import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../data/datasources/local/theme_prefs_datasource.dart';

/// Riverpod Notifier for application ThemeMode state, persisted via
/// [ThemePrefsDataSource] so the choice survives app restarts.
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _load();
    return ThemeMode.light; // Default light theme until prefs load
  }

  Future<void> _load() async {
    final saved = await sl<ThemePrefsDataSource>().getThemeMode();
    state = saved;
  }

  void toggleTheme() {
    setThemeMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    sl<ThemePrefsDataSource>().setThemeMode(mode);
  }
}

/// Global Riverpod Provider for ThemeNotifier
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
