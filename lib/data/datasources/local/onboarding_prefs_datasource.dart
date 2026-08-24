import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../domain/entities/council.dart';

abstract class OnboardingPrefsDataSource {
  Future<bool> hasCompletedOnboarding();
  Future<void> setOnboardingCompleted();
  Future<Council> getSelectedCouncil();
  Future<void> setSelectedCouncil(Council council);
}

class OnboardingPrefsDataSourceImpl implements OnboardingPrefsDataSource {
  static const _onboardingCompleteKey = 'onboarding_complete';
  static const _councilIdKey = 'selected_council_id';
  static const _councilNameKey = 'selected_council_name';
  static const _councilCountryKey = 'selected_council_country';

  static const defaultCouncil = Council(
    id: 'dublin-city-council',
    name: 'Dublin City Council',
    country: Country.ireland,
  );

  final FlutterSecureStorage _storage;

  OnboardingPrefsDataSourceImpl({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<bool> hasCompletedOnboarding() async {
    return (await _storage.read(key: _onboardingCompleteKey)) == 'true';
  }

  @override
  Future<void> setOnboardingCompleted() async {
    await _storage.write(key: _onboardingCompleteKey, value: 'true');
  }

  @override
  Future<Council> getSelectedCouncil() async {
    final id = await _storage.read(key: _councilIdKey);
    final name = await _storage.read(key: _councilNameKey);
    final countryRaw = await _storage.read(key: _councilCountryKey);
    if (id == null || name == null || countryRaw == null) {
      return defaultCouncil;
    }
    return Council(
      id: id,
      name: name,
      country: countryRaw == 'uk' ? Country.uk : Country.ireland,
    );
  }

  @override
  Future<void> setSelectedCouncil(Council council) async {
    await _storage.write(key: _councilIdKey, value: council.id);
    await _storage.write(key: _councilNameKey, value: council.name);
    await _storage.write(
      key: _councilCountryKey,
      value: council.country == Country.uk ? 'uk' : 'ireland',
    );
  }
}
