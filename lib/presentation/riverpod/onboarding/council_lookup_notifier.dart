import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/service_locator.dart';
import '../../../data/datasources/remote/council_lookup_datasource.dart';
import '../../../domain/entities/council.dart';

class CouncilLookupState {
  final bool isLoadingIrelandCouncils;
  final List<Council> irelandCouncils;
  final bool isLoadingUkCouncils;
  final List<Council> ukCouncils;
  final bool isResolvingPostcode;
  final String? postcodeError;

  const CouncilLookupState({
    required this.isLoadingIrelandCouncils,
    required this.irelandCouncils,
    required this.isLoadingUkCouncils,
    required this.ukCouncils,
    required this.isResolvingPostcode,
    required this.postcodeError,
  });

  factory CouncilLookupState.initial() => const CouncilLookupState(
        isLoadingIrelandCouncils: false,
        irelandCouncils: [],
        isLoadingUkCouncils: false,
        ukCouncils: [],
        isResolvingPostcode: false,
        postcodeError: null,
      );

  CouncilLookupState copyWith({
    bool? isLoadingIrelandCouncils,
    List<Council>? irelandCouncils,
    bool? isLoadingUkCouncils,
    List<Council>? ukCouncils,
    bool? isResolvingPostcode,
    String? postcodeError,
  }) {
    return CouncilLookupState(
      isLoadingIrelandCouncils: isLoadingIrelandCouncils ?? this.isLoadingIrelandCouncils,
      irelandCouncils: irelandCouncils ?? this.irelandCouncils,
      isLoadingUkCouncils: isLoadingUkCouncils ?? this.isLoadingUkCouncils,
      ukCouncils: ukCouncils ?? this.ukCouncils,
      isResolvingPostcode: isResolvingPostcode ?? this.isResolvingPostcode,
      postcodeError: postcodeError,
    );
  }
}

class CouncilLookupNotifier extends Notifier<CouncilLookupState> {
  @override
  CouncilLookupState build() => CouncilLookupState.initial();

  Future<void> loadIrelandCouncils() async {
    if (state.irelandCouncils.isNotEmpty || state.isLoadingIrelandCouncils) return;
    state = state.copyWith(isLoadingIrelandCouncils: true);
    try {
      final councils = await sl<CouncilLookupDataSource>().irelandCouncils();
      state = state.copyWith(isLoadingIrelandCouncils: false, irelandCouncils: councils);
    } catch (e) {
      state = state.copyWith(isLoadingIrelandCouncils: false);
    }
  }

  Future<void> loadUkCouncils() async {
    if (state.ukCouncils.isNotEmpty || state.isLoadingUkCouncils) return;
    state = state.copyWith(isLoadingUkCouncils: true);
    try {
      final councils = await sl<CouncilLookupDataSource>().ukCouncils();
      state = state.copyWith(isLoadingUkCouncils: false, ukCouncils: councils);
    } catch (e) {
      state = state.copyWith(isLoadingUkCouncils: false);
    }
  }

  Future<Council?> resolveUkPostcode(String postcode) async {
    state = state.copyWith(isResolvingPostcode: true, postcodeError: null);
    try {
      final council = await sl<CouncilLookupDataSource>().resolveUkCouncilFromPostcode(postcode);
      state = state.copyWith(isResolvingPostcode: false, postcodeError: null);
      return council;
    } catch (e) {
      state = state.copyWith(isResolvingPostcode: false, postcodeError: e.toString());
      return null;
    }
  }
}

final councilLookupProvider = NotifierProvider<CouncilLookupNotifier, CouncilLookupState>(() {
  return CouncilLookupNotifier();
});
