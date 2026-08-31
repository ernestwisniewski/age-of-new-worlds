import 'package:aonw_engine_client/src/protocol_coordinate.dart';
import 'package:aonw_engine_client/src/protocol_json.dart';

enum AonwClientFeature {
  artifacts,
  cities,
  combat,
  inspectMap,
  matchStart,
  actorHandoff,
  aiTurns,
  snapshot,
  reachable,
  routePlan,
  moveUnit,
  unitActions,
  turnKernel,
  saveGame,
  replayVerification,
  replayPlayback,
  movementLogistics,
  workers,
  production,
  research,
  diplomacy;

  factory AonwClientFeature.fromJson(Object? value) {
    final wire = readString(value, 'client feature');
    return values.firstWhere(
      (feature) => feature.name == wire,
      orElse: () => throw FormatException('Unknown AoNW client feature $wire.'),
    );
  }
}

enum AonwResourceType {
  wheat,
  fish,
  deer,
  sheep,
  rice,
  cow,
  apple,
  banana,
  citrus,
  gold,
  silver,
  gems,
  silk,
  spices,
  cotton,
  grapes,
  ivory,
  pearls,
  coffee,
  cocoa,
  tobacco,
  sugar,
  iron,
  coal,
  oil,
  aluminium,
  uranium,
  horses,
  marble;

  factory AonwResourceType.fromJson(Object? source) {
    final wire = readString(source, 'resource type');
    return values.firstWhere(
      (resource) => resource.name == wire,
      orElse: () => throw FormatException('Unknown AoNW resource type $wire.'),
    );
  }
}

enum AonwUnitKind {
  commander,
  warrior,
  archer,
  settler,
  worker,
  merchant,
  scout,
  spearman,
  cavalry,
  catapult,
  heavyInfantry,
  fieldCannon,
  rifleman,
  tank,
  scoutShip,
  warship,
  reconPlane;

  factory AonwUnitKind.fromJson(Object? value) {
    final wire = readString(value, 'unit kind');
    return values.firstWhere(
      (kind) => kind.name == wire,
      orElse: () => throw FormatException('Unknown AoNW unit kind $wire.'),
    );
  }
}

enum AonwUnitPosture {
  active,
  fortified,
  autoExploring,
  autoWorking;

  factory AonwUnitPosture.fromJson(Object? value) {
    final wire = readString(value, 'unit posture');
    return values.firstWhere(
      (posture) => posture.name == wire,
      orElse: () => throw FormatException('Unknown AoNW unit posture $wire.'),
    );
  }
}

enum AonwCityConquestAction { capture, destroy }

final class AonwSessionStamp {
  const AonwSessionStamp({
    required this.revision,
    required this.stateDigest,
    required this.mapHash,
    required this.rulesetHash,
  });

  factory AonwSessionStamp.fromJson(Object? source) {
    final value = readObject(source, 'session stamp');
    requireKeys(value, const {
      'revision',
      'stateDigest',
      'mapHash',
      'rulesetHash',
    }, 'session stamp');
    return AonwSessionStamp(
      revision: readUnsigned(value['revision'], 'state revision'),
      stateDigest: readString(value['stateDigest'], 'state digest'),
      mapHash: readString(value['mapHash'], 'map hash'),
      rulesetHash: readString(value['rulesetHash'], 'ruleset hash'),
    );
  }

  final int revision;
  final String stateDigest;
  final String mapHash;
  final String rulesetHash;
}

final class AonwMovementStep {
  const AonwMovementStep({
    required this.coordinate,
    required this.enterCostUnits,
    required this.cumulativeCostUnits,
  });

  factory AonwMovementStep.fromJson(Object? source) {
    final value = readObject(source, 'movement step');
    requireKeys(value, const {
      'coordinate',
      'enterCostUnits',
      'cumulativeCostUnits',
    }, 'movement step');
    return AonwMovementStep(
      coordinate: AonwCoordinate.fromJson(value['coordinate']),
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

final class AonwReachableTile {
  const AonwReachableTile({
    required this.coordinate,
    required this.costUnits,
    required this.exhaustsMovement,
  });

  factory AonwReachableTile.fromJson(Object? source) {
    final value = readObject(source, 'reachable tile');
    requireKeys(value, const {
      'coordinate',
      'costUnits',
      'exhaustsMovement',
    }, 'reachable tile');
    return AonwReachableTile(
      coordinate: AonwCoordinate.fromJson(value['coordinate']),
      costUnits: readUnsigned(value['costUnits'], 'reachable cost'),
      exhaustsMovement: readBool(
        value['exhaustsMovement'],
        'reachable exhaustion',
      ),
    );
  }

  final AonwCoordinate coordinate;
  final int costUnits;
  final bool exhaustsMovement;
}
