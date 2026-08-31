import 'dart:io';

import 'failure.dart';
import 'git_repository.dart';
import 'policy.dart';
import 'strict_json.dart';

final class SourceCensus {
  SourceCensus({required this.repository, required this.policy});

  final GitRepository repository;
  final ArchitecturePolicy policy;

  void validateRepositoryCoverage() {
    final sources = repository.sourceFiles('.').toList()..sort();
    if (sources.isEmpty) {
      throw const ArchitectureFailure(
        'Repository census found no Dart source files.',
      );
    }
    final uncovered = <String>[];
    for (final path in sources) {
      _validatePhysicalSource(path);
      final owners = policy.scopes.entries
          .where((entry) => _isInside(path, entry.value.sourceRoot))
          .map((entry) => entry.key)
          .toList();
      if (owners.isEmpty) {
        uncovered.add(path);
      } else if (owners.length > 1) {
        throw ArchitectureFailure(
          'Dart source belongs to multiple architecture scopes: '
          '$path -> $owners',
        );
      }
    }
    if (uncovered.isNotEmpty) {
      throw ArchitectureFailure(
        'Dart sources are outside the architecture policy: $uncovered',
      );
    }
  }

  List<String> handwrittenFiles(String scopeName) {
    final scope = policy.scopes[scopeName];
    if (scope == null) {
      throw ArchitectureFailure('Unknown architecture scope: $scopeName');
    }
    final sources = repository.sourceFiles(scope.sourceRoot);
    if (sources.isEmpty) {
      throw ArchitectureFailure(
        '$scopeName/${scope.sourceRoot}: no Dart source files found.',
      );
    }
    for (final path in sources) {
      _validatePhysicalSource(path);
    }
    for (final prefix in scope.generatedPrefixes) {
      if (!sources.any((path) => path.startsWith(prefix))) {
        throw ArchitectureFailure(
          '$scopeName has a stale generated prefix: $prefix',
        );
      }
    }
    final generated = sources.where((path) {
      final isGenerated = policy.isGenerated(path, scopeName, scope);
      if (isGenerated) _validateGeneratedSource(scopeName, path, sources);
      return isGenerated;
    }).toSet();
    final handwritten = sources.difference(generated).toList()..sort();
    if (handwritten.isEmpty) {
      throw ArchitectureFailure('$scopeName has no handwritten Dart sources.');
    }
    for (final path in handwritten) {
      scope.roleFor(path);
    }
    return handwritten;
  }

  void _validatePhysicalSource(String path) {
    validateRepositoryPath(path, 'source path');
    final absolute = repository.resolve(path);
    final type = FileSystemEntity.typeSync(absolute, followLinks: false);
    if (type != FileSystemEntityType.file) {
      throw ArchitectureFailure(
        'Dart source must be a regular file, not a link or directory: $path',
      );
    }
  }

  void _validateGeneratedSource(
    String scopeName,
    String path,
    Set<String> sources,
  ) {
    final file = File(repository.resolve(path));
    final firstLine = _firstLine(file);
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) {
      final suffix = path.endsWith('.freezed.dart')
          ? '.freezed.dart'
          : '.g.dart';
      final input = '${path.substring(0, path.length - suffix.length)}.dart';
      if (firstLine == '// GENERATED CODE - DO NOT MODIFY BY HAND' &&
          sources.contains(input) &&
          _isRegularFile(repository.resolve(input))) {
        return;
      }
      throw ArchitectureFailure(
        '$scopeName generated suffix has no canonical header/input: $path',
      );
    }
    if (path.startsWith('server/lib/src/generated/') ||
        path.startsWith('server/test/integration/test_tools/') ||
        path.startsWith('packages/aonw_server_client/lib/src/protocol/')) {
      if (firstLine == '/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */') {
        return;
      }
      throw ArchitectureFailure(
        '$scopeName Serverpod output has no canonical header: $path',
      );
    }
    const localizationRoot = 'clients/aonw_flutter/lib/l10n/generated/';
    if (path.startsWith(localizationRoot)) {
      final basename = path.substring(localizationRoot.length);
      if (basename == 'aonw_localizations.dart' &&
          _isRegularFile(
            repository.resolve('clients/aonw_flutter/l10n.yaml'),
          ) &&
          _isRegularFile(
            repository.resolve('clients/aonw_flutter/lib/l10n/app_en.arb'),
          )) {
        return;
      }
      final locale = RegExp(
        r'^aonw_localizations_(.+)\.dart$',
      ).firstMatch(basename)?.group(1);
      if (locale != null &&
          _isRegularFile(
            repository.resolve('clients/aonw_flutter/lib/l10n/app_$locale.arb'),
          )) {
        return;
      }
      throw ArchitectureFailure(
        '$scopeName localization output has no matching ARB: $path',
      );
    }
    throw ArchitectureFailure(
      '$scopeName has an unsupported generated-code exclusion: $path',
    );
  }
}

bool _isInside(String path, String root) => path.startsWith('$root/');

bool _isRegularFile(String path) =>
    FileSystemEntity.typeSync(path, followLinks: false) ==
    FileSystemEntityType.file;

String _firstLine(File file) {
  final handle = file.openSync();
  try {
    final bytes = handle.readSync(128);
    return String.fromCharCodes(
      bytes,
    ).split(RegExp(r'\r?\n')).first.trimRight();
  } finally {
    handle.closeSync();
  }
}
