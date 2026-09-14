part of 'map_test_fixture.dart';

MapScene testMapScene({
  int cols = 3,
  int rows = 2,
  String? mapId,
  String? contentHash,
  double defaultZoom = 1,
  List<MapObjectiveView> objectives = const [],
  List<VisibleUnitView> units = const [],
  List<CityView> cities = const [],
  List<WorldArtifactView> artifacts = const [],
  List<String> diplomaticCounterpartPlayerIds = const [],
  DiplomacyView? diplomacy,
  List<FieldImprovementView> fieldImprovements = const [],
  List<RoadView> roads = const [],
  CityFoundingDraftView? cityFoundingDraft,
  GameOutcomeView? outcome,
  PendingActionView? pendingAction,
  int actorColorValue = 0xff000000,
}) {
  final terrains = MapTerrain.values;
  final tiles = <MapTileView>[];
  for (var row = 0; row < rows; row++) {
    for (var col = 0; col < cols; col++) {
      final terrain = terrains[(row * cols + col) % terrains.length];
      tiles.add(
        MapTileView(
          coordinate: (col: col, row: row),
          displayTerrain: terrain,
          yieldTerrain: terrain,
          movementTerrains: [terrain],
          terrainTags: [terrain],
          resources: const [],
          height: 0,
        ),
      );
    }
  }
  return MapScene(
    map: MapView(
      mapId: mapId ?? (cols == 7 && rows == 7 ? 'aonw2_starter' : 'test-map'),
      contentHash: contentHash ?? 'a' * 64,
      gridLayout: MapGridLayout.oddQFlatTop,
      cols: cols,
      rows: rows,
      defaultZoom: defaultZoom,
      tiles: tiles,
      objectives: objectives,
    ),
    reference: MapReferenceBundle(
      mapId: mapId ?? (cols == 7 && rows == 7 ? 'aonw2_starter' : 'test-map'),
      mapContentHash: contentHash ?? 'a' * 64,
      worldWidth: 120 + (cols - 1) * 90,
      worldHeight: 103.92304845413263 * (rows + (cols > 1 ? 0.5 : 0)),
      pages: const [],
    ),
    player: PlayerMapView.preview(
      actorPlayerId: 'preview-player',
      stamp: SessionStampView(
        revision: 0,
        stateDigest: 'b' * 64,
        mapHash: contentHash ?? 'a' * 64,
        rulesetHash: 'c' * 64,
      ),
      turn: 1,
      pendingAction: pendingAction,
      outcome: outcome,
      units: units,
      diplomacy:
          diplomacy ??
          DiplomacyView(
            relations: [
              for (final id in diplomaticCounterpartPlayerIds)
                DiplomaticRelationView(
                  counterpartPlayerId: id,
                  status: DiplomaticRelationStatusView.neutral,
                  relationScore: 0,
                  statusExpiresOnTurn: null,
                  lastChangedTurn: null,
                  lastChangeReason: null,
                ),
            ],
            proposals: const [],
            messages: const [],
            resourceTradeAgreements: const [],
          ),
      cities: cities,
      artifacts: artifacts,
      fieldImprovements: fieldImprovements,
      roads: roads,
      cityFoundingDraft: cityFoundingDraft,
      actorColorValue: actorColorValue,
    ),
  );
}

RoutePlanView testRoutePlanView({
  String unitId = 'preview-commander',
  MapHexCoordinate origin = (col: 0, row: 0),
  MapHexCoordinate target = (col: 1, row: 0),
}) => RoutePlanView(
  roadStepIndices: const [],
  stamp: testSessionStamp(),
  unitId: unitId,
  target: target,
  destination: target,
  totalCostUnits: 4,
  availableMovementUnits: 12,
  remainingMovementUnits: 8,
  estimatedTurns: 1,
  stepTurns: const [1, 1],
  steps: [
    MovementStepView(
      coordinate: origin,
      enterCostUnits: 0,
      cumulativeCostUnits: 0,
    ),
    MovementStepView(
      coordinate: target,
      enterCostUnits: 4,
      cumulativeCostUnits: 4,
    ),
  ],
);

MoveUnitExecutionView testMoveUnitExecutionView({
  String unitId = 'preview-commander',
  MapHexCoordinate from = const (col: 0, row: 0),
  MapHexCoordinate to = const (col: 1, row: 0),
}) => MoveUnitExecutionView(
  events: [UnitMovedEventView(unitId: unitId, from: from, to: to)],
  evidence: UnitMovementEvidenceView(
    unitId: unitId,
    from: from,
    steps: [
      MovementStepView(
        coordinate: to,
        enterCostUnits: 4,
        cumulativeCostUnits: 4,
      ),
    ],
  ),
);
