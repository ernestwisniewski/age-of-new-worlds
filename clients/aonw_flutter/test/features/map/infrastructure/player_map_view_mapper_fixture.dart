part of 'player_map_view_mapper_test.dart';

AonwPlayerViewSnapshot _snapshot(
  List<AonwPlayerUnitView> units, {
  String? mapHash,
  AonwPendingActionView? pendingAction,
  List<AonwPlayerCityView> cities = const [],
  List<AonwPlayerArtifactView> artifacts = const [],
  AonwPlayerDiplomacyView? diplomacy,
  List<AonwFieldImprovementView> fieldImprovements = const [],
  List<AonwRoadView> roads = const [],
  AonwPlayerEconomyView? economy,
  AonwPlayerFogView fog = const AonwPlayerFogView(
    enabled: true,
    discoveredHexes: [
      AonwCoordinate(col: 0, row: 0),
      AonwCoordinate(col: 1, row: 0),
    ],
    visibleHexes: [AonwCoordinate(col: 1, row: 0)],
  ),
}) => AonwPlayerViewSnapshot(
  stamp: AonwSessionStamp(
    revision: 7,
    stateDigest: 'b' * 64,
    mapHash: mapHash ?? 'a' * 64,
    rulesetHash: 'c' * 64,
  ),
  turn: 7,
  turnMode: AonwTurnMode.sequential,
  participants: const [
    AonwPlayerParticipantView(
      id: 'player-1',
      name: 'Player One',
      colorValue: 0xff000000,
      country: AonwPlayerCountry.poland,
      kind: AonwPlayerKind.human,
    ),
    AonwPlayerParticipantView(
      id: 'player-2',
      name: 'Player Two',
      colorValue: 0xffffffff,
      country: AonwPlayerCountry.germany,
      kind: AonwPlayerKind.ai,
    ),
  ],
  fog: fog,
  economy: economy ?? AonwPlayerEconomyView.empty(),
  outcome: AonwGameOutcome(
    condition: AonwGameOutcomeCondition.ongoing,
    winnerPlayerId: null,
    scoreByPlayerId: const {},
  ),
  turnLifecycle: const AonwPlayerTurnLifecycle(
    ownState: AonwPlayerTurnState.active,
    ownSubmitted: false,
    requiredSubmissionCount: 1,
    submittedCount: 0,
  ),
  pendingAction: pendingAction,
  cityFoundingDraft: null,
  diplomacy: diplomacy ?? _diplomacy(),
  units: units,
  cities: cities,
  artifacts: artifacts,
  fieldImprovements: fieldImprovements,
  roads: roads,
);

AonwPlayerCityView _city() => AonwPlayerCityView(
  id: 'city-a',
  ownerPlayerId: 'player-1',
  name: 'Capital',
  center: const AonwCoordinate(col: 1, row: 1),
  visibleControlledHexes: const [AonwCoordinate(col: 1, row: 1)],
  hitPoints: 10,
  ownedDetails: AonwOwnedCityDetails(
    population: 3,
    storedFood: 2,
    maxHexes: 6,
    territoryRadius: 2,
    workedHexes: const [AonwCoordinate(col: 1, row: 1)],
    buildings: const [AonwCityBuildingType.workshop],
    wonders: const [AonwWonderType.greatLibrary],
    productionQueue: AonwCityProductionQueue(
      target: AonwCityProductionTarget.fromJson(const {
        'kind': 'unit',
        'unitType': 'tank',
      }),
      investedProduction: 7,
      resourceAllocation: const {AonwResourceType.oil: 2},
    ),
    productionOverflow: 3,
    specialization: AonwCitySpecialization.industry,
    preferredExpansionHex: const AonwCoordinate(col: 2, row: 1),
  ),
);

AonwPlayerUnitView _unit(
  String id, {
  int col = 0,
  int row = 0,
  String ownerPlayerId = 'player-1',
  AonwOwnedUnitDetails? ownedDetails,
  AonwUnitKind kind = AonwUnitKind.commander,
  String? carriedArtifactId,
}) => AonwPlayerUnitView(
  id: id,
  ownerPlayerId: ownerPlayerId,
  kind: kind,
  name: 'Commander',
  coordinate: AonwCoordinate(col: col, row: row),
  movementUnits: 12,
  posture: AonwUnitPosture.active,
  workerBuildCharges: ownedDetails?.workerBuildCharges ?? 0,
  workerJob: ownedDetails?.workerJob,
  workerAssignment: ownedDetails?.workerAssignment,
  carriedArtifactId: carriedArtifactId,
  ownedDetails: ownedDetails,
);

AonwPlayerDiplomacyView _diplomacy([List<String> counterpartIds = const []]) =>
    AonwPlayerDiplomacyView(
      relations: [
        for (final id in counterpartIds)
          AonwPlayerDiplomaticRelationView(
            counterpartPlayerId: id,
            status: AonwDiplomaticRelationStatus.neutral,
            relationScore: 0,
            statusExpiresOnTurn: null,
            lastChangedTurn: null,
            lastChangeReason: null,
          ),
      ],
      proposals: const [],
      messages: const [],
      resourceTradeAgreements: const [],
    );

AonwPlayerEconomyView _economy({
  int gold = 10,
  int warWeariness = 0,
  int stabilityNet = 0,
  bool withOutput = false,
}) => AonwPlayerEconomyView(
  gold: gold,
  warWeariness: warWeariness,
  stabilityNet: stabilityNet,
  strategicResourceStockpile: const [
    AonwPlayerStrategicResourceAmount(
      resource: AonwResourceType.oil,
      amount: 2,
    ),
  ],
  strategicResourceOutput: withOutput
      ? const [
          AonwPlayerStrategicResourceAmount(
            resource: AonwResourceType.oil,
            amount: 1,
          ),
        ]
      : const [],
  strategicResourceSources: withOutput
      ? const [
          AonwPlayerStrategicResourceSource(
            cityId: 'city-a',
            coordinate: AonwCoordinate(col: 1, row: 1),
            resource: AonwResourceType.oil,
            improvement: AonwFieldImprovementKind.oilWell,
            amountPerTurn: 1,
          ),
        ]
      : const [],
);
