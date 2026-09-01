import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../../artifacts/read_model/artifact_view.dart';
import '../../cities/read_model/city_view.dart';
import '../../diplomacy/infrastructure/diplomacy_view_mapper.dart';
import '../../turns/read_model/recipient_turn_view.dart';
import '../../workers/infrastructure/worker_view_mapper.dart';
import '../read_model/map_view.dart';
import '../read_model/pending_action_view.dart';
import '../read_model/player_map_view.dart';
import 'pending_action_view_mapper.dart';
import 'player_economy_view_mapper.dart';
import 'player_victory_view_mapper.dart';
import 'recipient_projection_validator.dart';

final class PlayerMapViewMapper {
  const PlayerMapViewMapper({
    PendingActionViewMapper pendingActionMapper =
        const PendingActionViewMapper(),
    WorkerViewMapper workerMapper = const WorkerViewMapper(),
    DiplomacyViewMapper diplomacyMapper = const DiplomacyViewMapper(),
  }) : _pendingActionMapper = pendingActionMapper,
       _workerMapper = workerMapper,
       _diplomacyMapper = diplomacyMapper;

  final PendingActionViewMapper _pendingActionMapper;
  final WorkerViewMapper _workerMapper;
  final DiplomacyViewMapper _diplomacyMapper;

  PlayerMapView fromWire(
    AonwPlayerViewSnapshot wire, {
    required MapView map,
    required String actorPlayerId,
  }) {
    RecipientProjectionValidator(map).validateSnapshot(wire);
    _validateActor(wire.participants, actorPlayerId);
    final units = _mapUnits(wire.units, map);
    final cities = [for (final city in wire.cities) _mapCity(city)];
    final artifacts = [
      for (final artifact in wire.artifacts) _mapArtifact(artifact),
    ];
    _validateArtifactReferences(
      artifacts,
      units: units,
      cities: cities,
      actorPlayerId: actorPlayerId,
    );
    final pendingAction = _pendingActionMapper.fromWire(
      wire.pendingAction,
      actorPlayerId: actorPlayerId,
      units: units,
      map: map,
    );
    return PlayerMapView(
      actorPlayerId: actorPlayerId,
      stamp: _mapStamp(wire.stamp),
      turnMode: MatchTurnModeView.values.byName(wire.turnMode.name),
      participants: _mapParticipants(wire.participants),
      fog: _mapFog(wire.fog),
      economy: mapPlayerEconomyView(wire.economy),
      research: _mapResearch(wire.research),
      victory: mapPlayerVictoryView(wire.victory),
      turnView: _mapTurnView(wire, pendingAction),
      diplomacy: _diplomacyMapper.fromWire(
        wire.diplomacy,
        actorPlayerId: actorPlayerId,
      ),
      units: units,
      cities: cities,
      artifacts: artifacts,
      fieldImprovements: [
        for (final improvement in wire.fieldImprovements)
          _workerMapper.fieldImprovement(improvement, map),
      ],
      roads: [for (final road in wire.roads) _workerMapper.road(road, map)],
      cityFoundingDraft: wire.cityFoundingDraft == null
          ? null
          : _mapCityFoundingDraft(wire.cityFoundingDraft!),
    );
  }

  List<VisibleUnitView> _mapUnits(
    List<AonwPlayerUnitView> source,
    MapView map,
  ) {
    final units = <VisibleUnitView>[];
    String? previousId;
    for (final unit in source) {
      _validateUnit(unit, previousId: previousId, map: map);
      units.add(_mapUnit(unit, map));
      previousId = unit.id;
    }
    return units;
  }

  static void _validateUnit(
    AonwPlayerUnitView unit, {
    required String? previousId,
    required MapView map,
  }) {
    if (unit.id.isEmpty || unit.ownerPlayerId.isEmpty || unit.name.isEmpty) {
      throw const FormatException(
        'Session snapshot contains an empty unit field.',
      );
    }
    if (previousId != null && previousId.compareTo(unit.id) >= 0) {
      throw const FormatException(
        'Session snapshot unit identifiers are not unique and ordered.',
      );
    }
    if (!map.contains(_coordinate(unit))) {
      throw const FormatException('Session snapshot unit is outside the map.');
    }
  }

  VisibleUnitView _mapUnit(AonwPlayerUnitView unit, MapView map) =>
      VisibleUnitView(
        id: unit.id,
        ownerPlayerId: unit.ownerPlayerId,
        kind: _kind(unit.kind),
        name: unit.name,
        coordinate: _coordinate(unit),
        movementUnits: unit.movementUnits,
        posture: _posture(unit.posture),
        hitPoints: unit.hitPoints,
        maximumHitPoints: unit.maximumHitPoints,
        threatenedHexes: [
          for (final coordinate in unit.threatenedHexes)
            (col: coordinate.col, row: coordinate.row),
        ],
        army: [
          for (final troop
              in unit.ownedDetails?.army ?? const <AonwArmyTroop>[])
            VisibleArmyTroopView(kind: troop.kind.name, count: troop.count),
        ],
        queuedTarget: unit.ownedDetails?.queuedPath == null
            ? null
            : (
                col: unit.ownedDetails!.queuedPath!.target.col,
                row: unit.ownedDetails!.queuedPath!.target.row,
              ),
        merchantRouteDestinationCityId:
            unit.ownedDetails?.merchantTradeRoute?.destinationCityId,
        workerBuildCharges: unit.workerBuildCharges,
        workerJob: _workerMapper.job(unit.workerJob, map),
        workerAssignment: unit.workerAssignment == null
            ? null
            : _ownedCoordinate(unit.workerAssignment!, map),
        cityFoundingRemainingTurns:
            unit.ownedDetails?.cityFoundingJob?.remainingTurns,
        carriedArtifactId: unit.carriedArtifactId,
        excavatingArtifactId: unit.ownedDetails?.excavatingArtifactId,
      );

  static CityView _mapCity(AonwPlayerCityView city) => CityView(
    id: city.id,
    ownerPlayerId: city.ownerPlayerId,
    name: city.name,
    center: _cityCoordinate(city.center),
    visibleControlledHexes: [
      for (final coordinate in city.visibleControlledHexes)
        _cityCoordinate(coordinate),
    ],
    hitPoints: city.hitPoints,
    ownedDetails: city.ownedDetails == null
        ? null
        : OwnedCityDetailsView(
            population: city.ownedDetails!.population,
            storedFood: city.ownedDetails!.storedFood,
            maxHexes: city.ownedDetails!.maxHexes,
            territoryRadius: city.ownedDetails!.territoryRadius,
            workedHexes: [
              for (final coordinate in city.ownedDetails!.workedHexes)
                _cityCoordinate(coordinate),
            ],
            preferredExpansionHex:
                city.ownedDetails!.preferredExpansionHex == null
                ? null
                : _cityCoordinate(city.ownedDetails!.preferredExpansionHex!),
            buildings: [
              for (final building in city.ownedDetails!.buildings)
                building.name,
            ],
            wonders: [
              for (final wonder in city.ownedDetails!.wonders) wonder.name,
            ],
            productionQueue: city.ownedDetails!.productionQueue == null
                ? null
                : _mapProductionQueue(city.ownedDetails!.productionQueue!),
            productionOverflow: city.ownedDetails!.productionOverflow,
            specialization: city.ownedDetails!.specialization?.name,
          ),
  );

  static CityProductionQueueView _mapProductionQueue(
    AonwCityProductionQueue value,
  ) => CityProductionQueueView(
    targetKind: value.target.kind.name,
    target: switch (value.target.kind) {
      AonwCityProductionTargetKind.building => value.target.buildingType!.name,
      AonwCityProductionTargetKind.unit => value.target.unitType!.name,
      AonwCityProductionTargetKind.project => value.target.projectType!.name,
      AonwCityProductionTargetKind.wonder => value.target.wonderType!.name,
    },
    investedProduction: value.investedProduction,
    resourceAllocation: {
      for (final entry in value.resourceAllocation.entries)
        MapResource.values.byName(entry.key.name): entry.value,
    },
  );

  static WorldArtifactView _mapArtifact(AonwPlayerArtifactView value) =>
      WorldArtifactView(
        id: value.id,
        kind: WorldArtifactKindView.values.byName(value.type.name),
        location: switch (value.location) {
          AonwMapArtifactLocation(:final coordinate) => MapArtifactLocationView(
            _cityCoordinate(coordinate),
          ),
          AonwCarriedArtifactLocation(:final unitId) =>
            CarriedArtifactLocationView(unitId),
          AonwStoredArtifactLocation(:final cityId) =>
            StoredArtifactLocationView(cityId),
          AonwExcavationArtifactLocation(
            :final unitId,
            :final coordinate,
            :final remainingTurns,
          ) =>
            remainingTurns < 1
                ? throw const FormatException(
                    'Artifact excavation duration is not positive.',
                  )
                : ExcavationArtifactLocationView(
                    unitId: unitId,
                    coordinate: _cityCoordinate(coordinate),
                    remainingTurns: remainingTurns,
                  ),
        },
      );

  static void _validateArtifactReferences(
    List<WorldArtifactView> artifacts, {
    required List<VisibleUnitView> units,
    required List<CityView> cities,
    required String actorPlayerId,
  }) {
    final unitsById = {for (final unit in units) unit.id: unit};
    final citiesById = {for (final city in cities) city.id: city};
    final artifactsById = {
      for (final artifact in artifacts) artifact.id: artifact,
    };
    for (final artifact in artifacts) {
      switch (artifact.location) {
        case MapArtifactLocationView():
          break;
        case CarriedArtifactLocationView(:final unitId):
          final unit = unitsById[unitId];
          if (unit == null || unit.carriedArtifactId != artifact.id) {
            throw const FormatException('Artifact carrier is inconsistent.');
          }
        case StoredArtifactLocationView(:final cityId):
          if (!citiesById.containsKey(cityId)) {
            throw const FormatException('Artifact storage city is absent.');
          }
        case ExcavationArtifactLocationView(:final unitId, :final coordinate):
          final unit = unitsById[unitId];
          if (unit == null || unit.coordinate != coordinate) {
            throw const FormatException('Artifact excavation is inconsistent.');
          }
          if (unit.ownerPlayerId == actorPlayerId &&
              unit.excavatingArtifactId != artifact.id) {
            throw const FormatException(
              'Controlled artifact excavation is inconsistent.',
            );
          }
      }
    }
    for (final unit in units) {
      final carried = unit.carriedArtifactId;
      if (carried != null) {
        final location = artifactsById[carried]?.location;
        if (location is! CarriedArtifactLocationView ||
            location.unitId != unit.id) {
          throw const FormatException(
            'Unit artifact reference is inconsistent.',
          );
        }
      }
      final excavation = unit.excavatingArtifactId;
      if (excavation != null) {
        final location = artifactsById[excavation]?.location;
        if (location is! ExcavationArtifactLocationView ||
            location.unitId != unit.id) {
          throw const FormatException(
            'Unit excavation reference is inconsistent.',
          );
        }
      }
    }
  }

  static CityFoundingDraftView _mapCityFoundingDraft(
    AonwCityFoundingDraft draft,
  ) => CityFoundingDraftView(
    founderUnitId: draft.founderUnitId,
    center: _cityCoordinate(draft.center),
    controlledHexes: [
      for (final coordinate in draft.controlledHexes)
        _cityCoordinate(coordinate),
    ],
  );

  static SessionStampView _mapStamp(AonwSessionStamp stamp) => SessionStampView(
    revision: stamp.revision,
    stateDigest: stamp.stateDigest,
    mapHash: stamp.mapHash,
    rulesetHash: stamp.rulesetHash,
  );

  static ({int col, int row}) _coordinate(AonwPlayerUnitView unit) =>
      (col: unit.coordinate.col, row: unit.coordinate.row);

  static MapHexCoordinate _cityCoordinate(AonwCoordinate coordinate) =>
      (col: coordinate.col, row: coordinate.row);

  static MapHexCoordinate _ownedCoordinate(
    AonwCoordinate coordinate,
    MapView map,
  ) {
    final value = _cityCoordinate(coordinate);
    if (!map.contains(value)) {
      throw const FormatException('Owned unit coordinate is outside the map.');
    }
    return value;
  }

  static VisibleUnitKind _kind(AonwUnitKind value) =>
      VisibleUnitKind.values.byName(value.name);

  static VisibleUnitPosture _posture(AonwUnitPosture value) =>
      VisibleUnitPosture.values.byName(value.name);
}

void _validateActor(
  List<AonwPlayerParticipantView> participants,
  String actorPlayerId,
) {
  if (actorPlayerId.isEmpty) {
    throw const FormatException('Session actor player id is empty.');
  }
  if (!participants.any((participant) => participant.id == actorPlayerId)) {
    throw const FormatException('Session actor is not a match participant.');
  }
}

List<MatchParticipantView> _mapParticipants(
  List<AonwPlayerParticipantView> participants,
) => [
  for (final participant in participants)
    MatchParticipantView(
      id: participant.id,
      name: participant.name,
      colorValue: participant.colorValue,
      country: MatchParticipantCountryView.values.byName(
        participant.country.name,
      ),
      kind: MatchParticipantKindView.values.byName(participant.kind.name),
    ),
];

MapFogView _mapFog(AonwPlayerFogView fog) => MapFogView(
  enabled: fog.enabled,
  discoveredHexes: [
    for (final coordinate in fog.discoveredHexes)
      (col: coordinate.col, row: coordinate.row),
  ],
  visibleHexes: [
    for (final coordinate in fog.visibleHexes)
      (col: coordinate.col, row: coordinate.row),
  ],
);

PlayerResearchSummaryView _mapResearch(AonwPlayerResearchView research) =>
    PlayerResearchSummaryView(
      activeTechnologyId: research.activeTechnology?.name,
      activeProgress: research.activeProgress,
      activeEffectiveCost: research.activeEffectiveCost,
      scienceOverflow: research.scienceOverflow,
      sciencePerTurn: research.scienceYield.total,
      scienceByCityId: research.scienceYield.byCityId,
      scienceSources: [
        for (final source in research.scienceYield.sources)
          PlayerScienceYieldSourceView(
            cityId: source.cityId,
            amount: source.amount,
            kind: PlayerScienceYieldSourceKindView.values.byName(
              source.kind.name,
            ),
          ),
      ],
    );

RecipientTurnView _mapTurnView(
  AonwPlayerViewSnapshot wire,
  PendingActionView? pendingAction,
) => RecipientTurnView(
  number: wire.turn,
  ownState: switch (wire.turnLifecycle.ownState) {
    AonwPlayerTurnState.active => RecipientTurnStateView.active,
    AonwPlayerTurnState.finished => RecipientTurnStateView.finished,
    null => null,
  },
  ownSubmitted: wire.turnLifecycle.ownSubmitted,
  requiredSubmissionCount: wire.turnLifecycle.requiredSubmissionCount,
  submittedCount: wire.turnLifecycle.submittedCount,
  pendingAction: pendingAction,
  outcome: GameOutcomeView(
    condition: GameOutcomeConditionView.values.byName(
      wire.outcome.condition.name,
    ),
    winnerPlayerId: wire.outcome.winnerPlayerId,
    scoreByPlayerId: wire.outcome.scoreByPlayerId,
  ),
);
