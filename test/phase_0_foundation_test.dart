import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wastemanagementapp/core/error/failure.dart';
import 'package:wastemanagementapp/presentation/common/theme_notifier.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 0 Architecture Foundation Tests', () {
    setUp(() async {
      mockSecureStorage();
    });

    test('Failure hierarchy formats messages properly', () {
      const failure = ServerFailure('Server unavailable', code: '500');
      expect(failure.message, 'Server unavailable');
      expect(failure.code, '500');
      expect(failure.toString(), contains('ServerFailure'));
    });

    test('Riverpod ThemeNotifier correctly toggles ThemeMode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeProvider), ThemeMode.light);

      container.read(themeProvider.notifier).toggleTheme();
      expect(container.read(themeProvider), ThemeMode.dark);

      container.read(themeProvider.notifier).toggleTheme();
      expect(container.read(themeProvider), ThemeMode.light);
    });
  });
}
