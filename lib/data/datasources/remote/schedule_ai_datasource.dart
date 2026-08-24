import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../../core/error/failure.dart';
import '../../../core/utils/app_logger.dart';
import '../../../domain/entities/collection_schedule.dart';
import '../../../domain/entities/council.dart';

const _tag = 'ScheduleAi';

abstract class ScheduleAiDataSource {
  /// Asks the AI model for [council]'s typical weekly collection pattern.
  ///
  /// Unlike the vision datasource, this deliberately does NOT fall back to
  /// a fabricated result on failure — callers must surface a real error so
  /// users don't get shown confident-looking but made-up collection days.
  Future<CollectionSchedule> fetchSchedule(Council council);
}

class ScheduleAiDataSourceImpl implements ScheduleAiDataSource {
  final http.Client client;

  ScheduleAiDataSourceImpl({http.Client? client}) : client = client ?? http.Client();

  @override
  Future<CollectionSchedule> fetchSchedule(Council council) async {
    final apiKey = dotenv.get(
      'OPENROUTER_API_KEY',
      fallback: dotenv.get('GEMMA_TOKEN', fallback: ''),
    );
    if (apiKey.isEmpty) {
      AppLogger.error(_tag, 'OPENROUTER_API_KEY is not configured in .env');
      throw const ServerFailure('OpenRouter API token (OPENROUTER_API_KEY) is not configured in .env');
    }

    final model = dotenv.get('OPENROUTER_MODEL', fallback: 'openai/gpt-4o');
    final countryLabel = council.country == Country.ireland ? 'Ireland' : 'the United Kingdom';

    final promptText = 'For "${council.name}" in $countryLabel, describe the typical weekly '
        'household kerbside waste collection pattern (which weekdays bins are collected and '
        'what material each collection takes, e.g. general waste, recycling, organic/food '
        'waste, garden waste). If you are not confident, still give your best general '
        'estimate but reflect that in confidence.'
        ' Return JSON only, no prose, in exactly this shape: '
        '{"monday":{"collects":false,"materials":[]},"tuesday":{"collects":false,"materials":[]},'
        '"wednesday":{"collects":false,"materials":[]},"thursday":{"collects":false,"materials":[]},'
        '"friday":{"collects":false,"materials":[]},"saturday":{"collects":false,"materials":[]},'
        '"sunday":{"collects":false,"materials":[]},"confidence":"low|medium|high"}';

    AppLogger.info(_tag, 'POST /chat/completions — model=$model, council=${council.name}');
    AppLogger.prompt(_tag, promptText);
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
          'max_tokens': 500,
          'messages': [
            {'role': 'user', 'content': promptText},
          ],
        }),
      );
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Network request failed', e, stackTrace);
      throw ServerFailure('Could not reach the schedule lookup service: $e');
    }

    AppLogger.info(_tag, 'Response: ${response.statusCode}');
    if (response.statusCode != 200) {
      AppLogger.error(_tag, 'OpenRouter API error ${response.statusCode}: ${response.body}');
      throw ServerFailure(
        'OpenRouter API error (${response.statusCode}): ${response.body}',
        code: response.statusCode.toString(),
      );
    }

    final Map<String, dynamic> parsedJson;
    try {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = jsonResponse['choices'] as List?;
      final message = (choices != null && choices.isNotEmpty) ? choices[0]['message'] : null;
      final content = message != null ? message['content'] : null;

      String text = '';
      if (content is String) {
        text = content;
      } else if (content is List && content.isNotEmpty) {
        text = content[0]['text'] ?? '';
      }

      AppLogger.response(_tag, text);
      final cleanedText = text.replaceAll('```json', '').replaceAll('```', '').trim();
      parsedJson = jsonDecode(cleanedText) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Could not parse the schedule response from the AI model', e, stackTrace);
      throw ServerFailure('Could not parse the schedule response from the AI model: $e');
    }

    final days = <String, DaySchedule>{};
    for (final day in weekdayOrder) {
      final raw = parsedJson[day] as Map<String, dynamic>?;
      days[day] = DaySchedule.fromJson(raw ?? const {});
    }

    return CollectionSchedule(
      councilId: council.id,
      days: days,
      generatedAt: DateTime.now(),
    );
  }
}
