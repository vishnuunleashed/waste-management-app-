import 'package:flutter/material.dart';

import 'bin_assignment.dart';
import 'waste_item.dart' show ClassificationSource;

/// How long a scan stays in a device's history before it's purged.
const Duration scanHistoryRetention = Duration(days: 7);

/// A saved entry in a device's scan history, as displayed on the Home
/// screen's "Recent Scans" list and its detail screen.
class ScanRecord {
  final String id;
  final String objectName;
  final String materialType;
  final String condition;
  final double confidenceScore;
  final BinType binType;
  final String localBinName;
  final Color binColor;
  final String primaryCategory;
  final String councilName;
  final List<String> disposalSteps;
  final DateTime scannedAt;
  final DateTime expireAt;
  final ClassificationSource source;

  const ScanRecord({
    required this.id,
    required this.objectName,
    required this.materialType,
    required this.condition,
    required this.confidenceScore,
    required this.binType,
    required this.localBinName,
    required this.binColor,
    required this.primaryCategory,
    required this.councilName,
    required this.disposalSteps,
    required this.scannedAt,
    required this.expireAt,
    this.source = ClassificationSource.cloud,
  });
}
