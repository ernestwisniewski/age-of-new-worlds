import 'dart:collection';

import 'package:aonw_engine_client/aonw_engine_client.dart';

typedef _CombatIdentity = (String attacker, String kind, String target);

/// Matches disclosed results without shifting later battles past a withheld
/// result. Repeated identities require complete evidence to be unambiguous.
final class MapCombatEvidenceIndex {
  MapCombatEvidenceIndex(
    AonwClientEvidence? evidence,
    List<AonwClientEvent> events,
  ) {
    final counts = <_CombatIdentity, int>{};
    for (final event in events.whereType<AonwCombatResolvedEvent>()) {
      final key = _identity(event.attackerUnitId, event.target);
      counts.update(key, (count) => count + 1, ifAbsent: () => 1);
    }
    final executions = switch (evidence) {
      AonwCombatEvidence(:final execution) => [execution],
      AonwTurnKernelEvidence(:final combatExecutions) => combatExecutions,
      _ => const <AonwCombatExecution>[],
    };
    for (final execution in executions) {
      final preview = execution.preview;
      final key = _identity(preview.attackerUnitId, preview.target);
      (_pending[key] ??= Queue()).add(execution);
    }
    _pending.removeWhere((key, values) => counts[key] != values.length);
  }

  final _pending = <_CombatIdentity, Queue<AonwCombatExecution>>{};

  AonwCombatExecution? take(AonwCombatResolvedEvent event) {
    final queue = _pending[_identity(event.attackerUnitId, event.target)];
    return queue == null || queue.isEmpty ? null : queue.removeFirst();
  }

  static _CombatIdentity _identity(String attacker, AonwCombatTarget target) =>
      switch (target) {
        AonwUnitCombatTarget(:final unitId) => (attacker, 'unit', unitId),
        AonwCityCombatTarget(:final cityId) => (attacker, 'city', cityId),
      };
}
