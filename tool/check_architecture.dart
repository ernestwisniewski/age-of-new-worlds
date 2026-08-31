import 'dart:io';

import 'architecture/failure.dart';
import 'architecture/gate.dart';
import 'architecture/git_repository.dart';

void main(List<String> arguments) {
  try {
    final options = _Options.parse(arguments);
    final repository = GitRepository(options.repository);
    final gate = ArchitectureGate(
      repository: repository,
      policyPath: _resolve(options.repository, options.policyPath),
      baselinePath: _resolve(options.repository, options.baselinePath),
    );
    switch (options.command) {
      case _Command.snapshot:
        stdout.write(gate.snapshot().canonicalRepresentation);
      case _Command.check:
        final result = gate.check();
        stdout.writeln(
          'Architecture budgets pass: ${result.fileDebt} oversized files, '
          '${result.declarationDebt} oversized declarations, '
          '${result.callableLineDebt} long callables, '
          '${result.nestingDebt} deeply nested callables, '
          '${result.cyclomaticDebt} cyclomatic-complexity debts, and '
          '${result.cognitiveDebt} cognitive-complexity debts.',
        );
    }
  } on ArchitectureFailure catch (error) {
    stderr.writeln('Architecture budget gate failed:\n${error.message}');
    exitCode = 1;
  } on FormatException catch (error) {
    stderr.writeln('Architecture budget gate failed:\n${error.message}');
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('Architecture budget gate failed:\n$error');
    exitCode = 1;
  }
}

enum _Command { snapshot, check }

final class _Options {
  const _Options({
    required this.command,
    required this.repository,
    required this.policyPath,
    required this.baselinePath,
  });

  factory _Options.parse(List<String> arguments) {
    if (arguments.isEmpty) {
      throw const ArchitectureFailure(
        'Usage: dart run tool/check_architecture.dart <snapshot|check> '
        '[--repository PATH] [--policy PATH] [--baseline PATH] '
        '',
      );
    }
    final command = switch (arguments.first) {
      'snapshot' => _Command.snapshot,
      'check' => _Command.check,
      final value => throw ArchitectureFailure('Unknown command: $value'),
    };
    var repository = Directory.current.absolute.path;
    var policyPath = 'tool/architecture_policy.json';
    var baselinePath = 'tool/architecture_baseline.json';
    for (var index = 1; index < arguments.length; index++) {
      final argument = arguments[index];
      String valueFor(String name) {
        if (argument.startsWith('$name=')) {
          return argument.substring(name.length + 1);
        }
        if (argument == name && index + 1 < arguments.length) {
          index++;
          return arguments[index];
        }
        throw ArchitectureFailure('Missing value for $name.');
      }

      if (argument == '--repository' || argument.startsWith('--repository=')) {
        repository = Directory(valueFor('--repository')).absolute.path;
      } else if (argument == '--policy' || argument.startsWith('--policy=')) {
        policyPath = valueFor('--policy');
      } else if (argument == '--baseline' ||
          argument.startsWith('--baseline=')) {
        baselinePath = valueFor('--baseline');
      } else {
        throw ArchitectureFailure('Unknown argument: $argument');
      }
    }
    return _Options(
      command: command,
      repository: repository,
      policyPath: policyPath,
      baselinePath: baselinePath,
    );
  }

  final _Command command;
  final String repository;
  final String policyPath;
  final String baselinePath;
}

String _resolve(String repository, String path) {
  if (_isAbsolutePath(path)) return File(path).absolute.path;
  return File(
    '$repository${Platform.pathSeparator}'
    '${path.replaceAll('/', Platform.pathSeparator)}',
  ).absolute.path;
}

bool _isAbsolutePath(String path) =>
    path.startsWith('/') ||
    path.startsWith(r'\\') ||
    RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path);
