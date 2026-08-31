import '../../artifacts/read_model/artifact_view.dart';
import '../../cities/read_model/city_view.dart';
import '../../diplomacy/read_model/diplomacy_view.dart';
import '../../turns/read_model/recipient_turn_view.dart';
import '../../workers/read_model/worker_view.dart';
import 'map_view.dart';
import 'pending_action_view.dart';

enum VisibleUnitKind {
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
  reconPlane,
}

enum VisibleUnitPosture { active, fortified, autoExploring, autoWorking }

final class SessionStampView {
  const SessionStampView({
    required this.revision,
    required this.stateDigest,
    required this.mapHash,
    required this.rulesetHash,
  });

  final int revision;
  final String stateDigest;
  final String mapHash;
  final String rulesetHash;
}

final class VisibleUnitView {
  VisibleUnitView({
    required this.id,
    required this.ownerPlayerId,
    required this.kind,
    required this.name,
    required this.coordinate,
    required this.movementUnits,
    required this.posture,
    List<VisibleArmyTroopView> army = const [],
    this.queuedTarget,
    this.merchantRouteDestinationCityId,
    this.workerBuildCharges = 0,
    this.workerJob,
    this.workerAssignment,
    this.carriedArtifactId,
    this.excavatingArtifactId,
  }) : army = List.unmodifiable(army);

  final String id;
  final String ownerPlayerId;
  final VisibleUnitKind kind;
  final String name;
  final MapHexCoordinate coordinate;
  final int movementUnits;
  final VisibleUnitPosture posture;
  final List<VisibleArmyTroopView> army;
  final MapHexCoordinate? queuedTarget;
  final String? merchantRouteDestinationCityId;
  final int workerBuildCharges;
  final WorkerJobView? workerJob;
  final MapHexCoordinate? workerAssignment;
  final String? carriedArtifactId;
  final String? excavatingArtifactId;
}

final class VisibleArmyTroopView {
  const VisibleArmyTroopView({required this.kind, required this.count});

  final String kind;
  final int count;
}

final class PlayerMapView {
  PlayerMapView({
    required this.actorPlayerId,
    required this.stamp,
    required this.turnView,
    required this.diplomacy,
    required List<VisibleUnitView> units,
    List<CityView> cities = const [],
    List<WorldArtifactView> artifacts = const [],
    List<FieldImprovementView> fieldImprovements = const [],
    List<RoadView> roads = const [],
    this.cityFoundingDraft,
  }) : units = List.unmodifiable(units),
       cities = List.unmodifiable(cities),
       artifacts = List.unmodifiable(artifacts),
       fieldImprovements = List.unmodifiable(fieldImprovements),
       roads = List.unmodifiable(roads) {
    final byCoordinate = <MapHexCoordinate, List<VisibleUnitView>>{};
    final controlledById = <String, VisibleUnitView>{};
    for (final unit in units) {
      (byCoordinate[unit.coordinate] ??= []).add(unit);
      if (unit.ownerPlayerId == actorPlayerId) controlledById[unit.id] = unit;
    }
    _unitsByCoordinate = Map.unmodifiable({
      for (final entry in byCoordinate.entries)
        entry.key: List<VisibleUnitView>.unmodifiable(entry.value),
    });
    _controlledUnitsById = Map.unmodifiable(controlledById);
    _citiesByCoordinate = Map.unmodifiable({
      for (final city in cities) city.center: city,
    });
    _citiesById = Map.unmodifiable({for (final city in cities) city.id: city});
    _controlledCitiesById = Map.unmodifiable({
      for (final city in cities)
        if (city.ownerPlayerId == actorPlayerId) city.id: city,
    });
    final unitsById = {for (final unit in units) unit.id: unit};
    final citiesById = {for (final city in cities) city.id: city};
    _artifactsById = Map.unmodifiable({
      for (final artifact in artifacts) artifact.id: artifact,
    });
    final artifactsByCoordinate = <MapHexCoordinate, List<WorldArtifactView>>{};
    for (final artifact in artifacts) {
      final coordinate = switch (artifact.location) {
        MapArtifactLocationView(:final coordinate) => coordinate,
        ExcavationArtifactLocationView(:final coordinate) => coordinate,
        CarriedArtifactLocationView(:final unitId) =>
          unitsById[unitId]?.coordinate,
        StoredArtifactLocationView(:final cityId) => citiesById[cityId]?.center,
      };
      if (coordinate != null) {
        (artifactsByCoordinate[coordinate] ??= []).add(artifact);
      }
    }
    _artifactsByCoordinate = Map.unmodifiable({
      for (final entry in artifactsByCoordinate.entries)
        entry.key: List<WorldArtifactView>.unmodifiable(entry.value),
    });
    _fieldImprovementsByCoordinate = Map.unmodifiable({
      for (final improvement in fieldImprovements)
        improvement.coordinate: improvement,
    });
    _roadsByCoordinate = Map.unmodifiable({
      for (final road in roads) road.coordinate: road,
    });
  }

  factory PlayerMapView.preview({
    required String actorPlayerId,
    required SessionStampView stamp,
    required int turn,
    required PendingActionView? pendingAction,
    required List<VisibleUnitView> units,
    GameOutcomeView? outcome,
    DiplomacyView diplomacy = const DiplomacyView.empty(),
    List<CityView> cities = const [],
    List<WorldArtifactView> artifacts = const [],
    List<FieldImprovementView> fieldImprovements = const [],
    List<RoadView> roads = const [],
    CityFoundingDraftView? cityFoundingDraft,
  }) => PlayerMapView(
    actorPlayerId: actorPlayerId,
    stamp: stamp,
    turnView: RecipientTurnView(
      number: turn,
      ownState: RecipientTurnStateView.active,
      ownSubmitted: false,
      requiredSubmissionCount: 1,
      submittedCount: 0,
      pendingAction: pendingAction,
      outcome:
          outcome ??
          GameOutcomeView(
            condition: GameOutcomeConditionView.ongoing,
            winnerPlayerId: null,
            scoreByPlayerId: const {},
          ),
    ),
    diplomacy: diplomacy,
    units: units,
    cities: cities,
    artifacts: artifacts,
    fieldImprovements: fieldImprovements,
    roads: roads,
    cityFoundingDraft: cityFoundingDraft,
  );

  final String actorPlayerId;
  final SessionStampView stamp;
  final RecipientTurnView turnView;
  final DiplomacyView diplomacy;
  final List<VisibleUnitView> units;
  final List<CityView> cities;
  final List<WorldArtifactView> artifacts;
  final List<FieldImprovementView> fieldImprovements;
  final List<RoadView> roads;
  final CityFoundingDraftView? cityFoundingDraft;
  late final Map<MapHexCoordinate, List<VisibleUnitView>> _unitsByCoordinate;
  late final Map<String, VisibleUnitView> _controlledUnitsById;
  late final Map<MapHexCoordinate, CityView> _citiesByCoordinate;
  late final Map<String, CityView> _citiesById;
  late final Map<String, CityView> _controlledCitiesById;
  late final Map<String, WorldArtifactView> _artifactsById;
  late final Map<MapHexCoordinate, List<WorldArtifactView>>
  _artifactsByCoordinate;
  late final Map<MapHexCoordinate, FieldImprovementView>
  _fieldImprovementsByCoordinate;
  late final Map<MapHexCoordinate, RoadView> _roadsByCoordinate;

  int get turn => turnView.number;

  PendingActionView? get pendingAction => turnView.pendingAction;

  List<String> get diplomaticCounterpartPlayerIds => List.unmodifiable(
    diplomacy.relations.map((relation) => relation.counterpartPlayerId),
  );

  Iterable<VisibleUnitView> unitsAt(MapHexCoordinate coordinate) =>
      _unitsByCoordinate[coordinate] ?? const <VisibleUnitView>[];

  VisibleUnitView? controlledUnitAt(MapHexCoordinate coordinate) {
    for (final unit in unitsAt(coordinate)) {
      if (unit.ownerPlayerId == actorPlayerId) return unit;
    }
    return null;
  }

  VisibleUnitView? controlledUnitById(String unitId) =>
      _controlledUnitsById[unitId];

  CityView? cityAt(MapHexCoordinate coordinate) =>
      _citiesByCoordinate[coordinate];

  CityView? cityById(String cityId) => _citiesById[cityId];

  CityView? controlledCityById(String cityId) => _controlledCitiesById[cityId];

  WorldArtifactView? artifactById(String artifactId) =>
      _artifactsById[artifactId];

  Iterable<WorldArtifactView> artifactsAt(MapHexCoordinate coordinate) =>
      _artifactsByCoordinate[coordinate] ?? const <WorldArtifactView>[];

  FieldImprovementView? fieldImprovementAt(MapHexCoordinate coordinate) =>
      _fieldImprovementsByCoordinate[coordinate];

  RoadView? roadAt(MapHexCoordinate coordinate) =>
      _roadsByCoordinate[coordinate];
}
