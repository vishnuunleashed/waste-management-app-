enum Country { ireland, uk }

class Council {
  final String id;
  final String name;
  final Country country;

  const Council({
    required this.id,
    required this.name,
    required this.country,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Council &&
          other.id == id &&
          other.name == name &&
          other.country == country);

  @override
  int get hashCode => Object.hash(id, name, country);

  @override
  String toString() => 'Council(id: $id, name: $name, country: $country)';
}

/// Turns a council name into a stable Firestore-safe document id,
/// e.g. "Dublin City Council" -> "dublin-city-council".
String slugifyCouncilName(String name) {
  return name
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9\s-]"), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '-');
}
