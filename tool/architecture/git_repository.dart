import 'dart:convert';
import 'dart:io';

import 'failure.dart';

final class GitRepository {
  factory GitRepository(String repository) {
    final directory = Directory(repository).absolute;
    if (!directory.existsSync()) {
      throw ArchitectureFailure('Repository does not exist: ${directory.path}');
    }
    final requestedRoot = directory.resolveSymbolicLinksSync();
    final result = Process.runSync(
      'git',
      ['-C', requestedRoot, 'rev-parse', '--show-toplevel'],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (result.exitCode != 0) {
      throw ArchitectureFailure(
        'Cannot resolve Git repository root for $requestedRoot:\n'
        '${(result.stderr as String).trim()}',
      );
    }
    final gitRoot = Directory(
      (result.stdout as String).trimRight(),
    ).resolveSymbolicLinksSync();
    if (gitRoot != requestedRoot) {
      throw ArchitectureFailure(
        'Architecture repository must be the Git top level: '
        '$requestedRoot != $gitRoot',
      );
    }
    return GitRepository._(gitRoot);
  }

  const GitRepository._(this.repository);

  final String repository;

  Set<String> sourceFiles(String sourceRoot) {
    final present = _nulPaths([
      'ls-files',
      '-z',
      '--cached',
      '--others',
      '--exclude-per-directory=.gitignore',
      '--',
      sourceRoot,
    ]).where((path) => path.endsWith('.dart')).toSet();
    final deleted = _nulPaths([
      'ls-files',
      '-z',
      '--deleted',
      '--',
      sourceRoot,
    ]).where((path) => path.endsWith('.dart')).toSet();
    present.removeAll(deleted);
    return present.map(normalizeGitPath).toSet();
  }

  bool commitExists(String ref) {
    final result = _processText(['rev-parse', '--verify', '$ref^{commit}']);
    return result.exitCode == 0;
  }

  void requireCommit(String ref, String description) {
    if (!commitExists(ref)) {
      throw ArchitectureFailure('Unknown $description: $ref');
    }
  }

  String resolveCommit(String ref) {
    final result = run(['rev-parse', '--verify', '$ref^{commit}']);
    final sha = result.stdout.trim();
    if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(sha)) {
      throw ArchitectureFailure('git rev-parse returned an invalid SHA: $sha');
    }
    return sha;
  }

  Map<String, String> renamesFrom(String ref) {
    final fields = _nulPaths([
      'diff',
      '--no-ext-diff',
      '--no-textconv',
      '--find-renames=1%',
      '--diff-filter=R',
      '--name-status',
      '-z',
      ref,
      '--',
    ]);
    if (fields.length % 3 != 0) {
      throw ArchitectureFailure(
        'git diff returned malformed rename records for $ref.',
      );
    }
    final renames = <String, String>{};
    for (var index = 0; index < fields.length; index += 3) {
      final status = fields[index];
      if (!RegExp(r'^R[0-9]{1,3}$').hasMatch(status)) {
        throw ArchitectureFailure(
          'git diff returned an invalid rename status: $status',
        );
      }
      final source = normalizeGitPath(fields[index + 1]);
      final destination = normalizeGitPath(fields[index + 2]);
      if (renames.putIfAbsent(source, () => destination) != destination) {
        throw ArchitectureFailure(
          'git diff returned multiple rename destinations for $source.',
        );
      }
    }
    return Map.unmodifiable(renames);
  }

  bool isAncestor(String ancestor, String descendant) {
    final result = _processText([
      'merge-base',
      '--is-ancestor',
      ancestor,
      descendant,
    ]);
    if (result.exitCode == 0) return true;
    if (result.exitCode == 1) return false;
    throw ArchitectureFailure(
      'git merge-base failed: ${(result.stderr as String).trim()}',
    );
  }

  List<String> mergeBases(String first, String second) {
    final result = _processText(['merge-base', '--all', first, second]);
    if (result.exitCode == 1) return const [];
    if (result.exitCode != 0) {
      throw ArchitectureFailure(
        'git merge-base failed: ${(result.stderr as String).trim()}',
      );
    }
    final bases = const LineSplitter()
        .convert(result.stdout as String)
        .where((line) => line.isNotEmpty)
        .toList();
    if (bases.any((sha) => !RegExp(r'^[0-9a-f]{40}$').hasMatch(sha))) {
      throw const ArchitectureFailure(
        'git merge-base returned an invalid SHA.',
      );
    }
    return bases;
  }

  String? show(String ref, String repositoryPath) {
    final exists = _processText(['cat-file', '-e', '$ref:$repositoryPath']);
    if (exists.exitCode != 0) return null;
    return run(['show', '$ref:$repositoryPath']).stdout;
  }

  String repositoryRelativePath(String path) {
    final file = File(path).absolute;
    if (FileSystemEntity.typeSync(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw ArchitectureFailure(
        'Architecture policy and baseline must be regular files: $path',
      );
    }
    final canonicalParent = file.parent.resolveSymbolicLinksSync();
    final basename = file.path.substring(
      file.parent.path.length + Platform.pathSeparator.length,
    );
    final absolute = '$canonicalParent${Platform.pathSeparator}$basename';
    final root = repository.endsWith(Platform.pathSeparator)
        ? repository
        : '$repository${Platform.pathSeparator}';
    if (!absolute.startsWith(root)) {
      throw ArchitectureFailure(
        'Architecture policy and baseline must be inside the repository: '
        '$path',
      );
    }
    final relative = absolute.substring(root.length);
    return Platform.pathSeparator == '/'
        ? relative
        : relative.replaceAll(Platform.pathSeparator, '/');
  }

  String resolve(String repositoryPath) {
    final portable = normalizeGitPath(repositoryPath);
    return '$repository${Platform.pathSeparator}'
        '${portable.replaceAll('/', Platform.pathSeparator)}';
  }

  GitOutput run(List<String> arguments) {
    final result = _processText(arguments);
    if (result.exitCode != 0) {
      throw ArchitectureFailure(
        'git ${arguments.join(' ')} failed:\n'
        '${(result.stderr as String).trim()}',
      );
    }
    return GitOutput(
      stdout: result.stdout as String,
      stderr: result.stderr as String,
    );
  }

  List<String> _nulPaths(List<String> arguments) {
    final result = _processBytes(arguments);
    if (result.exitCode != 0) {
      throw ArchitectureFailure(
        'git ${arguments.join(' ')} failed:\n'
        '${(result.stderr as String).trim()}',
      );
    }
    final bytes = result.stdout as List<int>;
    if (bytes.isEmpty) return const [];
    if (bytes.last != 0) {
      throw ArchitectureFailure(
        'git ${arguments.join(' ')} returned unterminated NUL output.',
      );
    }
    late final String decoded;
    try {
      decoded = utf8.decode(bytes, allowMalformed: false);
    } on FormatException catch (error) {
      throw ArchitectureFailure(
        'git ${arguments.join(' ')} returned a non-UTF-8 path: $error',
      );
    }
    final paths = decoded.split('\u0000')..removeLast();
    if (paths.any((path) => path.isEmpty)) {
      throw ArchitectureFailure(
        'git ${arguments.join(' ')} returned an empty path.',
      );
    }
    return paths;
  }

  ProcessResult _processText(List<String> arguments) => Process.runSync(
    'git',
    ['-C', repository, ...arguments],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );

  ProcessResult _processBytes(List<String> arguments) => Process.runSync(
    'git',
    ['-C', repository, ...arguments],
    stdoutEncoding: null,
    stderrEncoding: utf8,
  );
}

final class GitOutput {
  const GitOutput({required this.stdout, required this.stderr});

  final String stdout;
  final String stderr;
}

String normalizeGitPath(String value) {
  if (value.startsWith('./')) return value.substring(2);
  return value;
}
