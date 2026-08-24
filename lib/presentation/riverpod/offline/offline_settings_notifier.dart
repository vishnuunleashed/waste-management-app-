import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/service_locator.dart';
import '../../../data/datasources/local/offline_prefs_datasource.dart';

class OfflineSettingsState {
  final bool isLoading;
  final bool enabled;

  const OfflineSettingsState({required this.isLoading, required this.enabled});

  factory OfflineSettingsState.initial() =>
      const OfflineSettingsState(isLoading: true, enabled: false);

  OfflineSettingsState copyWith({bool? isLoading, bool? enabled}) {
    return OfflineSettingsState(
      isLoading: isLoading ?? this.isLoading,
      enabled: enabled ?? this.enabled,
    );
  }
}

class OfflineSettingsNotifier extends Notifier<OfflineSettingsState> {
  @override
  OfflineSettingsState build() {
    _load();
    return OfflineSettingsState.initial();
  }

  Future<void> _load() async {
    final enabled = await sl<OfflinePrefsDataSource>().isOfflineScanEnabled();
    state = state.copyWith(isLoading: false, enabled: enabled);
  }

  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    await sl<OfflinePrefsDataSource>().setOfflineScanEnabled(value);
  }
}

final offlineSettingsProvider =
    NotifierProvider<OfflineSettingsNotifier, OfflineSettingsState>(() {
  return OfflineSettingsNotifier();
});
