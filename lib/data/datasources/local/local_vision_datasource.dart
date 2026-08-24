import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/app_logger.dart';
import '../remote/openrouter_vision_datasource.dart' show RawVisionAnalysis;

const _tag = 'LocalVision';
const _modelAsset = 'assets/models/waste_classifier.tflite';
const _labelsAsset = 'assets/models/labels.txt';
const _inputSize = 224;

/// Maps each of the bundled model's 12 raw class labels to one of the
/// app's 4 bin categories (see [validBinCategories]). Labels with no
/// dedicated kerbside stream (clothes, shoes) fall back to general waste —
/// textile/shoe recycling banks are a separate, non-kerbside disposal
/// route this app doesn't currently model.
const _labelToBinCategory = {
  'battery': 'special_hazard',
  'biological': 'brown_compost',
  'brown-glass': 'green_recycling',
  'green-glass': 'green_recycling',
  'white-glass': 'green_recycling',
  'cardboard': 'green_recycling',
  'metal': 'green_recycling',
  'paper': 'green_recycling',
  'plastic': 'green_recycling',
  'clothes': 'black_general',
  'shoes': 'black_general',
  'trash': 'black_general',
};

/// On-device counterpart to [OpenRouterVisionDataSource] — same input
/// (an image path) and same [RawVisionAnalysis] output shape, so
/// `council_rules_datasource.dart` and everything downstream of
/// classification doesn't need to know or care which one ran.
///
/// Unlike the cloud path, this runs a small (~20MB) traditional image
/// classifier (MobileNetV2-based, MIT licensed, from
/// github.com/KrisnaSantosa15/wastenet-garbage-classifier) bundled
/// directly in the app — no download, no gating, works instantly offline
/// on any device.
abstract class LocalVisionDataSource {
  Future<RawVisionAnalysis> analyzeImage(String imagePath);
}

class LocalVisionDataSourceImpl implements LocalVisionDataSource {
  Interpreter? _interpreter;
  List<String>? _labels;

  Future<Interpreter> _loadInterpreter() async {
    final existing = _interpreter;
    if (existing != null) return existing;
    AppLogger.info(_tag, 'Loading TFLite interpreter from $_modelAsset...');
    final interpreter = await Interpreter.fromAsset(_modelAsset);
    _interpreter = interpreter;
    AppLogger.info(_tag, 'TFLite interpreter ready');
    return interpreter;
  }

  Future<List<String>> _loadLabels() async {
    final existing = _labels;
    if (existing != null) return existing;
    final raw = await rootBundle.loadString(_labelsAsset);
    final labels = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    _labels = labels;
    return labels;
  }

  /// Resizes to the model's expected 224x224 input and normalizes each
  /// channel to [0, 1] (matches the exact preprocessing — plain /255.0,
  /// no per-channel mean/std subtraction — used to train this model, per
  /// its published training script).
  List<List<List<List<double>>>> _preprocess(img.Image decoded) {
    final resized = img.copyResize(
      decoded,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.average,
    );
    return [
      List.generate(_inputSize, (y) {
        return List.generate(_inputSize, (x) {
          final pixel = resized.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        });
      }),
    ];
  }

  @override
  Future<RawVisionAnalysis> analyzeImage(String imagePath) async {
    final imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      AppLogger.error(_tag, 'Image file does not exist: $imagePath');
      throw const ServerFailure('Selected image file does not exist');
    }

    try {
      final interpreter = await _loadInterpreter();
      final labels = await _loadLabels();

      final rawBytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) {
        AppLogger.error(_tag, 'Could not decode image: $imagePath');
        throw const ServerFailure('Could not decode selected image');
      }

      final input = _preprocess(decoded);
      final output = [List.filled(labels.length, 0.0)];

      AppLogger.info(_tag, 'Running inference...');
      interpreter.run(input, output);

      final scores = output[0];
      var bestIndex = 0;
      for (var i = 1; i < scores.length; i++) {
        if (scores[i] > scores[bestIndex]) bestIndex = i;
      }
      final label = labels[bestIndex];
      final confidence = scores[bestIndex];
      AppLogger.response(_tag, 'label=$label confidence=$confidence');

      final result = RawVisionAnalysis(
        objectName: label,
        materialType: label,
        condition: 'Unknown (offline scan)',
        confidenceScore: confidence,
        binCategory: _labelToBinCategory[label],
      );
      AppLogger.info(_tag, 'Classified: ${result.objectName} / '
          'bin=${result.binCategory} / confidence=${result.confidenceScore}');
      return result;
    } catch (e, stackTrace) {
      if (e is Failure) rethrow;
      AppLogger.error(_tag, 'On-device classification failed', e, stackTrace);
      throw ServerFailure('On-device classification failed: $e');
    }
  }
}
