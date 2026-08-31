import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

import 'baseline.dart';
import 'complexity_metrics.dart';
import 'failure.dart';
import 'git_repository.dart';
import 'policy.dart';
import 'source_census.dart';
import 'strict_json.dart';

final class ArchitectureMeasurer {
  ArchitectureMeasurer({
    required this.repository,
    required this.policy,
    required this.census,
  });

  final GitRepository repository;
  final ArchitecturePolicy policy;
  final SourceCensus census;

  ArchitectureBaseline measure({Map<String, int>? legacyFileTargets}) {
    final effectiveLegacyTargets =
        legacyFileTargets ?? policy.migration.legacyFileTargets;
    census.validateRepositoryCoverage();
    final scopes = <String, ScopeBaseline>{};
    for (final entry in policy.scopes.entries) {
      scopes[entry.key] = _measureScope(
        entry.key,
        entry.value,
        effectiveLegacyTargets,
      );
    }
    return ArchitectureBaseline(scopes: scopes);
  }

  ScopeBaseline _measureScope(
    String scopeName,
    ScopePolicy scope,
    Map<String, int> legacyFileTargets,
  ) {
    final files = <String, int>{};
    final legacyFiles = <String, int>{};
    final declarations = <String, int>{};
    final callableLines = <String, int>{};
    final nesting = <String, int>{};
    final cyclomaticComplexity = <String, int>{};
    final cognitiveComplexity = <String, int>{};
    for (final path in census.handwrittenFiles(scopeName)) {
      final contents = File(repository.resolve(path)).readAsStringSync();
      final sourceMetrics = measureDartSource(path, contents);
      final role = scope.roleFor(path);
      if (sourceMetrics.fileLines > role.fileLines) {
        files[path] = sourceMetrics.fileLines;
      }
      final legacyTarget = legacyFileTargets[path];
      if (legacyTarget != null && sourceMetrics.fileLines > legacyTarget) {
        legacyFiles[path] = sourceMetrics.fileLines;
      }
      for (final declaration in sourceMetrics.declarations) {
        if (declaration.lines > role.declarationLines) {
          _insertUnique(declarations, declaration.key, declaration.lines, path);
        }
      }
      for (final callable in sourceMetrics.callables) {
        if (callable.lines > role.callableLines) {
          _insertUnique(callableLines, callable.key, callable.lines, path);
        }
        if (callable.nesting > role.nesting) {
          _insertUnique(nesting, callable.key, callable.nesting, path);
        }
        if (callable.cyclomaticComplexity > role.cyclomaticComplexity) {
          _insertUnique(
            cyclomaticComplexity,
            callable.key,
            callable.cyclomaticComplexity,
            path,
          );
        }
        if (callable.cognitiveComplexity > role.cognitiveComplexity) {
          _insertUnique(
            cognitiveComplexity,
            callable.key,
            callable.cognitiveComplexity,
            path,
          );
        }
      }
    }
    return ScopeBaseline(
      files: Map.unmodifiable(sortedMap(files)),
      legacyFiles: Map.unmodifiable(sortedMap(legacyFiles)),
      declarations: Map.unmodifiable(sortedMap(declarations)),
      callableLines: Map.unmodifiable(sortedMap(callableLines)),
      nesting: Map.unmodifiable(sortedMap(nesting)),
      cyclomaticComplexity: Map.unmodifiable(sortedMap(cyclomaticComplexity)),
      cognitiveComplexity: Map.unmodifiable(sortedMap(cognitiveComplexity)),
    );
  }
}

DartSourceMetrics measureDartSource(String path, String contents) {
  final result = parseString(
    content: contents,
    path: path,
    throwIfDiagnostics: false,
  );
  if (result.errors.isNotEmpty) {
    final details = result.errors
        .map((diagnostic) => diagnostic.toString())
        .join('\n');
    throw ArchitectureFailure('$path has parser diagnostics:\n$details');
  }
  final visitor = _MetricsVisitor(
    path: path,
    lineInfo: LineInfo.fromContent(contents),
  );
  result.unit.accept(visitor);
  return DartSourceMetrics(
    fileLines: const LineSplitter().convert(contents).length,
    declarations: List.unmodifiable(visitor.declarations),
    callables: List.unmodifiable(visitor.callables),
  );
}

final class DartSourceMetrics {
  const DartSourceMetrics({
    required this.fileLines,
    required this.declarations,
    required this.callables,
  });

  final int fileLines;
  final List<DeclarationMetric> declarations;
  final List<CallableMetric> callables;
}

final class DeclarationMetric {
  const DeclarationMetric({
    required this.key,
    required this.startLine,
    required this.lines,
  });

  final String key;
  final int startLine;
  final int lines;
}

final class CallableMetric {
  const CallableMetric({
    required this.key,
    required this.startLine,
    required this.lines,
    required this.nesting,
    required this.cyclomaticComplexity,
    required this.cognitiveComplexity,
  });

  final String key;
  final int startLine;
  final int lines;
  final int nesting;
  final int cyclomaticComplexity;
  final int cognitiveComplexity;
}

final class _MetricsVisitor extends RecursiveAstVisitor<void> {
  _MetricsVisitor({required this.path, required this.lineInfo});

  final String path;
  final LineInfo lineInfo;
  final List<DeclarationMetric> declarations = [];
  final List<_RawCallableMetric> _rawCallables = [];
  final List<String> _typeOwners = [];
  final List<String> _callableOwners = [];
  final Set<String> _keys = {};
  final Map<String, int> _closureCounts = {};
  final Map<String, int> _anonymousExtensionCounts = {};
  final Map<String, int> _localFunctionCounts = {};

  List<CallableMetric> get callables {
    final directChildLines = <String, Set<int>>{};
    for (final metric in _rawCallables) {
      final parentKey = metric.parentKey;
      if (parentKey != null) {
        directChildLines
            .putIfAbsent(parentKey, () => <int>{})
            .addAll(
              Iterable<int>.generate(
                metric.rawLines,
                (index) => metric.startLine + index,
              ),
            );
      }
    }
    return [
      for (final metric in _rawCallables)
        CallableMetric(
          key: metric.key,
          startLine: metric.startLine,
          lines: (metric.rawLines - (directChildLines[metric.key]?.length ?? 0))
              .clamp(1, metric.rawLines),
          nesting: metric.nesting,
          cyclomaticComplexity: metric.cyclomaticComplexity,
          cognitiveComplexity: metric.cognitiveComplexity,
        ),
    ];
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) => _visitType(
    node,
    'class',
    node.namePart.typeName.lexeme,
    () => super.visitClassDeclaration(node),
  );

  @override
  void visitEnumDeclaration(EnumDeclaration node) => _visitType(
    node,
    'enum',
    node.namePart.typeName.lexeme,
    () => super.visitEnumDeclaration(node),
  );

  @override
  void visitMixinDeclaration(MixinDeclaration node) => _visitType(
    node,
    'mixin',
    node.name.lexeme,
    () => super.visitMixinDeclaration(node),
  );

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    final declaredName = node.name?.lexeme;
    final anonymousBase =
        '<on:${node.onClause?.extendedType.toSource().replaceAll(RegExp(r'\s+'), ' ') ?? '<augmentation>'}>';
    final name =
        declaredName ?? _numbered(anonymousBase, _anonymousExtensionCounts);
    _visitType(
      node,
      'extension',
      name,
      () => super.visitExtensionDeclaration(node),
    );
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) =>
      _visitType(
        node,
        'extension_type',
        node.primaryConstructor.typeName.lexeme,
        () => super.visitExtensionTypeDeclaration(node),
      );

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final kind = node.isGetter
        ? 'getter'
        : node.isSetter
        ? 'setter'
        : _callableOwners.isEmpty
        ? 'function'
        : 'local_function';
    final owner = _callableOwners.isEmpty ? null : _callableOwners.last;
    var key = owner == null
        ? '$path::$kind:${node.name.lexeme}'
        : '$owner/$kind:${node.name.lexeme}';
    if (kind == 'local_function') {
      key = _numbered(key, _localFunctionCounts);
    }
    _visitCallable(
      node,
      node.functionExpression.body,
      key,
      () => super.visitFunctionDeclaration(node),
    );
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final kind = node.isGetter
        ? 'getter'
        : node.isSetter
        ? 'setter'
        : node.isOperator
        ? 'operator'
        : 'method';
    _visitCallable(
      node,
      node.body,
      '${_requiredTypeOwner(node)}/$kind:${node.name.lexeme}',
      () => super.visitMethodDeclaration(node),
    );
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _visitCallable(
      node,
      node,
      '${_requiredTypeOwner(node)}/constructor:${node.name?.lexeme ?? '<unnamed>'}',
      () => super.visitConstructorDeclaration(node),
    );
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) {
      super.visitFunctionExpression(node);
      return;
    }
    final key = _closureKey(node);
    _visitCallable(
      node,
      node.body,
      key,
      () => super.visitFunctionExpression(node),
    );
  }

  void _visitType(
    AnnotatedNode node,
    String kind,
    String name,
    void Function() visitChildren,
  ) {
    final key = '$path::$kind:$name';
    _requireUnique(key);
    final span = _span(node);
    declarations.add(
      DeclarationMetric(key: key, startLine: span.startLine, lines: span.lines),
    );
    _typeOwners.add(key);
    visitChildren();
    _typeOwners.removeLast();
  }

  void _visitCallable(
    AstNode node,
    AstNode complexityRoot,
    String key,
    void Function() visitChildren,
  ) {
    _requireUnique(key);
    final span = _span(node);
    final complexity = measureCallableComplexity(complexityRoot);
    _rawCallables.add(
      _RawCallableMetric(
        key: key,
        parentKey: _callableOwners.isEmpty ? null : _callableOwners.last,
        startLine: span.startLine,
        rawLines: span.lines,
        nesting: complexity.nesting,
        cyclomaticComplexity: complexity.cyclomatic,
        cognitiveComplexity: complexity.cognitive,
      ),
    );
    _callableOwners.add(key);
    visitChildren();
    _callableOwners.removeLast();
  }

  _SourceSpan _span(AstNode node) {
    final startOffset = node is AnnotatedNode
        ? node.metadata.isEmpty
              ? node.firstTokenAfterCommentAndMetadata.offset
              : node.metadata.first.offset
        : node.offset;
    final endOffset = node.end > startOffset ? node.end - 1 : startOffset;
    final startLine = lineInfo.getLocation(startOffset).lineNumber;
    final endLine = lineInfo.getLocation(endOffset).lineNumber;
    return _SourceSpan(startLine: startLine, lines: endLine - startLine + 1);
  }

  String _requiredTypeOwner(AstNode node) {
    if (_typeOwners.isEmpty) {
      throw ArchitectureFailure('$path has a callable outside a type: $node');
    }
    return _typeOwners.last;
  }

  void _requireUnique(String key) {
    if (!_keys.add(key)) {
      throw ArchitectureFailure(
        '$path contains duplicate stable architecture key: $key',
      );
    }
  }

  String _closureKey(FunctionExpression node) {
    final owner = _callableOwners.isEmpty
        ? _typeOwners.isEmpty
              ? '$path::top_level'
              : _typeOwners.last
        : _callableOwners.last;
    AstNode? context = node.parent;
    if (context is NamedExpression) context = context.parent;
    if (context is ArgumentList) {
      final invocation = context.parent;
      final callee = switch (invocation) {
        MethodInvocation() => invocation.methodName.name,
        FunctionExpressionInvocation() => invocation.function.toSource(),
        InstanceCreationExpression() => invocation.constructorName.toSource(),
        _ => invocation.runtimeType.toString(),
      };
      String? label;
      for (final argument in context.arguments) {
        final expression = argument is NamedExpression
            ? argument.expression
            : argument;
        if (expression is StringLiteral && expression.stringValue != null) {
          label = expression.stringValue;
          break;
        }
      }
      final normalizedCallee = _identityPart(callee);
      if (label != null && label.isNotEmpty) {
        return _numberedClosure(
          '$owner/closure:$normalizedCallee[${_identityPart(label)}]',
        );
      }
      return _numberedClosure('$owner/closure:$normalizedCallee');
    }
    final parent = node.parent;
    if (parent is VariableDeclaration) {
      return _numberedClosure(
        '$owner/closure:initializer[${_identityPart(parent.name.lexeme)}]',
      );
    }
    return _numberedClosure(
      '$owner/closure:${_identityPart(parent.runtimeType.toString())}',
    );
  }

  String _numberedClosure(String base) {
    return _numbered(base, _closureCounts);
  }
}

final class _SourceSpan {
  const _SourceSpan({required this.startLine, required this.lines});

  final int startLine;
  final int lines;
}

final class _RawCallableMetric {
  const _RawCallableMetric({
    required this.key,
    required this.parentKey,
    required this.startLine,
    required this.rawLines,
    required this.nesting,
    required this.cyclomaticComplexity,
    required this.cognitiveComplexity,
  });

  final String key;
  final String? parentKey;
  final int startLine;
  final int rawLines;
  final int nesting;
  final int cyclomaticComplexity;
  final int cognitiveComplexity;
}

void _insertUnique(
  Map<String, int> metrics,
  String key,
  int value,
  String path,
) {
  if (metrics.containsKey(key)) {
    throw ArchitectureFailure('$path contains duplicate metric key: $key');
  }
  metrics[key] = value;
}

String _identityPart(String value) => value
    .trim()
    .replaceAll(RegExp(r'\s+'), '_')
    .replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');

String _numbered(String base, Map<String, int> counts) {
  final count = (counts[base] ?? 0) + 1;
  counts[base] = count;
  return '$base#$count';
}
