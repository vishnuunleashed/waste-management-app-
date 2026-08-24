const List<String> weekdayOrder = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

class DaySchedule {
  final bool collects;
  final List<String> materials;

  const DaySchedule({required this.collects, required this.materials});

  Map<String, dynamic> toJson() => {
        'collects': collects,
        'materials': materials,
      };

  factory DaySchedule.fromJson(Map<String, dynamic> json) => DaySchedule(
        collects: json['collects'] as bool? ?? false,
        materials: (json['materials'] as List?)?.cast<String>() ?? const [],
      );
}

/// A council's typical weekly waste collection pattern.
///
/// This is AI-sourced (there is no free public API providing real
/// per-council collection data for the UK or Ireland) and therefore
/// approximate — callers should always surface [disclaimer] to the user.
class CollectionSchedule {
  final String councilId;
  final Map<String, DaySchedule> days;
  final DateTime generatedAt;
  final String disclaimer;

  const CollectionSchedule({
    required this.councilId,
    required this.days,
    required this.generatedAt,
    this.disclaimer = 'Auto-generated — verify with your council.',
  });

  bool get isStale => DateTime.now().difference(generatedAt) > const Duration(days: 30);

  Map<String, dynamic> toJson() => {
        'days': days.map((k, v) => MapEntry(k, v.toJson())),
        'generatedAt': generatedAt.toIso8601String(),
        'disclaimer': disclaimer,
      };

  factory CollectionSchedule.fromJson(String councilId, Map<String, dynamic> json) {
    final rawDays = (json['days'] as Map<String, dynamic>?) ?? const {};
    return CollectionSchedule(
      councilId: councilId,
      days: rawDays.map(
        (k, v) => MapEntry(k, DaySchedule.fromJson(v as Map<String, dynamic>)),
      ),
      generatedAt: DateTime.tryParse(json['generatedAt'] as String? ?? '') ?? DateTime(2000),
      disclaimer: json['disclaimer'] as String? ??
          'Auto-generated — verify with your council.',
    );
  }
}
