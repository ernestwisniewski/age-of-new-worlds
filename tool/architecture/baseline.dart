import 'dart:io';

import 'failure.dart';
import 'policy.dart';
import 'strict_json.dart';

final class ArchitectureBaseline {
  ArchitectureBaseline({required Map<String, ScopeBaseline> scopes})
    : scopes = Map.unmodifiable(sortedMap(scopes));

  factory ArchitectureBaseline.empty(ArchitecturePolicy policy) =>
      ArchitectureBaseline(
        scopes: {
          for (final name in policy.scopes.keys) name: ScopeBaseline.empty,
        },
      );

  factory ArchitectureBaseline.load(String path, ArchitecturePolicy policy) {
    final file = File(path);
    if (!file.existsSync()) {
      throw ArchitectureFailure('Architecture baseline does not exist: $path');
    }
    return ArchitectureBaseline.parse(file.readAsStringSync(), policy, path);
  }

  factory ArchitectureBaseline.parse(
    String contents,
    ArchitecturePolicy policy,
    String description,
  ) {
    final root = decodeObject(contents, description);
    expectKeys(root, const {'schema', 'scopes'}, description);
    if (readInt(root, 'schema', description) != ArchitecturePolicy.schema) {
      throw ArchitectureFailure('$description has an unsupported schema.');
    }
    final rawScopes = readObject(root, 'scopes', description);
    expectKeys(rawScopes, policy.scopes.keys.toSet(), '$description.scopes');
    final scopes = <String, ScopeBaseline>{};
    for (final entry in rawScopes.entries) {
      scopes[entry.key] = ScopeBaseline.parse(
        entry.value,
        policy.scopes[entry.key]!,
        '$description.scopes.${entry.key}',
      );
    }
    final baseline = ArchitectureBaseline(scopes: scopes);
    requireCanonicalJson(contents, baseline.toJson(), description);
    return baseline;
  }

  final Map<String, ScopeBaseline> scopes;

  Map<String, Object?> toJson() => {
    'schema': ArchitecturePolicy.schema,
    'scopes': {
      for (final entry in scopes.entries) entry.key: entry.value.toJson(),
    },
  };

  String get canonicalRepresentation => canonicalJson(toJson());

  ArchitectureBaseline withEmptyScopes(Iterable<String> scopeNames) =>
      ArchitectureBaseline(
        scopes: {
          for (final name in scopeNames)
            name: scopes[name] ?? ScopeBaseline.empty,
        },
      );

  List<String> exactDifferences(ArchitectureBaseline expected) {
    final failures = <String>[];
    for (final name in scopes.keys) {
      failures.addAll(
        scopes[name]!.exactDifferences(expected.scopes[name]!, name),
      );
    }
    return failures;
  }

  List<String> ratchetDifferences(ArchitectureBaseline historical) {
    final failures = <String>[];
    for (final name in scopes.keys) {
      failures.addAll(
        scopes[name]!.ratchetDifferences(historical.scopes[name]!, name),
      );
    }
    return failures;
  }

  List<String> ratchetDifferencesAllowingNewScopes(
    ArchitectureBaseline historical,
  ) => ratchetDifferences(historical.withEmptyScopes(scopes.keys));

  int get fileDebtCount => _uniqueFileDebt.length;
  int get declarationDebtCount => _sum((scope) => scope.declarations.length);
  int get callableLineDebtCount => _sum((scope) => scope.callableLines.length);
  int get nestingDebtCount => _sum((scope) => scope.nesting.length);
  int get cyclomaticDebtCount =>
      _sum((scope) => scope.cyclomaticComplexity.length);
  int get cognitiveDebtCount =>
      _sum((scope) => scope.cognitiveComplexity.length);

  int _sum(int Function(ScopeBaseline scope) select) =>
      scopes.values.fold(0, (sum, scope) => sum + select(scope));

  Set<String> get _uniqueFileDebt => {
    for (final scope in scopes.values) ...scope.files.keys,
  };
}

final class ScopeBaseline {
  const ScopeBaseline({
    required this.files,
    required this.declarations,
    required this.callableLines,
    required this.nesting,
    required this.cyclomaticComplexity,
    required this.cognitiveComplexity,
  });

  static const empty = ScopeBaseline(
    files: {},
    declarations: {},
    callableLines: {},
    nesting: {},
    cyclomaticComplexity: {},
    cognitiveComplexity: {},
  );

  factory ScopeBaseline.parse(
    Object? value,
    ScopePolicy policy,
    String description,
  ) {
    final object = asObject(value, description);
    expectKeys(object, const {
      'files',
      'declarations',
      'callableLines',
      'nesting',
      'cyclomaticComplexity',
      'cognitiveComplexity',
    }, description);
    return ScopeBaseline(
      files: _readMetricMap(
        object,
        'files',
        description,
        policy,
        isFileKey: true,
        target: (role) => role.fileLines,
      ),
      declarations: _readMetricMap(
        object,
        'declarations',
        description,
        policy,
        target: (role) => role.declarationLines,
      ),
      callableLines: _readMetricMap(
        object,
        'callableLines',
        description,
        policy,
        target: (role) => role.callableLines,
      ),
      nesting: _readMetricMap(
        object,
        'nesting',
        description,
        policy,
        target: (role) => role.nesting,
      ),
      cyclomaticComplexity: _readMetricMap(
        object,
        'cyclomaticComplexity',
        description,
        policy,
        target: (role) => role.cyclomaticComplexity,
      ),
      cognitiveComplexity: _readMetricMap(
        object,
        'cognitiveComplexity',
        description,
        policy,
        target: (role) => role.cognitiveComplexity,
      ),
    );
  }

  final Map<String, int> files;
  final Map<String, int> declarations;
  final Map<String, int> callableLines;
  final Map<String, int> nesting;
  final Map<String, int> cyclomaticComplexity;
  final Map<String, int> cognitiveComplexity;

  Map<String, Object?> toJson() => {
    'files': sortedMap(files),
    'declarations': sortedMap(declarations),
    'callableLines': sortedMap(callableLines),
    'nesting': sortedMap(nesting),
    'cyclomaticComplexity': sortedMap(cyclomaticComplexity),
    'cognitiveComplexity': sortedMap(cognitiveComplexity),
  };

  List<String> exactDifferences(ScopeBaseline expected, String scopeName) => [
    ..._exactMapDifferences(files, expected.files, '$scopeName file'),
    ..._exactMapDifferences(
      declarations,
      expected.declarations,
      '$scopeName declaration',
    ),
    ..._exactMapDifferences(
      callableLines,
      expected.callableLines,
      '$scopeName callable line',
    ),
    ..._exactMapDifferences(nesting, expected.nesting, '$scopeName nesting'),
    ..._exactMapDifferences(
      cyclomaticComplexity,
      expected.cyclomaticComplexity,
      '$scopeName cyclomatic complexity',
    ),
    ..._exactMapDifferences(
      cognitiveComplexity,
      expected.cognitiveComplexity,
      '$scopeName cognitive complexity',
    ),
  ];

  List<String> ratchetDifferences(ScopeBaseline historical, String scopeName) =>
      [
        ..._ratchetMapDifferences(files, historical.files, '$scopeName file'),
        ..._ratchetMapDifferences(
          declarations,
          historical.declarations,
          '$scopeName declaration',
        ),
        ..._ratchetMapDifferences(
          callableLines,
          historical.callableLines,
          '$scopeName callable line',
        ),
        ..._ratchetMapDifferences(
          nesting,
          historical.nesting,
          '$scopeName nesting',
        ),
        ..._ratchetMapDifferences(
          cyclomaticComplexity,
          historical.cyclomaticComplexity,
          '$scopeName cyclomatic complexity',
        ),
        ..._ratchetMapDifferences(
          cognitiveComplexity,
          historical.cognitiveComplexity,
          '$scopeName cognitive complexity',
        ),
      ];
}

Map<String, int> _readMetricMap(
  Map<String, Object?> object,
  String key,
  String description,
  ScopePolicy policy, {
  bool isFileKey = false,
  required int Function(ArchitectureRole role) target,
}) {
  final raw = readObject(object, key, description);
  final result = <String, int>{};
  for (final entry in raw.entries) {
    if (entry.value is! int || (entry.value! as int) < 1) {
      throw ArchitectureFailure(
        '$description.$key.${entry.key} must be a positive integer.',
      );
    }
    final path = isFileKey
        ? entry.key
        : _entityPath(entry.key, description, key);
    validateRepositoryPath(path, '$description.$key path');
    if (!path.startsWith('${policy.sourceRoot}/') || !path.endsWith('.dart')) {
      throw ArchitectureFailure(
        '$description.$key entry is outside ${policy.sourceRoot}: ${entry.key}',
      );
    }
    final value = entry.value! as int;
    final limit = target(policy.roleFor(path));
    if (value <= limit) {
      throw ArchitectureFailure(
        '$description.$key debt is not above its $limit target: '
        '${entry.key}=$value',
      );
    }
    result[entry.key] = value;
  }
  return Map.unmodifiable(sortedMap(result));
}

String _entityPath(String key, String description, String metric) {
  final separator = key.indexOf('::');
  if (separator <= 0 || separator == key.length - 2 || key.contains('\n')) {
    throw ArchitectureFailure(
      '$description has an invalid $metric debt key: $key',
    );
  }
  return key.substring(0, separator);
}

List<String> _exactMapDifferences(
  Map<String, int> actual,
  Map<String, int> expected,
  String label,
) {
  final failures = <String>[];
  final added = actual.keys.toSet().difference(expected.keys.toSet()).toList()
    ..sort();
  final removed = expected.keys.toSet().difference(actual.keys.toSet()).toList()
    ..sort();
  if (added.isNotEmpty) failures.add('$label debt added: $added');
  if (removed.isNotEmpty) failures.add('$label debt removed: $removed');
  for (final key in actual.keys.toSet().intersection(expected.keys.toSet())) {
    if (actual[key] != expected[key]) {
      failures.add(
        '$label metric changed: $key ${expected[key]} -> ${actual[key]}',
      );
    }
  }
  failures.sort();
  return failures;
}

List<String> ratchetMetricDifferences(
  Map<String, int> current,
  Map<String, int> historical,
  String label,
) => _ratchetMapDifferences(current, historical, label);

List<String> _ratchetMapDifferences(
  Map<String, int> current,
  Map<String, int> historical,
  String label,
) {
  final failures = <String>[];
  final added =
      current.keys.toSet().difference(historical.keys.toSet()).toList()..sort();
  if (added.isNotEmpty) {
    failures.add('$label debt cannot be introduced: $added');
  }
  for (final key in current.keys.toSet().intersection(
    historical.keys.toSet(),
  )) {
    if (current[key]! > historical[key]!) {
      failures.add(
        '$label debt cannot grow: $key ${historical[key]} -> ${current[key]}',
      );
    }
  }
  failures.sort();
  return failures;
}
