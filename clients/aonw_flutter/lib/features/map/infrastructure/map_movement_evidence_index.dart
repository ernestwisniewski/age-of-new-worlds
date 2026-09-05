import 'dart:collection';

import 'package:aonw_engine_client/aonw_engine_client.dart';

typedef _MovementIdentity = (String, int, int, int, int);

final class MapMovementEvidenceIndex {
  MapMovementEvidenceIndex(
    AonwClientEvidence? evidence,
    List<AonwClientEvent> events,
  ) {
    final counts = <_MovementIdentity, int>{};
    for (final event in events.whereType<AonwUnitMovedEvent>()) {
      final key = _identity(event.unitId, event.from, event.to);
      counts.update(key, (count) => count + 1, ifAbsent: () => 1);
    }
    for (final execution in _executions(evidence)) {
      if (execution.steps.isEmpty) continue;
      final key = _identity(
        execution.unitId,
        execution.from,
        execution.steps.last.coordinate,
      );
      (_pending[key] ??= Queue()).add(execution);
    }
    _pending.removeWhere((key, values) => counts[key] != values.length);
  }

  final _pending = <_MovementIdentity, Queue<AonwUnitMovementExecution>>{};

  AonwUnitMovementExecution? take(AonwUnitMovedEvent event) {
    final queue = _pending[_identity(event.unitId, event.from, event.to)];
    return queue == null || queue.isEmpty ? null : queue.removeFirst();
  }

  static _MovementIdentity _identity(
    String unit,
    AonwCoordinate from,
    AonwCoordinate to,
  ) => (unit, from.col, from.row, to.col, to.row);
}

Iterable<AonwUnitMovementExecution> _executions(AonwClientEvidence? evidence) =>
    switch (evidence) {
      AonwUnitMovementEvidence(:final unitId, :final from, :final steps) => [
        AonwUnitMovementExecution(unitId: unitId, from: from, steps: steps),
      ],
      AonwTurnKernelEvidence(:final movementExecutions) => movementExecutions,
      AonwLogisticsEvidence(
        execution: AonwAutoExploreExecution(:final movement),
      ) ||
      AonwWorkerAutomationEvidence(:final movement) => [?movement],
      _ => const [],
    };
