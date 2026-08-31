import 'package:aonw_rust_client/aonw_rust_client.dart';

import '../read_model/map_view.dart';
import '../read_model/movement_view.dart';
import '../read_model/player_map_view.dart';

final class MovementViewMapper {
  const MovementViewMapper();

  ReachableView reachable(
    AonwReachableResult wire, {
    required MapView map,
    required String expectedUnitId,
    required int expectedRevision,
  }) {
    _validateStamp(wire.stamp, map: map, expectedRevision: expectedRevision);
    if (wire.unitId != expectedUnitId) {
      throw const FormatException('Reachable result belongs to another unit.');
    }
    final coordinates = <MapHexCoordinate>{};
    final tiles = <ReachableTileView>[];
    MapHexCoordinate? previous;
    for (final tile in wire.tiles) {
      final coordinate = _coordinate(tile.coordinate);
      if (!map.contains(coordinate) || !coordinates.add(coordinate)) {
        throw const FormatException(
          'Reachable result has invalid tile coverage.',
        );
      }
      if (previous != null && _rowMajorCompare(previous, coordinate) >= 0) {
        throw const FormatException('Reachable result order is unstable.');
      }
      tiles.add(
        ReachableTileView(
          coordinate: coordinate,
          costUnits: tile.costUnits,
          exhaustsMovement: tile.exhaustsMovement,
        ),
      );
      previous = coordinate;
    }
    return ReachableView(
      stamp: _stamp(wire.stamp),
      unitId: wire.unitId,
      availableMovementUnits: wire.availableMovementUnits,
      tiles: tiles,
    );
  }

  RoutePlanView routePlan(
    AonwRoutePlanResult wire, {
    required MapView map,
    required VisibleUnitView unit,
    required MapHexCoordinate expectedTarget,
    required int expectedRevision,
  }) {
    _validateStamp(wire.stamp, map: map, expectedRevision: expectedRevision);
    final target = _coordinate(wire.target);
    final destination = _coordinate(wire.destination);
    _validateRouteIdentity(
      wire,
      map: map,
      unit: unit,
      target: target,
      destination: destination,
      expectedTarget: expectedTarget,
    );
    final steps = _routeSteps(wire.steps, map);
    _validateRouteEndpoints(
      steps,
      origin: unit.coordinate,
      destination: destination,
      totalCostUnits: wire.totalCostUnits,
    );
    return RoutePlanView(
      stamp: _stamp(wire.stamp),
      unitId: wire.unitId,
      target: target,
      destination: destination,
      totalCostUnits: wire.totalCostUnits,
      availableMovementUnits: wire.availableMovementUnits,
      remainingMovementUnits: wire.remainingMovementUnits,
      steps: steps,
    );
  }

  static List<MovementStepView> _routeSteps(
    List<AonwMovementStep> wire,
    MapView map,
  ) {
    final steps = <MovementStepView>[];
    var previousCost = -1;
    for (final step in wire) {
      final coordinate = _coordinate(step.coordinate);
      if (!map.contains(coordinate) ||
          step.cumulativeCostUnits < previousCost) {
        throw const FormatException('Route result contains invalid steps.');
      }
      steps.add(
        MovementStepView(
          coordinate: coordinate,
          enterCostUnits: step.enterCostUnits,
          cumulativeCostUnits: step.cumulativeCostUnits,
        ),
      );
      previousCost = step.cumulativeCostUnits;
    }
    return steps;
  }

  static void _validateRouteIdentity(
    AonwRoutePlanResult wire, {
    required MapView map,
    required VisibleUnitView unit,
    required MapHexCoordinate target,
    required MapHexCoordinate destination,
    required MapHexCoordinate expectedTarget,
  }) {
    if (wire.unitId != unit.id || target != expectedTarget) {
      throw const FormatException('Route result belongs to another request.');
    }
    if (!map.contains(target) || !map.contains(destination)) {
      throw const FormatException('Route result is outside the map.');
    }
  }

  static void _validateRouteEndpoints(
    List<MovementStepView> steps, {
    required MapHexCoordinate origin,
    required MapHexCoordinate destination,
    required int totalCostUnits,
  }) {
    if (steps.isEmpty ||
        steps.first.coordinate != origin ||
        steps.first.enterCostUnits != 0 ||
        steps.first.cumulativeCostUnits != 0 ||
        steps.last.coordinate != destination ||
        steps.last.cumulativeCostUnits != totalCostUnits) {
      throw const FormatException('Route result endpoints are inconsistent.');
    }
  }

  MoveUnitExecutionView validateCommand(
    AonwCommandResult wire, {
    required MapView map,
    required String expectedUnitId,
    required int expectedRevision,
    required int currentRevision,
  }) {
    final nextRevision = wire.accepted ? expectedRevision + 1 : currentRevision;
    _validateStamp(wire.stamp, map: map, expectedRevision: nextRevision);
    if (!wire.accepted) {
      return _validateRejectedCommand(wire);
    }

    final events = _movementEvents(
      wire.events,
      map: map,
      expectedUnitId: expectedUnitId,
    );
    final evidence = _movementEvidence(
      wire.evidence,
      events: events,
      map: map,
      expectedUnitId: expectedUnitId,
    );
    return MoveUnitExecutionView(events: events, evidence: evidence);
  }

  static MoveUnitExecutionView _validateRejectedCommand(
    AonwCommandResult wire,
  ) {
    if (wire.rejection == null ||
        wire.events.isNotEmpty ||
        wire.evidence != null) {
      throw const FormatException(
        'Rejected move has inconsistent execution details.',
      );
    }
    return MoveUnitExecutionView(events: const [], evidence: null);
  }

  static List<UnitMovedEventView> _movementEvents(
    List<AonwClientEvent> wire, {
    required MapView map,
    required String expectedUnitId,
  }) {
    final events = <UnitMovedEventView>[];
    for (final event in wire) {
      if (event is! AonwUnitMovedEvent || event.unitId != expectedUnitId) {
        throw const FormatException(
          'Accepted move has inconsistent movement events.',
        );
      }
      final from = _coordinate(event.from);
      final to = _coordinate(event.to);
      if (!map.contains(from) || !map.contains(to)) {
        throw const FormatException('Movement event is outside the map.');
      }
      events.add(UnitMovedEventView(unitId: event.unitId, from: from, to: to));
    }
    return events;
  }

  static UnitMovementEvidenceView? _movementEvidence(
    AonwClientEvidence? evidence, {
    required List<UnitMovedEventView> events,
    required MapView map,
    required String expectedUnitId,
  }) {
    if (evidence != null) {
      if (evidence is! AonwUnitMovementEvidence ||
          evidence.unitId != expectedUnitId) {
        throw const FormatException(
          'Accepted move has inconsistent movement evidence.',
        );
      }
      final from = _coordinate(evidence.from);
      if (!map.contains(from)) {
        throw const FormatException('Movement evidence is outside the map.');
      }
      final steps = _routeSteps(evidence.steps, map);
      final mappedEvidence = UnitMovementEvidenceView(
        unitId: evidence.unitId,
        from: from,
        steps: steps,
      );
      if (events.isNotEmpty &&
          (events.first.from != from ||
              steps.isEmpty ||
              events.last.to != steps.last.coordinate)) {
        throw const FormatException(
          'Movement event and evidence endpoints differ.',
        );
      }
      return mappedEvidence;
    }
    return null;
  }

  CommandRejectionCodeView rejectionCode(AonwCommandRejectionCode value) =>
      _rejectionCodes[value]!;

  static MapHexCoordinate _coordinate(AonwCoordinate value) =>
      (col: value.col, row: value.row);

  static int _rowMajorCompare(MapHexCoordinate left, MapHexCoordinate right) {
    final row = left.row.compareTo(right.row);
    return row != 0 ? row : left.col.compareTo(right.col);
  }

  static void _validateStamp(
    AonwSessionStamp value, {
    required MapView map,
    required int expectedRevision,
  }) {
    final digest = RegExp(r'^[0-9a-f]{64}$');
    if (!digest.hasMatch(value.stateDigest) ||
        !digest.hasMatch(value.mapHash) ||
        !digest.hasMatch(value.rulesetHash) ||
        value.mapHash != map.contentHash ||
        value.revision != expectedRevision) {
      throw const FormatException('Session response identity is stale.');
    }
  }

  static SessionStampView _stamp(AonwSessionStamp value) => SessionStampView(
    revision: value.revision,
    stateDigest: value.stateDigest,
    mapHash: value.mapHash,
    rulesetHash: value.rulesetHash,
  );
}

const _rejectionCodes = <AonwCommandRejectionCode, CommandRejectionCodeView>{
  AonwCommandRejectionCode.staleRevision:
      CommandRejectionCodeView.staleRevision,
  AonwCommandRejectionCode.unitNotFound: CommandRejectionCodeView.unitNotFound,
  AonwCommandRejectionCode.unitNotControlled:
      CommandRejectionCodeView.unitNotControlled,
  AonwCommandRejectionCode.unitUnavailable:
      CommandRejectionCodeView.unitUnavailable,
  AonwCommandRejectionCode.unitUsesTradeRoutes:
      CommandRejectionCodeView.unitUsesTradeRoutes,
  AonwCommandRejectionCode.unitOutOfBounds:
      CommandRejectionCodeView.unitOutOfBounds,
  AonwCommandRejectionCode.moveTargetOutOfBounds:
      CommandRejectionCodeView.moveTargetOutOfBounds,
  AonwCommandRejectionCode.moveTargetIsCurrentTile:
      CommandRejectionCodeView.moveTargetIsCurrentTile,
  AonwCommandRejectionCode.moveTargetIsForeignCityCenter:
      CommandRejectionCodeView.moveTargetIsForeignCityCenter,
  AonwCommandRejectionCode.moveTargetOccupied:
      CommandRejectionCodeView.moveTargetOccupied,
  AonwCommandRejectionCode.unitMovementCapacityInsufficient:
      CommandRejectionCodeView.unitMovementCapacityInsufficient,
  AonwCommandRejectionCode.movePathNotFound:
      CommandRejectionCodeView.movePathNotFound,
  AonwCommandRejectionCode.unitBusy: CommandRejectionCodeView.unitBusy,
  AonwCommandRejectionCode.unitDefinitionMissing:
      CommandRejectionCodeView.unitDefinitionMissing,
  AonwCommandRejectionCode.stateRevisionOverflow:
      CommandRejectionCodeView.stateRevisionOverflow,
  AonwCommandRejectionCode.invalidQueuedMovementPath:
      CommandRejectionCodeView.invalidQueuedMovementPath,
  AonwCommandRejectionCode.invalidUnit: CommandRejectionCodeView.invalidUnit,
  AonwCommandRejectionCode.movementUnitUpdateFailed:
      CommandRejectionCodeView.movementUnitUpdateFailed,
};
