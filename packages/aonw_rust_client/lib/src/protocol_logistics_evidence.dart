part of 'protocol_evidence.dart';

sealed class AonwLogisticsExecution {
  const AonwLogisticsExecution();

  factory AonwLogisticsExecution.fromJson(Object? source) {
    final value = readObject(source, 'logistics execution');
    return switch (readString(value['type'], 'logistics execution type')) {
      'autoExplore' => AonwAutoExploreExecution.fromJson(value),
      'merchantRouteAssigned' => AonwMerchantRouteExecution.fromJson(value),
      'merchantTravelQueued' => AonwMerchantTravelExecution.fromJson(value),
      'troopDetached' => AonwTroopDetachmentExecution.fromJson(value),
      _ => throw const FormatException('Unknown AoNW logistics execution.'),
    };
  }
}

final class AonwLogisticsEvidence extends AonwClientEvidence {
  const AonwLogisticsEvidence({required this.execution});

  factory AonwLogisticsEvidence.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'execution'}, 'logistics evidence');
    return AonwLogisticsEvidence(
      execution: AonwLogisticsExecution.fromJson(value['execution']),
    );
  }

  final AonwLogisticsExecution execution;
}

final class AonwAutoExploreExecution extends AonwLogisticsExecution {
  const AonwAutoExploreExecution({
    required this.unitId,
    required this.target,
    required this.movement,
  });

  factory AonwAutoExploreExecution.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'unitId',
      'target',
      'movement',
    }, 'auto explore execution');
    return AonwAutoExploreExecution(
      unitId: readString(value['unitId'], 'auto explore unit id'),
      target: AonwCoordinate.fromJson(value['target']),
      movement: value['movement'] == null
          ? null
          : AonwUnitMovementExecution.fromJson(value['movement']),
    );
  }

  final String unitId;
  final AonwCoordinate target;
  final AonwUnitMovementExecution? movement;
}

final class AonwMerchantRouteExecution extends AonwLogisticsExecution {
  const AonwMerchantRouteExecution({
    required this.unitId,
    required this.originCityId,
    required this.destinationCityId,
    required this.steps,
    required this.transportNetworkFingerprint,
  });

  factory AonwMerchantRouteExecution.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'unitId',
      'originCityId',
      'destinationCityId',
      'steps',
      'transportNetworkFingerprint',
    }, 'merchant route execution');
    return AonwMerchantRouteExecution(
      unitId: readString(value['unitId'], 'merchant unit id'),
      originCityId: readString(value['originCityId'], 'route origin city id'),
      destinationCityId: readString(
        value['destinationCityId'],
        'route destination city id',
      ),
      steps: _movementSteps(value['steps'], 'merchant route steps'),
      transportNetworkFingerprint: readString(
        value['transportNetworkFingerprint'],
        'transport network fingerprint',
      ),
    );
  }

  final String unitId;
  final String originCityId;
  final String destinationCityId;
  final List<AonwMovementStep> steps;
  final String transportNetworkFingerprint;
}

final class AonwMerchantTravelExecution extends AonwLogisticsExecution {
  const AonwMerchantTravelExecution({
    required this.unitId,
    required this.destinationCityId,
    required this.steps,
  });

  factory AonwMerchantTravelExecution.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'unitId',
      'destinationCityId',
      'steps',
    }, 'merchant travel execution');
    return AonwMerchantTravelExecution(
      unitId: readString(value['unitId'], 'merchant unit id'),
      destinationCityId: readString(
        value['destinationCityId'],
        'merchant destination city id',
      ),
      steps: _movementSteps(value['steps'], 'merchant travel steps'),
    );
  }

  final String unitId;
  final String destinationCityId;
  final List<AonwMovementStep> steps;
}

final class AonwTroopDetachmentExecution extends AonwLogisticsExecution {
  const AonwTroopDetachmentExecution({
    required this.sourceUnitId,
    required this.detachedUnitId,
    required this.troopKind,
    required this.destination,
  });

  factory AonwTroopDetachmentExecution.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'sourceUnitId',
      'detachedUnitId',
      'troopKind',
      'destination',
    }, 'troop detachment execution');
    return AonwTroopDetachmentExecution(
      sourceUnitId: readString(value['sourceUnitId'], 'source unit id'),
      detachedUnitId: readString(value['detachedUnitId'], 'detached unit id'),
      troopKind: AonwTroopKind.fromJson(value['troopKind']),
      destination: AonwCoordinate.fromJson(value['destination']),
    );
  }

  final String sourceUnitId;
  final String detachedUnitId;
  final AonwTroopKind troopKind;
  final AonwCoordinate destination;
}

sealed class AonwWorkerAutomationAction {
  const AonwWorkerAutomationAction();

  factory AonwWorkerAutomationAction.fromJson(Object? source) {
    final value = readObject(source, 'worker automation action');
    return switch (readString(value['type'], 'worker automation action type')) {
      'improve' => AonwWorkerImproveAction.fromJson(value),
      'assign' => AonwWorkerAssignAction.fromJson(value),
      _ => throw const FormatException(
        'Unknown AoNW worker automation action.',
      ),
    };
  }
}

final class AonwWorkerImproveAction extends AonwWorkerAutomationAction {
  const AonwWorkerImproveAction({required this.improvement});

  factory AonwWorkerImproveAction.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'improvement'}, 'worker improve action');
    return AonwWorkerImproveAction(
      improvement: AonwFieldImprovementKind.fromJson(value['improvement']),
    );
  }

  final AonwFieldImprovementKind improvement;
}

final class AonwWorkerAssignAction extends AonwWorkerAutomationAction {
  const AonwWorkerAssignAction();

  factory AonwWorkerAssignAction.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type'}, 'worker assign action');
    return const AonwWorkerAssignAction();
  }
}

final class AonwWorkerAutomationMetrics {
  const AonwWorkerAutomationMetrics({
    required this.tilesExamined,
    required this.legalityEvaluations,
    required this.routesPlanned,
  });

  factory AonwWorkerAutomationMetrics.fromJson(Object? source) {
    final value = readObject(source, 'worker automation metrics');
    requireKeys(value, const {
      'tilesExamined',
      'legalityEvaluations',
      'routesPlanned',
    }, 'worker automation metrics');
    return AonwWorkerAutomationMetrics(
      tilesExamined: readUnsigned(value['tilesExamined'], 'tiles examined'),
      legalityEvaluations: readUnsigned(
        value['legalityEvaluations'],
        'legality evaluations',
      ),
      routesPlanned: readUnsigned(value['routesPlanned'], 'routes planned'),
    );
  }

  final int tilesExamined;
  final int legalityEvaluations;
  final int routesPlanned;
}

final class AonwWorkerAutomationOption {
  const AonwWorkerAutomationOption({
    required this.target,
    required this.action,
    required this.movementCostUnits,
    required this.metrics,
  });

  factory AonwWorkerAutomationOption.fromJson(Object? source) {
    final value = readObject(source, 'worker automation option');
    requireKeys(value, const {
      'target',
      'action',
      'movementCostUnits',
      'metrics',
    }, 'worker automation option');
    return AonwWorkerAutomationOption(
      target: AonwCoordinate.fromJson(value['target']),
      action: AonwWorkerAutomationAction.fromJson(value['action']),
      movementCostUnits: readUnsigned(
        value['movementCostUnits'],
        'worker movement cost',
      ),
      metrics: AonwWorkerAutomationMetrics.fromJson(value['metrics']),
    );
  }

  final AonwCoordinate target;
  final AonwWorkerAutomationAction action;
  final int movementCostUnits;
  final AonwWorkerAutomationMetrics metrics;
}

final class AonwWorkerAutomationEvidence extends AonwClientEvidence {
  const AonwWorkerAutomationEvidence({
    required this.unitId,
    required this.option,
    required this.movement,
  });

  factory AonwWorkerAutomationEvidence.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'unitId',
      'option',
      'movement',
    }, 'worker automation evidence');
    return AonwWorkerAutomationEvidence(
      unitId: readString(value['unitId'], 'worker unit id'),
      option: AonwWorkerAutomationOption.fromJson(value['option']),
      movement: value['movement'] == null
          ? null
          : AonwUnitMovementExecution.fromJson(value['movement']),
    );
  }

  final String unitId;
  final AonwWorkerAutomationOption option;
  final AonwUnitMovementExecution? movement;
}
