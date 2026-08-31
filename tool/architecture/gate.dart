import 'baseline.dart';
import 'dart_metrics.dart';
import 'failure.dart';
import 'git_repository.dart';
import 'policy.dart';
import 'source_census.dart';

final class ArchitectureGate {
  ArchitectureGate({
    required this.repository,
    required this.policyPath,
    required this.baselinePath,
  }) : policy = ArchitecturePolicy.load(policyPath) {
    census = SourceCensus(repository: repository, policy: policy);
    measurer = ArchitectureMeasurer(
      repository: repository,
      policy: policy,
      census: census,
    );
  }

  final GitRepository repository;
  final String policyPath;
  final String baselinePath;
  final ArchitecturePolicy policy;
  late final SourceCensus census;
  late final ArchitectureMeasurer measurer;

  ArchitectureBaseline snapshot() => measurer.measure();

  ArchitectureCheckResult check() {
    final expected = ArchitectureBaseline.load(baselinePath, policy);
    final actual = measurer.measure();
    final failures = actual.exactDifferences(expected);
    if (failures.isNotEmpty) {
      throw ArchitectureFailure(failures.join('\n'));
    }
    return ArchitectureCheckResult(
      fileDebt: actual.fileDebtCount,
      declarationDebt: actual.declarationDebtCount,
      callableLineDebt: actual.callableLineDebtCount,
      nestingDebt: actual.nestingDebtCount,
      cyclomaticDebt: actual.cyclomaticDebtCount,
      cognitiveDebt: actual.cognitiveDebtCount,
    );
  }
}

final class ArchitectureCheckResult {
  const ArchitectureCheckResult({
    required this.fileDebt,
    required this.declarationDebt,
    required this.callableLineDebt,
    required this.nestingDebt,
    required this.cyclomaticDebt,
    required this.cognitiveDebt,
  });

  final int fileDebt;
  final int declarationDebt;
  final int callableLineDebt;
  final int nestingDebt;
  final int cyclomaticDebt;
  final int cognitiveDebt;
}
