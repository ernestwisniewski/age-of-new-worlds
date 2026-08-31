part of 'protocol_player_view.dart';

enum AonwPlayerTurnState {
  active,
  finished;

  factory AonwPlayerTurnState.fromJson(Object? source) {
    final name = readString(source, 'player turn state');
    return values.firstWhere(
      (value) => value.name == name,
      orElse: () => throw FormatException('Unknown AoNW turn state $name.'),
    );
  }
}

final class AonwPlayerTurnLifecycle {
  const AonwPlayerTurnLifecycle({
    required this.ownState,
    required this.ownSubmitted,
    required this.requiredSubmissionCount,
    required this.submittedCount,
  });

  factory AonwPlayerTurnLifecycle.fromJson(Object? source) {
    final value = readObject(source, 'player turn lifecycle');
    requireKeys(value, const {
      'ownState',
      'ownSubmitted',
      'requiredSubmissionCount',
      'submittedCount',
    }, 'player turn lifecycle');
    return AonwPlayerTurnLifecycle(
      ownState: value['ownState'] == null
          ? null
          : AonwPlayerTurnState.fromJson(value['ownState']),
      ownSubmitted: readBool(value['ownSubmitted'], 'own submitted state'),
      requiredSubmissionCount: readUnsigned(
        value['requiredSubmissionCount'],
        'required submission count',
      ),
      submittedCount: readUnsigned(value['submittedCount'], 'submitted count'),
    );
  }

  final AonwPlayerTurnState? ownState;
  final bool ownSubmitted;
  final int requiredSubmissionCount;
  final int submittedCount;
}

enum AonwTransportCondition {
  operational,
  pillaged;

  factory AonwTransportCondition.fromJson(Object? source) {
    final name = readString(source, 'transport condition');
    return values.firstWhere(
      (value) => value.name == name,
      orElse: () =>
          throw FormatException('Unknown AoNW transport condition $name.'),
    );
  }
}

final class AonwFieldImprovementView {
  const AonwFieldImprovementView({
    required this.coordinate,
    required this.improvement,
  });

  factory AonwFieldImprovementView.fromJson(Object? source) {
    final value = readObject(source, 'field improvement view');
    requireKeys(value, const {
      'coordinate',
      'improvement',
    }, 'field improvement view');
    return AonwFieldImprovementView(
      coordinate: AonwCoordinate.fromJson(value['coordinate']),
      improvement: AonwFieldImprovementKind.fromJson(value['improvement']),
    );
  }

  final AonwCoordinate coordinate;
  final AonwFieldImprovementKind improvement;
}

final class AonwRoadView {
  const AonwRoadView({required this.coordinate, required this.condition});

  factory AonwRoadView.fromJson(Object? source) {
    final value = readObject(source, 'road view');
    requireKeys(value, const {'coordinate', 'condition'}, 'road view');
    return AonwRoadView(
      coordinate: AonwCoordinate.fromJson(value['coordinate']),
      condition: AonwTransportCondition.fromJson(value['condition']),
    );
  }

  final AonwCoordinate coordinate;
  final AonwTransportCondition condition;
}

sealed class AonwWorkerJobView {
  const AonwWorkerJobView({
    required this.target,
    required this.remainingTurns,
    required this.totalTurns,
  });

  factory AonwWorkerJobView.fromJson(Object? source) {
    final value = readObject(source, 'worker job view');
    return switch (value['type']) {
      'fieldImprovement' => AonwFieldImprovementJobView.fromJson(value),
      'roadConstruction' => AonwRoadConstructionJobView.fromJson(value),
      final Object? type => throw FormatException('Unknown worker job $type.'),
    };
  }

  final AonwCoordinate target;
  final int remainingTurns;
  final int totalTurns;
}

final class AonwFieldImprovementJobView extends AonwWorkerJobView {
  const AonwFieldImprovementJobView({
    required super.target,
    required this.improvement,
    required super.remainingTurns,
    required super.totalTurns,
  });

  factory AonwFieldImprovementJobView.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'target',
      'improvement',
      'remainingTurns',
      'totalTurns',
    }, 'field improvement worker job');
    return AonwFieldImprovementJobView(
      target: AonwCoordinate.fromJson(value['target']),
      improvement: AonwFieldImprovementKind.fromJson(value['improvement']),
      remainingTurns: readUnsigned(value['remainingTurns'], 'remaining turns'),
      totalTurns: readUnsigned(value['totalTurns'], 'total turns'),
    );
  }

  final AonwFieldImprovementKind improvement;
}

final class AonwRoadConstructionJobView extends AonwWorkerJobView {
  const AonwRoadConstructionJobView({
    required super.target,
    required super.remainingTurns,
    required super.totalTurns,
  });

  factory AonwRoadConstructionJobView.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'target',
      'remainingTurns',
      'totalTurns',
    }, 'road construction worker job');
    return AonwRoadConstructionJobView(
      target: AonwCoordinate.fromJson(value['target']),
      remainingTurns: readUnsigned(value['remainingTurns'], 'remaining turns'),
      totalTurns: readUnsigned(value['totalTurns'], 'total turns'),
    );
  }
}

enum AonwTroopKind {
  warrior,
  archer,
  settler;

  factory AonwTroopKind.fromJson(Object? source) {
    final wire = readString(source, 'troop kind');
    return values.firstWhere(
      (kind) => kind.name == wire,
      orElse: () => throw FormatException('Unknown AoNW troop kind $wire.'),
    );
  }
}

final class AonwArmyTroop {
  const AonwArmyTroop({required this.kind, required this.count});

  factory AonwArmyTroop.fromJson(Object? source) {
    final value = readObject(source, 'army troop');
    requireKeys(value, const {'kind', 'count'}, 'army troop');
    return AonwArmyTroop(
      kind: AonwTroopKind.fromJson(value['kind']),
      count: readUnsigned(value['count'], 'troop count'),
    );
  }

  final AonwTroopKind kind;
  final int count;
}

final class AonwPersistedMovementStep {
  const AonwPersistedMovementStep({
    required this.coordinate,
    required this.enterCostUnits,
    required this.cumulativeCostUnits,
  });

  factory AonwPersistedMovementStep.fromJson(Object? source) {
    final value = readObject(source, 'persisted movement step');
    requireKeys(value, const {
      'col',
      'row',
      'enterCostUnits',
      'cumulativeCostUnits',
    }, 'persisted movement step');
    return AonwPersistedMovementStep(
      coordinate: AonwCoordinate(
        col: readInt(value['col'], 'movement step column'),
        row: readInt(value['row'], 'movement step row'),
      ),
      enterCostUnits: readUnsigned(value['enterCostUnits'], 'step entry cost'),
      cumulativeCostUnits: readUnsigned(
        value['cumulativeCostUnits'],
        'step cumulative cost',
      ),
    );
  }

  final AonwCoordinate coordinate;
  final int enterCostUnits;
  final int cumulativeCostUnits;
}

final class AonwQueuedMovePath {
  const AonwQueuedMovePath({required this.target, required this.steps});

  factory AonwQueuedMovePath.fromJson(Object? source) {
    final value = readObject(source, 'queued movement path');
    requireKeys(value, const {
      'targetCol',
      'targetRow',
      'steps',
    }, 'queued movement path');
    return AonwQueuedMovePath(
      target: AonwCoordinate(
        col: readInt(value['targetCol'], 'queued target column'),
        row: readInt(value['targetRow'], 'queued target row'),
      ),
      steps: readList(
        value['steps'],
        'queued movement steps',
        (item, _) => AonwPersistedMovementStep.fromJson(item),
      ),
    );
  }

  final AonwCoordinate target;
  final List<AonwPersistedMovementStep> steps;
}

final class AonwMerchantTradeRoute {
  const AonwMerchantTradeRoute({
    required this.originCityId,
    required this.destinationCityId,
    required this.steps,
    required this.transportNetworkFingerprint,
  });

  factory AonwMerchantTradeRoute.fromJson(Object? source) {
    final value = readObject(source, 'merchant trade route');
    requireKeys(value, const {
      'originCityId',
      'destinationCityId',
      'steps',
      'transportNetworkFingerprint',
    }, 'merchant trade route');
    return AonwMerchantTradeRoute(
      originCityId: readString(value['originCityId'], 'route origin city'),
      destinationCityId: readString(
        value['destinationCityId'],
        'route destination city',
      ),
      steps: readList(
        value['steps'],
        'merchant route steps',
        (item, _) => AonwPersistedMovementStep.fromJson(item),
      ),
      transportNetworkFingerprint: readString(
        value['transportNetworkFingerprint'],
        'transport network fingerprint',
      ),
    );
  }

  final String originCityId;
  final String destinationCityId;
  final List<AonwPersistedMovementStep> steps;
  final String transportNetworkFingerprint;
}

final class AonwCityFoundingJobView {
  const AonwCityFoundingJobView({
    required this.center,
    required this.controlledHexes,
    required this.remainingTurns,
    required this.totalTurns,
  });

  factory AonwCityFoundingJobView.fromJson(Object? source) {
    final value = readObject(source, 'city founding job');
    requireKeys(value, const {
      'center',
      'controlledHexes',
      'remainingTurns',
      'totalTurns',
    }, 'city founding job');
    return AonwCityFoundingJobView(
      center: AonwCoordinate.fromJson(value['center']),
      controlledHexes: readList(
        value['controlledHexes'],
        'city founding controlled hexes',
        (item, _) => AonwCoordinate.fromJson(item),
      ),
      remainingTurns: readUnsigned(value['remainingTurns'], 'remaining turns'),
      totalTurns: readUnsigned(value['totalTurns'], 'total turns'),
    );
  }

  final AonwCoordinate center;
  final List<AonwCoordinate> controlledHexes;
  final int remainingTurns;
  final int totalTurns;
}

final class AonwOwnedUnitDetails {
  const AonwOwnedUnitDetails({
    required this.army,
    required this.queuedPath,
    required this.merchantTradeRoute,
    required this.workerJob,
    required this.cityFoundingJob,
    required this.workerAssignment,
    required this.excavatingArtifactId,
    required this.workerBuildCharges,
    required this.experiencePoints,
  });

  factory AonwOwnedUnitDetails.fromJson(Object? source) {
    final value = readObject(source, 'owned unit details');
    requireKeys(value, const {
      'army',
      'queuedPath',
      'merchantTradeRoute',
      'workerJob',
      'cityFoundingJob',
      'workerAssignment',
      'excavatingArtifactId',
      'workerBuildCharges',
      'experiencePoints',
    }, 'owned unit details');
    return AonwOwnedUnitDetails(
      army: readList(
        value['army'],
        'unit army',
        (item, _) => AonwArmyTroop.fromJson(item),
      ),
      queuedPath: value['queuedPath'] == null
          ? null
          : AonwQueuedMovePath.fromJson(value['queuedPath']),
      merchantTradeRoute: value['merchantTradeRoute'] == null
          ? null
          : AonwMerchantTradeRoute.fromJson(value['merchantTradeRoute']),
      workerJob: value['workerJob'] == null
          ? null
          : AonwWorkerJobView.fromJson(value['workerJob']),
      cityFoundingJob: value['cityFoundingJob'] == null
          ? null
          : AonwCityFoundingJobView.fromJson(value['cityFoundingJob']),
      workerAssignment: value['workerAssignment'] == null
          ? null
          : AonwCoordinate.fromJson(value['workerAssignment']),
      excavatingArtifactId: readNullableString(
        value['excavatingArtifactId'],
        'excavating artifact id',
      ),
      workerBuildCharges: readUnsigned(
        value['workerBuildCharges'],
        'worker build charges',
      ),
      experiencePoints: readUnsigned(
        value['experiencePoints'],
        'unit experience points',
      ),
    );
  }

  final List<AonwArmyTroop> army;
  final AonwQueuedMovePath? queuedPath;
  final AonwMerchantTradeRoute? merchantTradeRoute;
  final AonwWorkerJobView? workerJob;
  final AonwCityFoundingJobView? cityFoundingJob;
  final AonwCoordinate? workerAssignment;
  final String? excavatingArtifactId;
  final int workerBuildCharges;
  final int experiencePoints;
}
