import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../read_model/map_view.dart';
import 'recipient_economy_validator.dart';
import 'recipient_research_validator.dart';
import 'recipient_victory_validator.dart';

final class RecipientProjectionValidator {
  const RecipientProjectionValidator(this.map);

  final MapView map;

  void validateSnapshot(AonwPlayerViewSnapshot snapshot) {
    validateStamp(snapshot.stamp);
    if (snapshot.stamp.mapHash != map.contentHash || snapshot.turn < 1) {
      throw const FormatException('Recipient snapshot identity is invalid.');
    }
    final participantIds = _validateParticipants(snapshot.participants);
    _validateFog(snapshot.fog);
    validateOrderedIds(snapshot.units, (unit) => unit.id, 'unit');
    validateOrderedIds(snapshot.cities, (city) => city.id, 'city');
    validateOrderedIds(
      snapshot.artifacts,
      (artifact) => artifact.id,
      'artifact',
    );
    validateOrderedCoordinates(
      snapshot.fieldImprovements,
      (improvement) => improvement.coordinate,
      'field improvement',
    );
    validateOrderedCoordinates(
      snapshot.roads,
      (road) => road.coordinate,
      'road',
    );
    _validateUnits(snapshot.units, participantIds);
    _validateCities(snapshot.cities, participantIds);
    RecipientEconomyValidator(map).validate(snapshot.economy, snapshot.cities);
    const RecipientResearchValidator().validate(
      snapshot.research,
      snapshot.cities,
    );
    RecipientVictoryValidator(map).validate(
      snapshot.victory,
      turn: snapshot.turn,
      participantIds: participantIds,
    );
    for (final artifact in snapshot.artifacts) {
      _validateArtifact(artifact);
    }
    final draft = snapshot.cityFoundingDraft;
    if (draft != null) {
      if (draft.founderUnitId.isEmpty) {
        throw const FormatException('City founding draft has no founder.');
      }
      requireCoordinate(draft.center, 'city founding center');
      _validateCoordinateSet(
        draft.controlledHexes,
        'city founding controlled hex',
      );
    }
    _validatePendingAction(snapshot.pendingAction);
  }

  Set<String> _validateParticipants(
    List<AonwPlayerParticipantView> participants,
  ) {
    final ids = <String>{};
    for (final participant in participants) {
      if (participant.id.isEmpty ||
          participant.name.isEmpty ||
          !ids.add(participant.id)) {
        throw const FormatException('Recipient participant roster is invalid.');
      }
    }
    if (ids.isEmpty) {
      throw const FormatException('Recipient participant roster is empty.');
    }
    return ids;
  }

  void _validateFog(AonwPlayerFogView fog) {
    validateOrderedCoordinateValues(fog.discoveredHexes, 'discovered fog');
    validateOrderedCoordinateValues(fog.visibleHexes, 'visible fog');
    if (!fog.enabled &&
        (fog.discoveredHexes.isNotEmpty || fog.visibleHexes.isNotEmpty)) {
      throw const FormatException('Disabled recipient fog is not empty.');
    }
    final discovered = fog.discoveredHexes.map(coordinateKey).toSet();
    if (fog.visibleHexes.any(
      (coordinate) => !discovered.contains(coordinateKey(coordinate)),
    )) {
      throw const FormatException('Visible recipient fog is not discovered.');
    }
  }

  void _validateUnits(
    List<AonwPlayerUnitView> units,
    Set<String> participantIds,
  ) {
    for (final unit in units) {
      if (!participantIds.contains(unit.ownerPlayerId)) {
        throw const FormatException('Recipient unit owner is unknown.');
      }
      requireCoordinate(unit.coordinate, 'unit');
      final assignment = unit.workerAssignment;
      if (assignment != null) {
        requireCoordinate(assignment, 'worker assignment');
      }
      final job = unit.workerJob;
      if (job != null) requireCoordinate(job.target, 'worker job');
    }
  }

  void _validateCities(
    List<AonwPlayerCityView> cities,
    Set<String> participantIds,
  ) {
    for (final city in cities) {
      if (!participantIds.contains(city.ownerPlayerId)) {
        throw const FormatException('Recipient city owner is unknown.');
      }
      _validateCity(city);
    }
  }

  void validateStamp(AonwSessionStamp stamp) {
    final digest = RegExp(r'^[0-9a-f]{64}$');
    if (!digest.hasMatch(stamp.stateDigest) ||
        !digest.hasMatch(stamp.mapHash) ||
        !digest.hasMatch(stamp.rulesetHash)) {
      throw const FormatException('Recipient session stamp is malformed.');
    }
  }

  bool hasSameStaticIdentity(AonwSessionStamp left, AonwSessionStamp right) =>
      left.mapHash == right.mapHash && left.rulesetHash == right.rulesetHash;

  void validateOrderedIds<T>(
    List<T> values,
    String Function(T value) idOf,
    String label,
  ) {
    String? previous;
    for (final value in values) {
      final id = idOf(value);
      if (id.isEmpty || (previous != null && previous.compareTo(id) >= 0)) {
        throw FormatException('Recipient $label identifiers are not ordered.');
      }
      previous = id;
    }
  }

  void validateOrderedStrings(List<String> values, String label) {
    String? previous;
    for (final value in values) {
      if (value.isEmpty ||
          (previous != null && previous.compareTo(value) >= 0)) {
        throw FormatException('Recipient $label values are not ordered.');
      }
      previous = value;
    }
  }

  void validateOrderedCoordinates<T>(
    List<T> values,
    AonwCoordinate Function(T value) coordinateOf,
    String label,
  ) => validateOrderedCoordinateValues(
    values.map(coordinateOf).toList(growable: false),
    label,
  );

  void validateOrderedCoordinateValues(
    List<AonwCoordinate> values,
    String label,
  ) {
    CoordinateKey? previous;
    for (final value in values) {
      requireCoordinate(value, label);
      final key = coordinateKey(value);
      if (previous != null && compareCoordinates(previous, key) >= 0) {
        throw FormatException('Recipient $label coordinates are not ordered.');
      }
      previous = key;
    }
  }

  void requireCoordinate(AonwCoordinate coordinate, String label) {
    if (!map.isWithinBounds((col: coordinate.col, row: coordinate.row))) {
      throw FormatException('Recipient $label is outside the map.');
    }
  }

  void _validateCity(AonwPlayerCityView city) {
    if (city.ownerPlayerId.isEmpty || city.name.isEmpty) {
      throw const FormatException('Recipient city identity is empty.');
    }
    requireCoordinate(city.center, 'city center');
    _validateCoordinateSet(city.visibleControlledHexes, 'controlled city hex');
    final planning = city.ownedDetails;
    if (planning == null) return;
    _validateCoordinateSet(planning.workedHexes, 'worked city hex');
    final preferred = planning.preferredExpansionHex;
    if (preferred != null) {
      requireCoordinate(preferred, 'preferred city expansion hex');
    }
  }

  void _validateArtifact(AonwPlayerArtifactView artifact) {
    switch (artifact.location) {
      case AonwMapArtifactLocation(:final coordinate):
        requireCoordinate(coordinate, 'map artifact');
      case AonwExcavationArtifactLocation(:final coordinate):
        requireCoordinate(coordinate, 'artifact excavation');
      case AonwCarriedArtifactLocation(:final unitId):
        if (unitId.isEmpty) {
          throw const FormatException('Artifact carrier id is empty.');
        }
      case AonwStoredArtifactLocation(:final cityId):
        if (cityId.isEmpty) {
          throw const FormatException('Artifact storage city id is empty.');
        }
    }
  }

  void _validatePendingAction(AonwPendingActionView? action) {
    switch (action) {
      case null || AonwPendingResearchSelection():
        return;
      case AonwPendingAttackTargeting(:final unitId, :final defender):
        if (unitId.isEmpty) {
          throw const FormatException('Pending action unit id is empty.');
        }
        if (defender != null) {
          requireCoordinate(defender, 'pending attack defender');
        }
      case AonwPendingCityActionView(:final cityId):
        if (cityId.isEmpty) {
          throw const FormatException('Pending action city id is empty.');
        }
      case AonwPendingUnitActionView(:final unitId):
        if (unitId.isEmpty) {
          throw const FormatException('Pending action unit id is empty.');
        }
    }
  }

  void _validateCoordinateSet(List<AonwCoordinate> values, String label) {
    final seen = <CoordinateKey>{};
    for (final coordinate in values) {
      requireCoordinate(coordinate, label);
      if (!seen.add(coordinateKey(coordinate))) {
        throw FormatException('Recipient snapshot duplicates $label.');
      }
    }
  }
}

typedef CoordinateKey = ({int col, int row});

CoordinateKey coordinateKey(AonwCoordinate value) =>
    (col: value.col, row: value.row);

int compareCoordinates(CoordinateKey left, CoordinateKey right) {
  final col = left.col.compareTo(right.col);
  return col != 0 ? col : left.row.compareTo(right.row);
}
