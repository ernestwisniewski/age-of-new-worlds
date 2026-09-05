import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../read_model/map_view.dart';
import '../read_model/player_map_view.dart';
import 'map_combat_evidence_index.dart';

/// Follows disclosed coordinates in one command's authoritative event order.
final class MapFeedbackPositions {
  MapFeedbackPositions(
    PlayerMapView previous,
    AonwClientEvidence? evidence,
    List<AonwClientEvent> events,
  ) : _units = {for (final unit in previous.units) unit.id: unit.coordinate},
      _combats = MapCombatEvidenceIndex(evidence, events);

  final Map<String, MapHexCoordinate> _units;
  final MapCombatEvidenceIndex _combats;
  AonwCombatExecution? _combat;

  AonwCombatExecution? get combat => _combat;

  MapHexCoordinate? coordinateOf(String unitId) => _units[unitId];

  MapHexCoordinate? advance(AonwClientEvent event) {
    if (event.kind == AonwClientEventKind.combatResolved) {
      _combat = event is AonwCombatResolvedEvent ? _combats.take(event) : null;
    }
    switch (event) {
      case AonwUnitMovedEvent(:final unitId, :final to):
        _units[unitId] = (col: to.col, row: to.row);
      case AonwUnitKilledEvent(:final subjectUnitId):
        return _units.remove(subjectUnitId);
      case AonwUnitRetreatedEvent():
        final coordinate = _retreat(event);
        if (coordinate == null) {
          _units.remove(event.subjectUnitId);
        } else {
          _units[event.subjectUnitId] = coordinate;
        }
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
