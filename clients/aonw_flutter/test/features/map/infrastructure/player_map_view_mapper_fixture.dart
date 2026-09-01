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
  AonwPlayerResearchView? research,
  AonwPlayerVictoryView? victory,
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
  research: research ?? AonwPlayerResearchView.empty(),
  victory: victory ?? AonwPlayerVictoryView.empty(),
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

AonwPlayerVictoryView _victory({
  Map<String, int> scoreByPlayerId = const {'player-1': 37, 'player-2': 21},
  List<AonwMapObjectiveProgress> mapObjectives = const [],
}) => AonwPlayerVictoryView(
  conquestEnabled: true,
  dominationEnabled: true,
  dominationRequiredControlPercent: 60,
  dominationRequiredHoldTurns: 5,
  culturalEnabled: true,
  culturalRequiredArtifacts: 6,
  culturalRequiredHoldTurns: 5,
  scoreFallbackEnabled: true,
  turnLimit: 20,
  remainingTurns: 13,
  scoreByPlayerId: scoreByPlayerId,
  domination: const [
    AonwDominationVictoryProgress(
      playerId: 'player-1',
      controlledPassableHexes: 3,
      totalPassableHexes: 6,
      holdTurns: 0,
    ),
    AonwDominationVictoryProgress(
      playerId: 'player-2',
      controlledPassableHexes: 2,
      totalPassableHexes: 6,
      holdTurns: 0,
    ),
  ],
  ownCultural: const AonwCulturalVictoryProgress(
    uniqueStoredArtifacts: 2,
    holdTurns: 1,
  ),
  mapObjectives: mapObjectives,
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
  hitPoints: 7,
  maximumHitPoints: 10,
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
  AonwEconomyForecast? forecast,
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
  forecast: forecast ?? _forecast(treasury: gold, warWeariness: warWeariness),
);

AonwEconomyForecast _forecast({
  required int treasury,
  int warWeariness = 0,
  int cityIncome = 0,
  int projectIncome = 0,
  List<AonwGoldIncomeSource> citySources = const [],
  List<AonwGoldIncomeSource> projectSources = const [],
}) => AonwEconomyForecast(
  treasury: treasury,
  cityIncome: cityIncome,
  projectIncome: projectIncome,
  grossIncome: cityIncome + projectIncome,
  netPerTurn: cityIncome + projectIncome,
  citySources: citySources,
  projectSources: projectSources,
  upkeep: AonwUnitUpkeepBreakdown.empty(),
  stability: AonwStabilityBreakdown(
    baseOrder: 0,
    buildingSources: 0,
    luxurySources: 0,
    technologySources: 0,
    artifactSources: 0,
    wonderSources: 0,
    cityCost: 0,
    populationCost: 0,
    cohesionCost: 0,
    conqueredCityCost: 0,
    warWearinessCost: warWeariness,
    hegemonyTax: 0,
    sourceTotal: 0,
    costTotal: warWeariness,
    relativeStandingAdjustment: 0,
    effectiveNet: -warWeariness,
    band: AonwStabilityBand.stable,
  ),
);

AonwPlayerResearchView _research({
  AonwTechnologyId? activeTechnology = AonwTechnologyId.agriculture,
  int? activeProgress = 4,
  int? activeEffectiveCost = 20,
  String sourceCityId = 'city-a',
}) => AonwPlayerResearchView(
  activeTechnology: activeTechnology,
  activeProgress: activeProgress,
  activeEffectiveCost: activeEffectiveCost,
  scienceOverflow: 1,
  scienceYield: AonwScienceYieldBreakdown(
    total: 5,
    byCityId: {sourceCityId: 5},
    sources: [
      AonwScienceYieldSource(
        cityId: sourceCityId,
        amount: 5,
        kind: AonwScienceYieldSourceKind.cityScience,
      ),
    ],
  ),
);
