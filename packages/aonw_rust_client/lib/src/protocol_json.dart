Map<String, Object?> readObject(Object? value, String label) {
  if (value is! Map) {
    throw FormatException('Invalid AoNW $label.');
  }
  try {
    return Map<String, Object?>.from(value);
  } on Object {
    throw FormatException('Invalid AoNW $label.');
  }
}

void requireKeys(
  Map<String, Object?> value,
  Set<String> expected,
  String label,
) {
  if (value.length != expected.length ||
      expected.any((key) => !value.containsKey(key))) {
    throw FormatException('Invalid AoNW $label fields.');
  }
}

String readString(Object? value, String label) {
  if (value is! String) throw FormatException('Invalid AoNW $label.');
  return value;
}

String? readNullableString(Object? value, String label) {
  if (value == null) return null;
  return readString(value, label);
}

int readInt(Object? value, String label) {
  if (value is! int) throw FormatException('Invalid AoNW $label.');
  return value;
}

int readUnsigned(Object? value, String label) {
  final parsed = readInt(value, label);
  if (parsed < 0) throw FormatException('Invalid AoNW $label.');
  return parsed;
}

Map<String, int> readStringIntMap(Object? value, String label) {
  final source = readObject(value, label);
  return Map<String, int>.unmodifiable({
    for (final MapEntry(key: key, value: item) in source.entries)
      key: readInt(item, '$label value'),
  });
}

double readFinitePositiveDouble(Object? value, String label) {
  if (value is! num) throw FormatException('Invalid AoNW $label.');
  final parsed = value.toDouble();
  if (!parsed.isFinite || parsed <= 0) {
    throw FormatException('Invalid AoNW $label.');
  }
  return parsed;
}

bool readBool(Object? value, String label) {
  if (value is! bool) throw FormatException('Invalid AoNW $label.');
  return value;
}

List<T> readList<T>(
  Object? value,
  String label,
  T Function(Object? item, int index) decode,
) {
  if (value is! List) throw FormatException('Invalid AoNW $label.');
  return List<T>.unmodifiable([
    for (var index = 0; index < value.length; index++)
      decode(value[index], index),
  ]);
}
