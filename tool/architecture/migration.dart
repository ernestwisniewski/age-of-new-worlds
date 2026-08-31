import 'failure.dart';
import 'strict_json.dart';

final class ArchitectureMigration {
  const ArchitectureMigration({
    required this.fromSchema,
    required this.policySha256,
    required this.baselineSha256,
    required this.legacyFileTargets,
  });

  factory ArchitectureMigration.parse(Object? value, String description) {
    final object = asObject(value, description);
    expectKeys(object, const {
      'fromSchema',
      'policySha256',
      'baselineSha256',
      'legacyFileTargets',
    }, description);
    final fromSchema = readInt(object, 'fromSchema', description);
    if (fromSchema != 1) {
      throw ArchitectureFailure('$description.fromSchema must be 1.');
    }
    final policySha256 = readString(object, 'policySha256', description);
    final baselineSha256 = readString(object, 'baselineSha256', description);
    for (final entry in {
      'policySha256': policySha256,
      'baselineSha256': baselineSha256,
    }.entries) {
      if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(entry.value)) {
        throw ArchitectureFailure(
          '$description.${entry.key} must be a lowercase SHA-256 digest.',
        );
      }
    }
    final rawLegacyFileTargets = readObject(
      object,
      'legacyFileTargets',
      description,
    );
    final legacyFileTargets = <String, int>{};
    for (final entry in rawLegacyFileTargets.entries) {
      validateRepositoryPath(entry.key, '$description.legacyFileTargets key');
      if (!entry.key.endsWith('.dart') ||
          entry.value is! int ||
          (entry.value! as int) < 1) {
        throw ArchitectureFailure(
          '$description has an invalid legacy file target: ${entry.key}',
        );
      }
      legacyFileTargets[entry.key] = entry.value! as int;
    }
    return ArchitectureMigration(
      fromSchema: fromSchema,
      policySha256: policySha256,
      baselineSha256: baselineSha256,
      legacyFileTargets: Map.unmodifiable(sortedMap(legacyFileTargets)),
    );
  }

  final int fromSchema;
  final String policySha256;
  final String baselineSha256;
  final Map<String, int> legacyFileTargets;

  Map<String, int> legacyFileTargetsAfter(Map<String, String> renames) {
    final relocated = <String, int>{};
    for (final entry in legacyFileTargets.entries) {
      final path = renames[entry.key] ?? entry.key;
      final previous = relocated[path];
      if (previous != null && previous != entry.value) {
        throw ArchitectureFailure(
          'Multiple legacy file targets were renamed to $path.',
        );
      }
      relocated[path] = entry.value;
    }
    return Map.unmodifiable(sortedMap(relocated));
  }

  Map<String, Object?> toJson() => {
    'fromSchema': fromSchema,
    'policySha256': policySha256,
    'baselineSha256': baselineSha256,
    'legacyFileTargets': legacyFileTargets,
  };
}
