import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../read_model/map_view.dart';
import '../read_model/pending_action_view.dart';
import '../read_model/player_map_view.dart';

final class PendingActionViewMapper {
  const PendingActionViewMapper();

  PendingActionView? fromWire(
    AonwPendingActionView? wire, {
    required String actorPlayerId,
    required List<VisibleUnitView> units,
    required MapView map,
  }) {
    if (wire == null) return null;
    return switch (wire) {
      AonwPendingResearchSelection() => const PendingResearchSelectionView(),
      AonwPendingCityActionView() => _cityAction(wire),
      AonwPendingUnitActionView() => _unitAction(
        wire,
        actorPlayerId: actorPlayerId,
        units: units,
        map: map,
      ),
    };
  }

  static PendingActionView _cityAction(AonwPendingCityActionView wire) {
    final cityId = _cityId(wire.cityId);
    return switch (wire) {
      AonwPendingCityWorkedHexSelection() => PendingCityWorkedHexSelectionView(
        cityId: cityId,
      ),
      AonwPendingCityExpansionSelection() => PendingCityExpansionSelectionView(
        cityId: cityId,
      ),
    };
  }

  static PendingActionView _unitAction(
    AonwPendingUnitActionView wire, {
    required String actorPlayerId,
    required List<VisibleUnitView> units,
    required MapView map,
  }) {
    final unitId = _controlledUnitId(wire.unitId, actorPlayerId, units);
    return switch (wire) {
      AonwPendingWorkerActionSelection(:final improvement) =>
        PendingWorkerActionSelectionView(
          unitId: unitId,
          improvement: improvement == null
              ? null
              : FieldImprovementKind.values.byName(improvement.name),
        ),
      AonwPendingMerchantTradeRouteSelection() =>
        PendingMerchantTradeRouteSelectionView(unitId: unitId),
      AonwPendingMerchantMoveToCitySelection() =>
        PendingMerchantMoveToCitySelectionView(unitId: unitId),
      AonwPendingUnitTurnSkip(:final restoreMovementUnits) =>
        PendingUnitTurnSkipView(
          unitId: unitId,
          restoreMovementUnits: restoreMovementUnits,
        ),
      AonwPendingAttackTargeting(:final defender) => PendingAttackTargetingView(
        unitId: unitId,
        defender: _defender(defender, map),
      ),
      AonwPendingCommanderMergeSelection() =>
        PendingCommanderMergeSelectionView(unitId: unitId),
    };
  }

  static String _cityId(String value) {
    if (value.isEmpty) {
      throw const FormatException('Pending action city id is empty.');
    }
    return value;
  }

  static String _controlledUnitId(
    String value,
    String actorPlayerId,
    List<VisibleUnitView> units,
  ) {
    for (final unit in units) {
      if (unit.id == value && unit.ownerPlayerId == actorPlayerId) return value;
    }
    throw const FormatException(
      'Pending action does not reference a controlled unit.',
    );
  }

  static MapHexCoordinate? _defender(AonwCoordinate? value, MapView map) {
    if (value == null) return null;
    final coordinate = (col: value.col, row: value.row);
    if (!map.contains(coordinate)) {
      throw const FormatException(
        'Pending attack defender is outside the map.',
      );
    }
    return coordinate;
  }
}
