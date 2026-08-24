import 'package:flutter/material.dart';

enum BinType {
  greenRecycling, // Dry Recyclables
  brownCompost,   // Organic / Food Waste
  blackGeneral,    // Residual Household Waste
  specialHazard,  // E-waste, batteries, civic amenity drop-off
}

class BinAssignment {
  final BinType binType;
  final String localBinName;
  final Color binColor;
  final String primaryCategory;
  final List<String> disposalSteps;
  final String councilName;

  const BinAssignment({
    required this.binType,
    required this.localBinName,
    required this.binColor,
    required this.primaryCategory,
    required this.disposalSteps,
    required this.councilName,
  });

  @override
  String toString() =>
      'BinAssignment(localName: $localBinName, binType: $binType, council: $councilName)';
}
