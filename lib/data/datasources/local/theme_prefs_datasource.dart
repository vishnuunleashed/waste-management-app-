import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class ThemePrefsDataSource {
  Future<ThemeMode> getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);
}

class ThemePrefsDataSourceImpl implements ThemePrefsDataSource {
  static const _themeModeKey = 'theme_mode';
  final FlutterSecureStorage _storage;

  ThemePrefsDataSourceImpl({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<ThemeMode> getThemeMode() async {
    final value = await _storage.read(key: _themeModeKey);
    return value == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    await _storage.write(key: _themeModeKey, value: mode == ThemeMode.light ? 'light' : 'dark');
  }
}
