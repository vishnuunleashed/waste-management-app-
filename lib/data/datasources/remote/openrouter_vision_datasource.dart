import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../../../core/error/failure.dart';
import '../../../core/utils/app_logger.dart';

const _tag = 'OpenRouterVision';

/// The bin categories the vision model is asked to choose between —
/// mirrors [BinType] in `domain/entities/bin_assignment.dart`. Kept as
/// plain strings here (rather than importing the domain enum) so this
/// remote datasource doesn't need to depend on domain/bin-rule concepts
/// beyond the raw category label.
const validBinCategories = {
  'green_recycling',
  'brown_compost',
  'black_general',
  'special_hazard',
};

class RawVisionAnalysis {
  final String objectName;
  final String materialType;
  final String condition;
  final double confidenceScore;

  /// The AI's own judgement of which bin this belongs in — one of
  /// [validBinCategories], or null if the model didn't return a
  /// recognised value (callers should fall back to their own heuristic).
  final String? binCategory;

  const RawVisionAnalysis({
    required this.objectName,
    required this.materialType,
    required this.condition,
    required this.confidenceScore,
    this.binCategory,
  });
}

/// Vision classification via OpenRouter's chat completions API. The
/// underlying model is whatever `OPENROUTER_MODEL` in `.env` names
/// (currently `openai/gpt-4o` by default) — named after the actual API
/// provider rather than a specific model, since the model is swappable
/// without code changes and this class previously carried a stale
/// "Gemini" name from an earlier plan that was never implemented.
abstract class OpenRouterVisionDataSource {
  Future<RawVisionAnalysis> analyzeImage(String imagePath);
}

class OpenRouterVisionDataSourceImpl implements OpenRouterVisionDataSource {
  final http.Client client;

  /// Max dimension (width or height) for the compressed image. Balanced
  /// against per-scan API cost — high enough that the model can actually
  /// make out shape, material texture, and packaging text; low enough to
  /// keep image tokens/cost reasonable per scan.
  static const int _maxDimension = 512;

  /// JPEG quality (1-100).
  static const int _jpegQuality = 70;

  OpenRouterVisionDataSourceImpl({http.Client? client})
      : client = client ?? http.Client();

  /// Compresses an image to a small JPEG to minimize base64 token usage.
  /// Runs in an isolate via [compute] so it doesn't block the UI thread.
  static Uint8List _compressImage(Uint8List rawBytes) {
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) return rawBytes;

    // Resize to fit within _maxDimension, preserving aspect ratio.
    final resized = img.copyResize(
      decoded,
      width: decoded.width > decoded.height ? _maxDimension : null,
      height: decoded.height >= decoded.width ? _maxDimension : null,
      interpolation: img.Interpolation.average,
    );

    return Uint8List.fromList(img.encodeJpg(resized, quality: _jpegQuality));
  }

  static const _promptText = '''
You are an expert waste-sorting assistant for Irish and UK household kerbside recycling. Look at the photographed item and classify it precisely so it can be routed to the correct bin.

Identify:
- objectName: a short, specific name for the single primary item in the photo (e.g. "aluminium drink can", "pizza box", "banana peel", "plastic yoghurt pot"). If several items are visible, name the most prominent one.
- materialType: the item's primary material in plain words (e.g. "cardboard", "aluminium", "mixed plastic", "food waste", "glass", "textile/fabric", "electronic/battery", "unknown" if you can't tell).
- condition: its physical state relevant to recyclability (e.g. "clean and dry", "food-soiled", "wet", "crushed but clean", "unknown").
- binCategory: which bin it belongs in, choosing EXACTLY one of these four values:
  - "green_recycling": clean, dry paper, cardboard, metal, glass, or rigid plastic that is NOT food-soiled.
  - "brown_compost": food scraps, garden waste, or other compostable organic matter.
  - "black_general": food-soiled/wet/contaminated items, mixed materials that can't be separated, soft plastics (film, wrappers, bags), or anything not covered by the other categories.
  - "special_hazard": batteries, electronics, light bulbs, paint, chemicals, or anything requiring a civic amenity drop-off rather than kerbside collection.
- confidenceScore: your genuine confidence in this classification, from 0 to 1. Use a LOW score (below 0.5) if the image is blurry, poorly lit, ambiguous, or shows multiple unclear items — don't inflate confidence just to give a clean-looking answer.

Return ONLY a single JSON object, no other text, in exactly this shape:
{"objectName":"","materialType":"","condition":"","binCategory":"","confidenceScore":0}''';

  @override
  Future<RawVisionAnalysis> analyzeImage(String imagePath) async {
    final apiKey = dotenv.get(
      'OPENROUTER_API_KEY',
      fallback: dotenv.get('GEMMA_TOKEN', fallback: ''),
    );
    if (apiKey.isEmpty) {
      AppLogger.error(_tag, 'OPENROUTER_API_KEY is not configured in .env');
      throw const ServerFailure('OpenRouter API token (OPENROUTER_API_KEY) is not configured in .env');
    }

    final File imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      AppLogger.error(_tag, 'Image file does not exist: $imagePath');
      throw const ServerFailure('Selected image file does not exist');
    }

    // Read raw bytes, then compress in a background isolate.
    final Uint8List rawBytes = await imageFile.readAsBytes();
    final Uint8List compressedBytes = await compute(_compressImage, rawBytes);
    final String base64Image = base64Encode(compressedBytes);

    AppLogger.info(_tag, 'Image compressed: ${rawBytes.length} → ${compressedBytes.length} bytes '
        '(base64: ${base64Image.length} chars)');

    final model = dotenv.get('OPENROUTER_MODEL', fallback: 'openai/gpt-4o');

    AppLogger.info(_tag, 'POST /chat/completions — model=$model');
    AppLogger.prompt(_tag, _promptText);
    final http.Response response;
    try {
      response = await client.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'max_tokens': 250,
          // Best-effort structured-output hint — most OpenRouter-proxied
          // models honor this and guarantee syntactically valid JSON; on
          // ones that don't, the prompt's own "return ONLY JSON" instruction
          // plus the markdown-fence stripping below still cover it.
          'response_format': {'type': 'json_object'},
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': _promptText,
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                  },
                },
              ],
            },
          ],
        }),
      );
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Network request failed', e, stackTrace);
      throw ServerFailure('Could not reach OpenRouter: $e');
    }

    AppLogger.info(_tag, 'Response: ${response.statusCode}');

    if (response.statusCode != 200) {
      AppLogger.error(_tag, 'OpenRouter API error ${response.statusCode}: ${response.body}');
      throw ServerFailure(
        'OpenRouter API error (${response.statusCode}): ${response.body}',
        code: response.statusCode.toString(),
      );
    }

    final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = jsonResponse['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      AppLogger.error(_tag, 'Invalid OpenRouter response structure: ${response.body}');
      throw ServerFailure('Invalid OpenRouter response structure: ${response.body}');
    }

    final message = choices[0]['message'];
    final messageContent = message != null ? message['content'] : null;

    String text = '';
    if (messageContent is String) {
      text = messageContent;
    } else if (messageContent is List && messageContent.isNotEmpty) {
      text = messageContent[0]['text'] ?? '';
    }

    AppLogger.response(_tag, text);
    final cleanedText = text.replaceAll('```json', '').replaceAll('```', '').trim();

    final Map<String, dynamic> parsedJson;
    try {
      parsedJson = jsonDecode(cleanedText) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Could not parse classification response: $cleanedText', e, stackTrace);
      throw ServerFailure('Could not parse classification response: $e');
    }

    final rawCategory = (parsedJson['binCategory'] as String?)
        ?.trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s-]+'), '_');

    final result = RawVisionAnalysis(
      objectName: parsedJson['objectName'] ?? 'Unknown Household Item',
      materialType: parsedJson['materialType'] ?? 'Mixed Material',
      condition: parsedJson['condition'] ?? 'Standard',
      confidenceScore: (parsedJson['confidenceScore'] as num?)?.toDouble() ?? 0.5,
      binCategory: validBinCategories.contains(rawCategory) ? rawCategory : null,
    );
    AppLogger.info(_tag, 'Classified: ${result.objectName} / ${result.materialType} / '
        'bin=${result.binCategory} / confidence=${result.confidenceScore}');
    return result;
  }
}
