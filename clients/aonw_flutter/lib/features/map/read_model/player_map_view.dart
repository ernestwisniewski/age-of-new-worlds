import '../../artifacts/read_model/artifact_view.dart';
import '../../cities/read_model/city_view.dart';
import '../../diplomacy/read_model/diplomacy_view.dart';
import '../../turns/read_model/recipient_turn_view.dart';
import '../../workers/read_model/worker_view.dart';
import 'map_view.dart';
import 'pending_action_view.dart';
import 'player_economy_view.dart';
import 'player_victory_view.dart';

export 'player_economy_view.dart';

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

enum MatchTurnModeView { sequential, simultaneous }

enum MapFogVisibilityView { hidden, discovered, visible }

final class MapFogView {
  MapFogView({
    required this.enabled,
    required List<MapHexCoordinate> discoveredHexes,
    required List<MapHexCoordinate> visibleHexes,
  }) : discoveredHexes = List.unmodifiable(discoveredHexes),
       visibleHexes = List.unmodifiable(visibleHexes),
       _discoveredHexes = Set.unmodifiable(discoveredHexes),
       _visibleHexes = Set.unmodifiable(visibleHexes);

  factory MapFogView.disabled() => MapFogView(
    enabled: false,
    discoveredHexes: const [],
    visibleHexes: const [],
  );

  final bool enabled;
  final List<MapHexCoordinate> discoveredHexes;
  final List<MapHexCoordinate> visibleHexes;
  final Set<MapHexCoordinate> _discoveredHexes;
  final Set<MapHexCoordinate> _visibleHexes;

  MapFogVisibilityView visibilityAt(MapHexCoordinate coordinate) {
    if (!enabled || _visibleHexes.contains(coordinate)) {
      return MapFogVisibilityView.visible;
    }
    return _discoveredHexes.contains(coordinate)
        ? MapFogVisibilityView.discovered
        : MapFogVisibilityView.hidden;
  }
}

enum PlayerScienceYieldSourceKindView {
  cityScience,
  cityResearchProject,
  worldArtifact,
  worldWonder,
}

final class PlayerScienceYieldSourceView {
  const PlayerScienceYieldSourceView({
    required this.cityId,
    required this.amount,
    required this.kind,
  });

  final String cityId;
  final int amount;
  final PlayerScienceYieldSourceKindView kind;
}

final class PlayerResearchSummaryView {
  PlayerResearchSummaryView({
    required this.activeTechnologyId,
    required this.activeProgress,
    required this.activeEffectiveCost,
    required this.scienceOverflow,
    required this.sciencePerTurn,
    required Map<String, int> scienceByCityId,
    required List<PlayerScienceYieldSourceView> scienceSources,
  }) : scienceByCityId = Map.unmodifiable(scienceByCityId),
       scienceSources = List.unmodifiable(scienceSources);

  factory PlayerResearchSummaryView.empty() => PlayerResearchSummaryView(
    activeTechnologyId: null,
    activeProgress: null,
    activeEffectiveCost: null,
    scienceOverflow: 0,
    sciencePerTurn: 0,
    scienceByCityId: const {},
    scienceSources: const [],
  );

  final String? activeTechnologyId;
  final int? activeProgress;
  final int? activeEffectiveCost;
  final int scienceOverflow;
  final int sciencePerTurn;
  final Map<String, int> scienceByCityId;
  final List<PlayerScienceYieldSourceView> scienceSources;
}

enum MatchParticipantKindView { human, ai }

enum MatchParticipantCountryView {
  poland,
  ukraine,
  germany,
  france,
  unitedKingdom,
  italy,
  spain,
  netherlands,
  sweden,
  russia,
  unitedStates,
  canada,
  china,
  korea,
  japan,
  portugal,
  india,
  brazil,
  indonesia,
  mexico,
  turkey,
  saudiArabia,
  egypt,
  greece,
}

final class MatchParticipantView {
  const MatchParticipantView({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.country,
    required this.kind,
  });

  final String id;
  final String name;
  final int colorValue;
  final MatchParticipantCountryView country;
  final MatchParticipantKindView kind;
}

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
    this.hitPoints,
    this.maximumHitPoints,
    List<VisibleArmyTroopView> army = const [],
    this.queuedTarget,
    this.merchantRouteDestinationCityId,
    this.workerBuildCharges = 0,
    this.workerJob,
    this.workerAssignment,
    this.cityFoundingRemainingTurns,
    this.carriedArtifactId,
    this.excavatingArtifactId,
    List<MapHexCoordinate> threatenedHexes = const [],
  }) : army = List.unmodifiable(army),
       threatenedHexes = List.unmodifiable(threatenedHexes);

  final String id;
  final String ownerPlayerId;
  final VisibleUnitKind kind;
  final String name;
  final MapHexCoordinate coordinate;
  final int movementUnits;
  final VisibleUnitPosture posture;
  final int? hitPoints;
  final int? maximumHitPoints;
  final List<VisibleArmyTroopView> army;
  final MapHexCoordinate? queuedTarget;
  final String? merchantRouteDestinationCityId;
  final int workerBuildCharges;
  final WorkerJobView? workerJob;
  final MapHexCoordinate? workerAssignment;
  final int? cityFoundingRemainingTurns;
  final String? carriedArtifactId;
  final String? excavatingArtifactId;
  final List<MapHexCoordinate> threatenedHexes;
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
    required this.turnMode,
    required List<MatchParticipantView> participants,
    required this.fog,
    required this.economy,
    required this.research,
    required this.victory,
    required this.turnView,
    required this.diplomacy,
    required List<VisibleUnitView> units,
    List<CityView> cities = const [],
    List<WorldArtifactView> artifacts = const [],
    List<FieldImprovementView> fieldImprovements = const [],
    List<RoadView> roads = const [],
    this.cityFoundingDraft,
  }) : participants = List.unmodifiable(participants),
       units = List.unmodifiable(units),
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
    _artifactsByCoordinate = _indexArtifactsByCoordinate(
      artifacts,
      unitsById,
      citiesById,
    );
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
    MatchTurnModeView turnMode = MatchTurnModeView.sequential,
    GameOutcomeView? outcome,
    DiplomacyView diplomacy = const DiplomacyView.empty(),
    List<CityView> cities = const [],
    List<WorldArtifactView> artifacts = const [],
    List<FieldImprovementView> fieldImprovements = const [],
    List<RoadView> roads = const [],
    CityFoundingDraftView? cityFoundingDraft,
    int actorColorValue = 0xff000000,
  }) => PlayerMapView(
    actorPlayerId: actorPlayerId,
    stamp: stamp,
    turnMode: turnMode,
    participants: [
      MatchParticipantView(
        id: actorPlayerId,
        name: actorPlayerId,
        colorValue: actorColorValue,
        country: MatchParticipantCountryView.poland,
        kind: MatchParticipantKindView.human,
      ),
    ],
    fog: MapFogView.disabled(),
    economy: PlayerEconomyView.empty(),
    research: PlayerResearchSummaryView.empty(),
    victory: PlayerVictoryView.empty(),
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
  final MatchTurnModeView turnMode;
  final List<MatchParticipantView> participants;
  final MapFogView fog;
  final PlayerEconomyView economy;
  final PlayerResearchSummaryView research;
  final PlayerVictoryView victory;
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

  VisibleUnitView? visibleUnitById(String unitId) {
    for (final unit in units) {
      if (unit.id == unitId) return unit;
    }
    return null;
  }

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

Map<MapHexCoordinate, List<WorldArtifactView>> _indexArtifactsByCoordinate(
  List<WorldArtifactView> artifacts,
  Map<String, VisibleUnitView> unitsById,
  Map<String, CityView> citiesById,
) {
  final byCoordinate = <MapHexCoordinate, List<WorldArtifactView>>{};
  for (final artifact in artifacts) {
    final coordinate = switch (artifact.location) {
      MapArtifactLocationView(:final coordinate) => coordinate,
      ExcavationArtifactLocationView(:final coordinate) => coordinate,
      CarriedArtifactLocationView(:final unitId) =>
        unitsById[unitId]?.coordinate,
      StoredArtifactLocationView(:final cityId) => citiesById[cityId]?.center,
    };
    if (coordinate != null) {
      (byCoordinate[coordinate] ??= []).add(artifact);
    }
  }
  return Map.unmodifiable({
    for (final entry in byCoordinate.entries)
      entry.key: List<WorldArtifactView>.unmodifiable(entry.value),
  });
}
