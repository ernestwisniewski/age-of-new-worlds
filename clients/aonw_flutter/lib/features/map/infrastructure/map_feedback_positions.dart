import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../read_model/map_view.dart';
import '../read_model/player_map_view.dart';

/// Follows disclosed coordinates in one command's authoritative event order.
final class MapFeedbackPositions {
  MapFeedbackPositions(PlayerMapView previous, AonwClientEvidence? evidence)
    : _units = {for (final unit in previous.units) unit.id: unit.coordinate},
      _combats = switch (evidence) {
        AonwCombatEvidence(:final execution) => [execution],
        AonwTurnKernelEvidence(:final combatExecutions) => combatExecutions,
        _ => const [],
      };

  final Map<String, MapHexCoordinate> _units;
  final List<AonwCombatExecution> _combats;
  int _nextCombat = 0;
  AonwCombatExecution? _combat;

  MapHexCoordinate? advance(AonwClientEvent event) {
    if (event.kind == AonwClientEventKind.combatResolved) {
      _combat = _nextCombat < _combats.length ? _combats[_nextCombat++] : null;
    }
    switch (event) {
      case AonwUnitMovedEvent(:final unitId, :final to):
        _units[unitId] = (col: to.col, row: to.row);
      case AonwUnitKilledEvent(:final subjectUnitId):
        return _units.remove(subjectUnitId);
      case AonwUnitRetreatedEvent():
        final coordinate = _retreat(event);
        if (coordinate != null) _units[event.subjectUnitId] = coordinate;
        return coordinate;
      default:
        break;
    }
    return null;
  }

  MapHexCoordinate? _retreat(AonwUnitRetreatedEvent event) {
    final combat = _combat;
    final target = combat?.preview.target;
    final eventTarget = event.target;
    final destination = combat?.outcome.defenderRetreat;
    if (combat == null ||
        target is! AonwUnitCombatTarget ||
        eventTarget is! AonwUnitCombatTarget ||
        destination == null ||
        combat.preview.attackerUnitId != event.attackerUnitId ||
        target.unitId != event.subjectUnitId ||
        target.unitId != eventTarget.unitId) {
      return null;
    }
    return (col: destination.col, row: destination.row);
  }
}
