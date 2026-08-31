import 'dart:convert';

import 'failure.dart';

Map<String, Object?> decodeObject(String contents, String description) {
  final decoded = jsonDecode(contents);
  if (decoded is! Map<String, Object?>) {
    throw ArchitectureFailure('$description must be a JSON object.');
  }
  return decoded;
}

Map<String, Object?> asObject(Object? value, String description) {
  if (value is! Map<String, Object?>) {
    throw ArchitectureFailure('$description must be an object.');
  }
  return value;
}

Map<String, Object?> readObject(
  Map<String, Object?> object,
  String key,
  String description,
) => asObject(object[key], '$description.$key');

String readString(Map<String, Object?> object, String key, String description) {
  final value = object[key];
  if (value is! String) {
    throw ArchitectureFailure('$description.$key must be a string.');
  }
  return value;
}

int readInt(Map<String, Object?> object, String key, String description) {
  final value = object[key];
  if (value is! int) {
    throw ArchitectureFailure('$description.$key must be an integer.');
  }
  return value;
}

bool readBool(Map<String, Object?> object, String key, String description) {
  final value = object[key];
  if (value is! bool) {
    throw ArchitectureFailure('$description.$key must be a boolean.');
  }
  return value;
}

List<String> readStringList(
  Map<String, Object?> object,
  String key,
  String description,
) {
  final value = object[key];
  if (value is! List<Object?> || value.any((entry) => entry is! String)) {
    throw ArchitectureFailure('$description.$key must be a string list.');
  }
  final result = value.cast<String>();
  requireSortedUnique(result, '$description.$key');
  return List.unmodifiable(result);
}

void expectKeys(
  Map<String, Object?> object,
  Set<String> expected,
  String description,
) {
  final actual = object.keys.toSet();
  final missing = expected.difference(actual).toList()..sort();
  final unknown = actual.difference(expected).toList()..sort();
  if (missing.isEmpty && unknown.isEmpty) return;
  throw ArchitectureFailure(
    '$description has invalid keys; missing=$missing unknown=$unknown.',
  );
}

void requireSortedUnique(List<String> values, String description) {
  final sorted = values.toSet().toList()..sort();
  if (sorted.length != values.length || !_sameList(sorted, values)) {
    throw ArchitectureFailure('$description must be sorted and unique.');
  }
}

void requireCanonicalJson(
  String source,
  Object? canonicalValue,
  String description,
) {
  final normalized = source.replaceAll('\r\n', '\n');
  final expected = canonicalJson(canonicalValue);
  if (normalized != expected) {
    throw ArchitectureFailure(
      '$description must use the canonical sorted JSON representation.',
    );
  }
}

String canonicalJson(Object? value) =>
    '${const JsonEncoder.withIndent('  ').convert(value)}\n';

Map<String, V> sortedMap<V>(Map<String, V> source) => {
  for (final key in source.keys.toList()..sort()) key: source[key] as V,
};

void validateRepositoryPath(
  String path,
  String description, {
  bool requirePrefix = false,
}) {
  if (path.isEmpty ||
      path.startsWith('/') ||
      path.contains('\\') ||
      path.contains('//') ||
      path.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f)) {
    throw ArchitectureFailure('$description is not a portable relative path.');
  }
  if (requirePrefix && !path.endsWith('/')) {
    throw ArchitectureFailure('$description must end with /.');
  }
  if (!requirePrefix && path.endsWith('/')) {
    throw ArchitectureFailure('$description must not end with /.');
  }
  final withoutTrailingSlash = path.endsWith('/')
      ? path.substring(0, path.length - 1)
      : path;
  if (withoutTrailingSlash
      .split('/')
      .any((segment) => segment.isEmpty || segment == '.' || segment == '..')) {
    throw ArchitectureFailure('$description contains an invalid segment.');
  }
}

bool pathMatches(String path, String pattern) =>
    pattern.endsWith('/') ? path.startsWith(pattern) : path == pattern;

bool patternsOverlap(String first, String second) {
  if (first == second) return true;
  if (first.endsWith('/')) {
    if (second.endsWith('/')) {
      return first.startsWith(second) || second.startsWith(first);
    }
    return second.startsWith(first);
  }
  if (second.endsWith('/')) return first.startsWith(second);
  return false;
}

bool _sameList<T>(List<T> first, List<T> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
