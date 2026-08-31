import 'dart:io';

import 'failure.dart';
import 'strict_json.dart';

final class ArchitecturePolicy {
  ArchitecturePolicy._({
    required this.enforcedSince,
    required this.generatedSuffixes,
    required this.buildRunnerScopes,
    required this.roles,
    required this.scopes,
  });

  factory ArchitecturePolicy.load(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw ArchitectureFailure('Architecture policy does not exist: $path');
    }
    return ArchitecturePolicy.parse(file.readAsStringSync(), path);
  }

  factory ArchitecturePolicy.parse(String contents, String description) {
    final root = decodeObject(contents, description);
    expectKeys(root, const {
      'schema',
      'enforcedSince',
      'generatedSuffixes',
      'buildRunnerScopes',
      'roles',
      'scopes',
    }, description);
    if (readInt(root, 'schema', description) != schema) {
      throw ArchitectureFailure('$description has an unsupported schema.');
    }
    final enforcedSince = readString(root, 'enforcedSince', description);
    if (!_isSha(enforcedSince)) {
      throw ArchitectureFailure(
        '$description.enforcedSince must be a full lowercase Git SHA.',
      );
    }
    final generatedSuffixes = readStringList(
      root,
      'generatedSuffixes',
      description,
    );
    if (!_sameSet(generatedSuffixes.toSet(), const {
      '.freezed.dart',
      '.g.dart',
    })) {
      throw ArchitectureFailure(
        '$description.generatedSuffixes must contain only canonical '
        'build_runner suffixes.',
      );
    }
    final buildRunnerScopes = readStringList(
      root,
      'buildRunnerScopes',
      description,
    );
    final rawRoles = readObject(root, 'roles', description);
    if (rawRoles.isEmpty) {
      throw ArchitectureFailure('$description.roles must not be empty.');
    }
    final roles = <String, ArchitectureRole>{};
    for (final entry in rawRoles.entries) {
      _validateName(entry.key, '$description role');
      roles[entry.key] = ArchitectureRole.parse(
        entry.key,
        entry.value,
        '$description.roles.${entry.key}',
      );
    }
    if (!_sameSet(roles.keys.toSet(), canonicalRoleNames)) {
      throw ArchitectureFailure(
        '$description.roles must define exactly $canonicalRoleNames.',
      );
    }

    final rawScopes = readObject(root, 'scopes', description);
    if (rawScopes.isEmpty) {
      throw ArchitectureFailure('$description.scopes must not be empty.');
    }
    final scopes = <String, ScopePolicy>{};
    for (final entry in rawScopes.entries) {
      _validateName(entry.key, '$description scope');
      scopes[entry.key] = ScopePolicy.parse(
        entry.value,
        '$description.scopes.${entry.key}',
        roles,
      );
    }
    final unknownBuildRunnerScopes =
        buildRunnerScopes.toSet().difference(scopes.keys.toSet()).toList()
          ..sort();
    if (unknownBuildRunnerScopes.isNotEmpty) {
      throw ArchitectureFailure(
        '$description.buildRunnerScopes contains unknown scopes: '
        '$unknownBuildRunnerScopes',
      );
    }
    final usedRoles = <String>{
      for (final scope in scopes.values) scope.defaultRole,
      for (final scope in scopes.values) ...scope.roleAssignments.keys,
    };
    final unusedRoles = roles.keys.toSet().difference(usedRoles).toList()
      ..sort();
    if (unusedRoles.isNotEmpty) {
      throw ArchitectureFailure(
        '$description.roles contains unused roles: $unusedRoles',
      );
    }
    final policy = ArchitecturePolicy._(
      enforcedSince: enforcedSince,
      generatedSuffixes: generatedSuffixes,
      buildRunnerScopes: buildRunnerScopes,
      roles: Map.unmodifiable(sortedMap(roles)),
      scopes: Map.unmodifiable(sortedMap(scopes)),
    );
    _validateDisjointScopeRoots(policy.scopes, description);
    requireCanonicalJson(contents, policy.toJson(), description);
    return policy;
  }

  static const schema = 3;
  static const canonicalRoleNames = {
    'production',
    'test',
    'tool',
    'flame_rendering',
  };

  final String enforcedSince;
  final List<String> generatedSuffixes;
  final List<String> buildRunnerScopes;
  final Map<String, ArchitectureRole> roles;
  final Map<String, ScopePolicy> scopes;

  Map<String, Object?> toJson() => {
    'schema': schema,
    'enforcedSince': enforcedSince,
    'generatedSuffixes': generatedSuffixes,
    'buildRunnerScopes': buildRunnerScopes,
    'roles': {
      for (final entry in roles.entries) entry.key: entry.value.toJson(),
    },
    'scopes': {
      for (final entry in scopes.entries) entry.key: entry.value.toJson(),
    },
  };

  String get canonicalRepresentation => canonicalJson(toJson());

  bool isMonotonicExtensionOf(ArchitecturePolicy historical) {
    if (enforcedSince != historical.enforcedSince ||
        !_sameSet(
          generatedSuffixes.toSet(),
          historical.generatedSuffixes.toSet(),
        ) ||
        canonicalJson({
              for (final entry in roles.entries)
                entry.key: entry.value.toJson(),
            }) !=
            canonicalJson({
              for (final entry in historical.roles.entries)
                entry.key: entry.value.toJson(),
            })) {
      return false;
    }
    final addedScopes = scopes.keys.toSet().difference(
      historical.scopes.keys.toSet(),
    );
    if (!scopes.keys.toSet().containsAll(historical.scopes.keys)) {
      return false;
    }
    for (final entry in historical.scopes.entries) {
      if (canonicalJson(scopes[entry.key]!.toJson()) !=
          canonicalJson(entry.value.toJson())) {
        return false;
      }
    }
    final historicalBuildScopes = historical.buildRunnerScopes.toSet();
    final currentBuildScopes = buildRunnerScopes.toSet();
    return currentBuildScopes.containsAll(historicalBuildScopes) &&
        currentBuildScopes
            .difference(historicalBuildScopes)
            .every(addedScopes.contains);
  }

  bool isGenerated(String path, String scopeName, ScopePolicy scope) =>
      (buildRunnerScopes.contains(scopeName) &&
          generatedSuffixes.any(path.endsWith)) ||
      scope.generatedPrefixes.any(path.startsWith);
}

final class ArchitectureRole {
  const ArchitectureRole._({
    required this.name,
    required this.fileLines,
    required this.declarationLines,
    required this.callableLines,
    required this.nesting,
    required this.cyclomaticComplexity,
    required this.cognitiveComplexity,
  });

  factory ArchitectureRole.parse(
    String name,
    Object? value,
    String description,
  ) {
    final object = asObject(value, description);
    expectKeys(object, const {
      'fileLines',
      'declarationLines',
      'callableLines',
      'nesting',
      'cyclomaticComplexity',
      'cognitiveComplexity',
    }, description);
    int target(String key) {
      final result = readInt(object, key, description);
      if (result < 1) {
        throw ArchitectureFailure('$description.$key must be positive.');
      }
      return result;
    }

    return ArchitectureRole._(
      name: name,
      fileLines: target('fileLines'),
      declarationLines: target('declarationLines'),
      callableLines: target('callableLines'),
      nesting: target('nesting'),
      cyclomaticComplexity: target('cyclomaticComplexity'),
      cognitiveComplexity: target('cognitiveComplexity'),
    );
  }

  final String name;
  final int fileLines;
  final int declarationLines;
  final int callableLines;
  final int nesting;
  final int cyclomaticComplexity;
  final int cognitiveComplexity;

  Map<String, Object?> toJson() => {
    'fileLines': fileLines,
    'declarationLines': declarationLines,
    'callableLines': callableLines,
    'nesting': nesting,
    'cyclomaticComplexity': cyclomaticComplexity,
    'cognitiveComplexity': cognitiveComplexity,
  };
}

final class ScopePolicy {
  ScopePolicy._({
    required this.sourceRoot,
    required this.generatedPrefixes,
    required this.defaultRole,
    required this.roleAssignments,
    required this.roles,
  });

  factory ScopePolicy.parse(
    Object? value,
    String description,
    Map<String, ArchitectureRole> roles,
  ) {
    final object = asObject(value, description);
    expectKeys(object, const {
      'sourceRoot',
      'generatedPrefixes',
      'defaultRole',
      'roleAssignments',
    }, description);
    final sourceRoot = readString(object, 'sourceRoot', description);
    validateRepositoryPath(sourceRoot, '$description.sourceRoot');
    final generatedPrefixes = readStringList(
      object,
      'generatedPrefixes',
      description,
    );
    for (final prefix in generatedPrefixes) {
      validateRepositoryPath(
        prefix,
        '$description.generatedPrefixes entry',
        requirePrefix: true,
      );
      if (!prefix.startsWith('$sourceRoot/')) {
        throw ArchitectureFailure(
          '$description generated prefix is outside $sourceRoot: $prefix',
        );
      }
    }
    final defaultRole = readString(object, 'defaultRole', description);
    if (!roles.containsKey(defaultRole)) {
      throw ArchitectureFailure(
        '$description references unknown default role: $defaultRole',
      );
    }
    final rawAssignments = readObject(object, 'roleAssignments', description);
    final roleAssignments = <String, List<String>>{};
    for (final entry in rawAssignments.entries) {
      if (!roles.containsKey(entry.key)) {
        throw ArchitectureFailure(
          '$description references unknown assigned role: ${entry.key}',
        );
      }
      if (entry.key == defaultRole) {
        throw ArchitectureFailure(
          '$description cannot assign its default role explicitly.',
        );
      }
      final assignment = asObject(
        entry.value,
        '$description.roleAssignments.${entry.key}',
      );
      expectKeys(assignment, const {
        'paths',
      }, '$description.roleAssignments.${entry.key}');
      final paths = readStringList(
        assignment,
        'paths',
        '$description.roleAssignments.${entry.key}',
      );
      if (paths.isEmpty) {
        throw ArchitectureFailure(
          '$description.roleAssignments.${entry.key}.paths must not be empty.',
        );
      }
      for (final path in paths) {
        validateRepositoryPath(
          path,
          '$description.roleAssignments.${entry.key}.paths entry',
          requirePrefix: path.endsWith('/'),
        );
        if (path != sourceRoot && !path.startsWith('$sourceRoot/')) {
          throw ArchitectureFailure(
            '$description role path is outside $sourceRoot: $path',
          );
        }
      }
      roleAssignments[entry.key] = List.unmodifiable(paths);
    }
    final assignments = roleAssignments.entries.toList();
    for (var firstIndex = 0; firstIndex < assignments.length; firstIndex++) {
      for (
        var secondIndex = firstIndex + 1;
        secondIndex < assignments.length;
        secondIndex++
      ) {
        for (final first in assignments[firstIndex].value) {
          for (final second in assignments[secondIndex].value) {
            if (patternsOverlap(first, second)) {
              throw ArchitectureFailure(
                '$description role assignments overlap: $first / $second',
              );
            }
          }
        }
      }
    }
    return ScopePolicy._(
      sourceRoot: sourceRoot,
      generatedPrefixes: generatedPrefixes,
      defaultRole: defaultRole,
      roleAssignments: Map.unmodifiable(sortedMap(roleAssignments)),
      roles: roles,
    );
  }

  final String sourceRoot;
  final List<String> generatedPrefixes;
  final String defaultRole;
  final Map<String, List<String>> roleAssignments;
  final Map<String, ArchitectureRole> roles;

  ArchitectureRole roleFor(String path) {
    final matches = roleAssignments.entries
        .where(
          (entry) => entry.value.any((pattern) => pathMatches(path, pattern)),
        )
        .map((entry) => entry.key)
        .toList();
    if (matches.length > 1) {
      throw ArchitectureFailure(
        '$path matches multiple architecture roles: ${matches.join(', ')}',
      );
    }
    return roles[matches.isEmpty ? defaultRole : matches.single]!;
  }

  Map<String, Object?> toJson() => {
    'sourceRoot': sourceRoot,
    'generatedPrefixes': generatedPrefixes,
    'defaultRole': defaultRole,
    'roleAssignments': {
      for (final entry in roleAssignments.entries)
        entry.key: {'paths': entry.value},
    },
  };
}

void _validateDisjointScopeRoots(
  Map<String, ScopePolicy> scopes,
  String description,
) {
  final entries = scopes.entries.toList();
  for (var firstIndex = 0; firstIndex < entries.length; firstIndex++) {
    for (
      var secondIndex = firstIndex + 1;
      secondIndex < entries.length;
      secondIndex++
    ) {
      final first = entries[firstIndex];
      final second = entries[secondIndex];
      if (_rootsOverlap(first.value.sourceRoot, second.value.sourceRoot)) {
        throw ArchitectureFailure(
          '$description scopes ${first.key} and ${second.key} overlap: '
          '${first.value.sourceRoot} / ${second.value.sourceRoot}',
        );
      }
    }
  }
}

void _validateName(String value, String description) {
  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(value)) {
    throw ArchitectureFailure('$description has an invalid name: $value');
  }
}

bool _rootsOverlap(String first, String second) =>
    first == second ||
    first.startsWith('$second/') ||
    second.startsWith('$first/');

bool _sameSet<T>(Set<T> first, Set<T> second) =>
    first.length == second.length && first.containsAll(second);

bool _isSha(String value) => RegExp(r'^[0-9a-f]{40}$').hasMatch(value);
