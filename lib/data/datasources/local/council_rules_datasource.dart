import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/bin_assignment.dart';

abstract class CouncilRulesDataSource {
  BinAssignment resolveBin({
    required String objectName,
    required String materialType,
    required String condition,
    required String councilName,
    /// The AI's own bin-category judgement (one of the values in
    /// `gemini_vision_datasource.dart`'s `validBinCategories`), if
    /// available. When present and recognised, this takes priority over
    /// the keyword heuristic below, since it reflects the model actually
    /// reasoning about the item rather than free text being pattern
    /// matched after the fact.
    String? binCategory,
  });
}

class DublinCouncilRulesDataSourceImpl implements CouncilRulesDataSource {
  @override
  BinAssignment resolveBin({
    required String objectName,
    required String materialType,
    required String condition,
    required String councilName,
    String? binCategory,
  }) {
    switch (binCategory) {
      case 'green_recycling':
        return _greenBin(councilName);
      case 'brown_compost':
        return _brownBin(councilName);
      case 'black_general':
        return _blackBin(councilName);
      case 'special_hazard':
        return _hazardBin(councilName);
    }

    // No (recognised) AI-provided category — fall back to keyword
    // matching on the free-text fields.
    final lowerObject = objectName.toLowerCase();
    final lowerMaterial = materialType.toLowerCase();
    final lowerCondition = condition.toLowerCase();

    final isContaminated = lowerCondition.contains('soiled') ||
        lowerCondition.contains('greasy') ||
        lowerCondition.contains('wet') ||
        lowerCondition.contains('dirty') ||
        lowerCondition.contains('food residue');

    if (lowerMaterial.contains('battery') ||
        lowerMaterial.contains('electronic') ||
        lowerObject.contains('battery') ||
        lowerObject.contains('bulb')) {
      return _hazardBin(councilName);
    }

    if (lowerMaterial.contains('organic') ||
        lowerMaterial.contains('food') ||
        lowerObject.contains('apple') ||
        lowerObject.contains('banana') ||
        lowerObject.contains('coffee grounds') ||
        lowerObject.contains('peel') ||
        lowerObject.contains('garden waste')) {
      return _brownBin(councilName);
    }

    if (isContaminated) {
      return _blackBin(councilName);
    }

    if (lowerMaterial.contains('paper') ||
        lowerMaterial.contains('cardboard') ||
        lowerMaterial.contains('metal') ||
        lowerMaterial.contains('aluminum') ||
        lowerMaterial.contains('aluminium') ||
        lowerMaterial.contains('steel') ||
        lowerMaterial.contains('glass') ||
        lowerMaterial.contains('plastic') ||
        lowerObject.contains('can') ||
        lowerObject.contains('bottle') ||
        lowerObject.contains('box')) {
      return _greenBin(councilName);
    }

    return _blackBin(councilName);
  }

  BinAssignment _brownBin(String councilName) => BinAssignment(
        binType: BinType.brownCompost,
        localBinName: 'Brown Bin (Organic Compost)',
        binColor: const Color(0xFF854D0E),
        primaryCategory: 'Food & Compostable Organic Waste',
        disposalSteps: const [
          'Place directly into your Brown Compost bin or food caddy.',
          'Ensure no plastic wrappers or non-compostable stickers are attached.',
        ],
        councilName: councilName,
      );

  BinAssignment _blackBin(String councilName) => BinAssignment(
        binType: BinType.blackGeneral,
        localBinName: 'Black / Grey Bin (General Waste)',
        binColor: const Color(0xFF334155),
        primaryCategory: 'General Non-Recyclable Waste',
        disposalSteps: const [
          'This item is contaminated, mixed-material, or otherwise non-recyclable.',
          'Place in the Black/Grey General Waste bin.',
        ],
        councilName: councilName,
      );

  BinAssignment _greenBin(String councilName) => BinAssignment(
        binType: BinType.greenRecycling,
        localBinName: 'Green Bin (Dry Recyclables)',
        binColor: const Color(0xFF16A34A),
        primaryCategory: 'Mixed Dry Recyclables',
        disposalSteps: const [
          'Ensure item is clean, dry, and loose (not in a tied plastic bag).',
          'Flatten cardboard boxes or crush aluminum cans to save space.',
        ],
        councilName: councilName,
      );

  BinAssignment _hazardBin(String councilName) => BinAssignment(
        binType: BinType.specialHazard,
        localBinName: 'Civic Amenity Drop-off (Hazardous / E-Waste)',
        binColor: AppTheme.hazardCivicAmenity,
        primaryCategory: 'Hazardous / Electronic Waste',
        disposalSteps: const [
          'Do not place this in any kerbside bin.',
          'Take it to your local civic amenity site or a designated battery/electronics collection point.',
        ],
        councilName: councilName,
      );
}
