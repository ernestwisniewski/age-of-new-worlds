import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

ComplexityMetric measureCallableComplexity(AstNode root) {
  final visitor = _ComplexityVisitor();
  root.accept(visitor);
  return ComplexityMetric(
    nesting: visitor.maximumNesting,
    cyclomatic: visitor.cyclomatic,
    cognitive: visitor.cognitive,
  );
}

final class ComplexityMetric {
  const ComplexityMetric({
    required this.nesting,
    required this.cyclomatic,
    required this.cognitive,
  });

  final int nesting;
  final int cyclomatic;
  final int cognitive;
}

final class _ComplexityVisitor extends RecursiveAstVisitor<void> {
  var currentNesting = 0;
  var maximumNesting = 0;
  var cyclomatic = 1;
  var cognitive = 0;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitIfStatement(IfStatement node) {
    final parent = node.parent;
    final isElseIf = parent is IfStatement && parent.elseStatement == node;
    cyclomatic++;
    if (isElseIf) {
      cognitive++;
      super.visitIfStatement(node);
      if (node.elseStatement != null && node.elseStatement is! IfStatement) {
        cognitive++;
      }
      return;
    }
    _nested(() => super.visitIfStatement(node));
    if (node.elseStatement != null && node.elseStatement is! IfStatement) {
      cognitive++;
    }
  }

  @override
  void visitForStatement(ForStatement node) {
    cyclomatic++;
    _nested(() => super.visitForStatement(node));
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    cyclomatic++;
    _nested(() => super.visitWhileStatement(node));
  }

  @override
  void visitDoStatement(DoStatement node) {
    cyclomatic++;
    _nested(() => super.visitDoStatement(node));
  }

  @override
  void visitCatchClause(CatchClause node) {
    cyclomatic++;
    _nested(() => super.visitCatchClause(node));
  }

  @override
  void visitSwitchStatement(SwitchStatement node) =>
      _nested(() => super.visitSwitchStatement(node));

  @override
  void visitSwitchCase(SwitchCase node) {
    cyclomatic++;
    super.visitSwitchCase(node);
  }

  @override
  void visitSwitchPatternCase(SwitchPatternCase node) {
    cyclomatic++;
    super.visitSwitchPatternCase(node);
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    _nested(() => super.visitSwitchExpression(node));
  }

  @override
  void visitSwitchExpressionCase(SwitchExpressionCase node) {
    cyclomatic++;
    super.visitSwitchExpressionCase(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    cyclomatic++;
    _nested(() => super.visitConditionalExpression(node));
  }

  @override
  void visitIfElement(IfElement node) {
    cyclomatic++;
    final parent = node.parent;
    final isElseIf = parent is IfElement && parent.elseElement == node;
    if (isElseIf) {
      cognitive++;
      super.visitIfElement(node);
      if (node.elseElement != null && node.elseElement is! IfElement) {
        cognitive++;
      }
      return;
    }
    _nested(() => super.visitIfElement(node));
    if (node.elseElement != null && node.elseElement is! IfElement) {
      cognitive++;
    }
  }

  @override
  void visitForElement(ForElement node) {
    cyclomatic++;
    _nested(() => super.visitForElement(node));
  }

  @override
  void visitGuardedPattern(GuardedPattern node) {
    if (node.whenClause != null) {
      cyclomatic++;
      cognitive++;
    }
    super.visitGuardedPattern(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final operator = node.operator.lexeme;
    if (operator == '&&' || operator == '||') {
      cyclomatic++;
      cognitive++;
    }
    super.visitBinaryExpression(node);
  }

  @override
  void visitLogicalAndPattern(LogicalAndPattern node) {
    cyclomatic++;
    cognitive++;
    super.visitLogicalAndPattern(node);
  }

  @override
  void visitLogicalOrPattern(LogicalOrPattern node) {
    cyclomatic++;
    cognitive++;
    super.visitLogicalOrPattern(node);
  }

  void _nested(void Function() visitChildren) {
    cognitive += 1 + currentNesting;
    currentNesting++;
    if (currentNesting > maximumNesting) maximumNesting = currentNesting;
    visitChildren();
    currentNesting--;
  }
}
