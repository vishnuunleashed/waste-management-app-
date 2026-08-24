import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class OfflinePrefsDataSource {
  Future<bool> isOfflineScanEnabled();
  Future<void> setOfflineScanEnabled(bool enabled);
}

class OfflinePrefsDataSourceImpl implements OfflinePrefsDataSource {
  static const _enabledKey = 'offline_scan_enabled';

  final FlutterSecureStorage _storage;

  OfflinePrefsDataSourceImpl({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<bool> isOfflineScanEnabled() async {
    return (await _storage.read(key: _enabledKey)) == 'true';
  }

  @override
  Future<void> setOfflineScanEnabled(bool enabled) async {
    await _storage.write(key: _enabledKey, value: enabled ? 'true' : 'false');
  }
}
