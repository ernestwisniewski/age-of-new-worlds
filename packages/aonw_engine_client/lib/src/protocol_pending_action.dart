import 'package:aonw_engine_client/src/protocol_coordinate.dart';
import 'package:aonw_engine_client/src/protocol_json.dart';

enum AonwFieldImprovementKind {
  farm,
  riverFarm,
  mine,
  lumberMill,
  pasture,
  camp,
  quarry,
  fishingBoats,
  orchard,
  plantation,
  vineyard,
  tradingPost,
  prospectorCamp,
  horseRanch,
  pearlDivers,
  coalShaft,
  oilWell,
  bauxiteMine,
  uraniumMine;

  factory AonwFieldImprovementKind.fromJson(Object? source) {
    final name = readString(source, 'field improvement');
    return values.firstWhere(
      (value) => value.name == name,
      orElse: () =>
          throw FormatException('Unknown AoNW field improvement $name.'),
    );
  }
}

sealed class AonwPendingActionView {
  const AonwPendingActionView();

  static final Map<String, AonwPendingActionView Function(Map<String, Object?>)>
  _parsers = {
    'researchSelection': _research,
    'cityWorkedHexSelection': _cityWorkedHex,
    'cityExpansionSelection': _cityExpansion,
    'workerActionSelection': _workerAction,
    'merchantTradeRouteSelection': _merchantTradeRoute,
    'merchantMoveToCitySelection': _merchantMoveToCity,
    'unitTurnSkip': _unitTurnSkip,
    'attackTargeting': _attackTargeting,
    'commanderMergeSelection': _commanderMerge,
  };

  factory AonwPendingActionView.fromJson(Object? source) {
    final value = readObject(source, 'pending action');
    final type = readString(value['type'], 'pending action type');
    final parser = _parsers[type];
    if (parser == null) {
      throw FormatException('Unknown AoNW pending action $type.');
    }
    return parser(value);
  }

  static AonwPendingResearchSelection _research(Map<String, Object?> value) {
    requireKeys(value, const {'type'}, 'research selection');
    return const AonwPendingResearchSelection();
  }

  static AonwPendingCityWorkedHexSelection _cityWorkedHex(
    Map<String, Object?> value,
  ) {
    requireKeys(value, const {'type', 'cityId'}, 'worked hex selection');
    return AonwPendingCityWorkedHexSelection(
      cityId: readString(value['cityId'], 'worked hex city id'),
    );
  }

  static AonwPendingCityExpansionSelection _cityExpansion(
    Map<String, Object?> value,
  ) {
    requireKeys(value, const {'type', 'cityId'}, 'city expansion selection');
    return AonwPendingCityExpansionSelection(
      cityId: readString(value['cityId'], 'expanding city id'),
    );
  }

  static AonwPendingWorkerActionSelection _workerAction(
    Map<String, Object?> value,
  ) {
    requireKeys(value, const {
      'type',
      'unitId',
      'improvement',
    }, 'worker action selection');
    final improvement = value['improvement'];
    return AonwPendingWorkerActionSelection(
      unitId: readString(value['unitId'], 'worker unit id'),
      improvement: improvement == null
          ? null
          : AonwFieldImprovementKind.fromJson(improvement),
    );
  }

  static AonwPendingMerchantTradeRouteSelection _merchantTradeRoute(
    Map<String, Object?> value,
  ) {
    requireKeys(value, const {
      'type',
      'unitId',
    }, 'merchant trade route selection');
    return AonwPendingMerchantTradeRouteSelection(
      unitId: readString(value['unitId'], 'merchant unit id'),
    );
  }

  static AonwPendingMerchantMoveToCitySelection _merchantMoveToCity(
    Map<String, Object?> value,
  ) {
    requireKeys(value, const {'type', 'unitId'}, 'merchant city selection');
    return AonwPendingMerchantMoveToCitySelection(
      unitId: readString(value['unitId'], 'merchant unit id'),
    );
  }

  static AonwPendingUnitTurnSkip _unitTurnSkip(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'unitId',
      'restoreMovementUnits',
    }, 'unit turn skip');
    return AonwPendingUnitTurnSkip(
      unitId: readString(value['unitId'], 'skipped unit id'),
      restoreMovementUnits: readUnsigned(
        value['restoreMovementUnits'],
        'restored movement units',
      ),
    );
  }

  static AonwPendingAttackTargeting _attackTargeting(
    Map<String, Object?> value,
  ) {
    requireKeys(value, const {
      'type',
      'unitId',
      'defender',
    }, 'attack targeting');
    final defender = value['defender'];
    return AonwPendingAttackTargeting(
      unitId: readString(value['unitId'], 'attacking unit id'),
      defender: defender == null ? null : AonwCoordinate.fromJson(defender),
    );
  }

  static AonwPendingCommanderMergeSelection _commanderMerge(
    Map<String, Object?> value,
  ) {
    requireKeys(value, const {'type', 'unitId'}, 'commander merge selection');
    return AonwPendingCommanderMergeSelection(
      unitId: readString(value['unitId'], 'commander unit id'),
    );
  }
}

final class AonwPendingResearchSelection extends AonwPendingActionView {
  const AonwPendingResearchSelection();
}

sealed class AonwPendingCityActionView extends AonwPendingActionView {
  const AonwPendingCityActionView({required this.cityId});

  final String cityId;
}

final class AonwPendingCityWorkedHexSelection
    extends AonwPendingCityActionView {
  const AonwPendingCityWorkedHexSelection({required super.cityId});
}

final class AonwPendingCityExpansionSelection
    extends AonwPendingCityActionView {
  const AonwPendingCityExpansionSelection({required super.cityId});
}

sealed class AonwPendingUnitActionView extends AonwPendingActionView {
  const AonwPendingUnitActionView({required this.unitId});

  final String unitId;
}

final class AonwPendingWorkerActionSelection extends AonwPendingUnitActionView {
  const AonwPendingWorkerActionSelection({
    required super.unitId,
    required this.improvement,
  });

  final AonwFieldImprovementKind? improvement;
}

final class AonwPendingMerchantTradeRouteSelection
    extends AonwPendingUnitActionView {
  const AonwPendingMerchantTradeRouteSelection({required super.unitId});
}

final class AonwPendingMerchantMoveToCitySelection
    extends AonwPendingUnitActionView {
  const AonwPendingMerchantMoveToCitySelection({required super.unitId});
}

final class AonwPendingUnitTurnSkip extends AonwPendingUnitActionView {
  const AonwPendingUnitTurnSkip({
    required super.unitId,
    required this.restoreMovementUnits,
  });

  final int restoreMovementUnits;
}

final class AonwPendingAttackTargeting extends AonwPendingUnitActionView {
  const AonwPendingAttackTargeting({
    required super.unitId,
    required this.defender,
  });

  final AonwCoordinate? defender;
}

final class AonwPendingCommanderMergeSelection
    extends AonwPendingUnitActionView {
  const AonwPendingCommanderMergeSelection({required super.unitId});
}
