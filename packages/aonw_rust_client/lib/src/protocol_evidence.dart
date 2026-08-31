import 'package:aonw_rust_client/src/protocol_coordinate.dart';
import 'package:aonw_rust_client/src/protocol_json.dart';
import 'package:aonw_rust_client/src/protocol_pending_action.dart';
import 'package:aonw_rust_client/src/protocol_player_view.dart';
import 'package:aonw_rust_client/src/protocol_values.dart';

part 'protocol_combat_evidence.dart';
part 'protocol_logistics_evidence.dart';

sealed class AonwClientEvidence {
  const AonwClientEvidence();

  factory AonwClientEvidence.fromJson(Object? source) {
    final value = readObject(source, 'client evidence');
    return switch (readString(value['type'], 'client evidence type')) {
      'combat' => AonwCombatEvidence.fromJson(value),
      'unitMovement' => AonwUnitMovementEvidence.fromJson(value),
      'logistics' => AonwLogisticsEvidence.fromJson(value),
      'workerAutomation' => AonwWorkerAutomationEvidence.fromJson(value),
      'turnKernel' => AonwTurnKernelEvidence.fromJson(value),
      final String type => throw FormatException(
        'Unknown AoNW client evidence $type.',
      ),
    };
  }
}

final class AonwUnitMovementEvidence extends AonwClientEvidence {
  const AonwUnitMovementEvidence({
    required this.unitId,
    required this.from,
    required this.steps,
  });

  factory AonwUnitMovementEvidence.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'unitId',
      'from',
      'steps',
    }, 'unit movement evidence');
    return AonwUnitMovementEvidence(
      unitId: readString(value['unitId'], 'evidence unit id'),
      from: AonwCoordinate.fromJson(value['from']),
      steps: _movementSteps(value['steps'], 'movement evidence steps'),
    );
  }

  final String unitId;
  final AonwCoordinate from;
  final List<AonwMovementStep> steps;
}

final class AonwUnitMovementExecution {
  const AonwUnitMovementExecution({
    required this.unitId,
    required this.from,
    required this.steps,
  });

  factory AonwUnitMovementExecution.fromJson(Object? source) {
    final value = readObject(source, 'unit movement execution');
    requireKeys(value, const {
      'unitId',
      'from',
      'steps',
    }, 'unit movement execution');
    return AonwUnitMovementExecution(
      unitId: readString(value['unitId'], 'execution unit id'),
      from: AonwCoordinate.fromJson(value['from']),
      steps: _movementSteps(value['steps'], 'execution movement steps'),
    );
  }

  final String unitId;
  final AonwCoordinate from;
  final List<AonwMovementStep> steps;
}

final class AonwTurnKernelEvidence extends AonwClientEvidence {
  AonwTurnKernelEvidence({
    required List<String> processors,
    required List<String> foundedCityIds,
    required List<AonwCombatExecution> combatExecutions,
    required List<String> resetUnitIds,
    required List<AonwUnitMovementExecution> movementExecutions,
    required List<String> invalidatedOrderUnitIds,
    required List<String> finishedAutoExploreUnitIds,
  }) : processors = List.unmodifiable(processors),
       foundedCityIds = List.unmodifiable(foundedCityIds),
       combatExecutions = List.unmodifiable(combatExecutions),
       resetUnitIds = List.unmodifiable(resetUnitIds),
       movementExecutions = List.unmodifiable(movementExecutions),
       invalidatedOrderUnitIds = List.unmodifiable(invalidatedOrderUnitIds),
       finishedAutoExploreUnitIds = List.unmodifiable(
         finishedAutoExploreUnitIds,
       );

  factory AonwTurnKernelEvidence.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'processors',
      'foundedCityIds',
      'combatExecutions',
      'resetUnitIds',
      'movementExecutions',
      'invalidatedOrderUnitIds',
      'finishedAutoExploreUnitIds',
    }, 'turn kernel evidence');
    return AonwTurnKernelEvidence(
      processors: _strings(value['processors'], 'turn processors'),
      foundedCityIds: _strings(value['foundedCityIds'], 'founded city ids'),
      combatExecutions: readList(
        value['combatExecutions'],
        'turn combat executions',
        (item, _) => AonwCombatExecution.fromJson(item),
      ),
      resetUnitIds: _strings(value['resetUnitIds'], 'reset unit ids'),
      movementExecutions: readList(
        value['movementExecutions'],
        'turn movement executions',
        (item, _) => AonwUnitMovementExecution.fromJson(item),
      ),
      invalidatedOrderUnitIds: _strings(
        value['invalidatedOrderUnitIds'],
        'invalidated order unit ids',
      ),
      finishedAutoExploreUnitIds: _strings(
        value['finishedAutoExploreUnitIds'],
        'finished auto explore unit ids',
      ),
    );
  }

  final List<String> processors;
  final List<String> foundedCityIds;
  final List<AonwCombatExecution> combatExecutions;
  final List<String> resetUnitIds;
  final List<AonwUnitMovementExecution> movementExecutions;
  final List<String> invalidatedOrderUnitIds;
  final List<String> finishedAutoExploreUnitIds;
}

List<AonwMovementStep> _movementSteps(Object? source, String label) =>
    readList(source, label, (item, _) => AonwMovementStep.fromJson(item));

List<String> _strings(Object? source, String label) =>
    readList(source, label, (item, _) => readString(item, label));

int? _nullableUnsigned(Object? source, String label) =>
    source == null ? null : readUnsigned(source, label);

T _enum<T extends Enum>(Object? source, List<T> values, String label) {
  final wire = readString(source, label);
  for (final value in values) {
    if (value.name == wire) return value;
  }
  throw FormatException('Unknown AoNW $label $wire.');
}
