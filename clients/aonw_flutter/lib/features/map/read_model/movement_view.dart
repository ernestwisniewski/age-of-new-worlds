import 'map_view.dart';
import 'player_map_view.dart';

final class ReachableTileView {
  const ReachableTileView({
    required this.coordinate,
    required this.costUnits,
    required this.exhaustsMovement,
  });

  final MapHexCoordinate coordinate;
  final int costUnits;
  final bool exhaustsMovement;
}

final class ReachableView {
  ReachableView({
    required this.stamp,
    required this.unitId,
    required this.availableMovementUnits,
    required List<ReachableTileView> tiles,
  }) : tiles = List.unmodifiable(tiles),
       _tilesByCoordinate = Map.unmodifiable({
         for (final tile in tiles) tile.coordinate: tile,
       });

  final SessionStampView stamp;
  final String unitId;
  final int availableMovementUnits;
  final List<ReachableTileView> tiles;
  final Map<MapHexCoordinate, ReachableTileView> _tilesByCoordinate;

  ReachableTileView? tileAt(MapHexCoordinate coordinate) =>
      _tilesByCoordinate[coordinate];
}

final class MovementStepView {
  const MovementStepView({
    required this.coordinate,
    required this.enterCostUnits,
    required this.cumulativeCostUnits,
  });

  final MapHexCoordinate coordinate;
  final int enterCostUnits;
  final int cumulativeCostUnits;
}

final class RoutePlanView {
  RoutePlanView({
    required this.stamp,
    required this.unitId,
    required this.target,
    required this.destination,
    required this.totalCostUnits,
    required this.availableMovementUnits,
    required this.remainingMovementUnits,
    required List<MovementStepView> steps,
  }) : steps = List.unmodifiable(steps);

  final SessionStampView stamp;
  final String unitId;
  final MapHexCoordinate target;
  final MapHexCoordinate destination;
  final int totalCostUnits;
  final int availableMovementUnits;
  final int remainingMovementUnits;
  final List<MovementStepView> steps;
}

enum CommandRejectionCodeView {
  staleRevision('stale_revision'),
  unitNotFound('unit_not_found'),
  unitNotControlled('unit_not_controlled'),
  unitUnavailable('unit_unavailable'),
  unitUsesTradeRoutes('unit_uses_trade_routes'),
  unitOutOfBounds('unit_out_of_bounds'),
  moveTargetOutOfBounds('move_target_out_of_bounds'),
  moveTargetIsCurrentTile('move_target_is_current_tile'),
  moveTargetIsForeignCityCenter('move_target_is_foreign_city_center'),
  moveTargetOccupied('move_target_occupied'),
  unitMovementCapacityInsufficient('unit_movement_capacity_insufficient'),
  movePathNotFound('move_path_not_found'),
  unitBusy('unit_busy'),
  unitDefinitionMissing('unit_definition_missing'),
  stateRevisionOverflow('state_revision_overflow'),
  invalidQueuedMovementPath('invalid_queued_movement_path'),
  invalidUnit('invalid_unit'),
  movementUnitUpdateFailed('movement_unit_update_failed');

  const CommandRejectionCodeView(this.wireCode);

  final String wireCode;
}

final class UnitMovedEventView {
  const UnitMovedEventView({
    required this.unitId,
    required this.from,
    required this.to,
  });

  final String unitId;
  final MapHexCoordinate from;
  final MapHexCoordinate to;
}

final class UnitMovementEvidenceView {
  UnitMovementEvidenceView({
    required this.unitId,
    required this.from,
    required List<MovementStepView> steps,
  }) : steps = List.unmodifiable(steps);

  final String unitId;
  final MapHexCoordinate from;
  final List<MovementStepView> steps;
}

final class MoveUnitExecutionView {
  MoveUnitExecutionView({
    required List<UnitMovedEventView> events,
    required this.evidence,
  }) : events = List.unmodifiable(events);

  final List<UnitMovedEventView> events;
  final UnitMovementEvidenceView? evidence;
}

final class MoveUnitResultView {
  const MoveUnitResultView.accepted({
    required this.player,
    required this.execution,
  }) : accepted = true,
       rejectionCode = null;

  const MoveUnitResultView.rejected({required CommandRejectionCodeView code})
    : accepted = false,
      rejectionCode = code,
      player = null,
      execution = null;

  final bool accepted;
  final CommandRejectionCodeView? rejectionCode;
  final PlayerMapView? player;
  final MoveUnitExecutionView? execution;
}
