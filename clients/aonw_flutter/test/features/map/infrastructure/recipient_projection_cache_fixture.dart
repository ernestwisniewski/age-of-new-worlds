part of 'recipient_projection_cache_test.dart';

RecipientProjectionCache _cache(AonwPlayerViewSnapshot snapshot) =>
    RecipientProjectionCache.open(snapshot: snapshot, map: testMapScene().map);

AonwPlayerViewSnapshot _snapshot({
  int revision = 0,
  String? rulesetHash,
  AonwTurnMode turnMode = AonwTurnMode.sequential,
  List<AonwPlayerParticipantView> participants = const [
    AonwPlayerParticipantView(
      id: 'player-1',
      name: 'Player One',
      colorValue: 0xff000000,
      country: AonwPlayerCountry.poland,
      kind: AonwPlayerKind.human,
    ),
  ],
  AonwPlayerFogView fog = const AonwPlayerFogView(
    enabled: false,
    discoveredHexes: [],
    visibleHexes: [],
  ),
  AonwPendingActionView? pendingAction,
  AonwCityFoundingDraft? cityFoundingDraft,
  AonwPlayerEconomyView? economy,
  AonwPlayerResearchView? research,
  AonwPlayerVictoryView? victory,
  List<AonwPlayerUnitView>? units,
}) => AonwPlayerViewSnapshot(
  stamp: _stamp(
    revision: revision,
    stateDigest: revision == 0 ? 'b' * 64 : 'd' * 64,
    rulesetHash: rulesetHash,
  ),
  turn: 1,
  turnMode: turnMode,
  participants: participants,
  fog: fog,
  economy: economy ?? AonwPlayerEconomyView.empty(),
  research: research ?? AonwPlayerResearchView.empty(),
  victory: victory ?? AonwPlayerVictoryView.empty(),
  outcome: AonwGameOutcome(
    condition: AonwGameOutcomeCondition.ongoing,
    winnerPlayerId: null,
    scoreByPlayerId: const {'player-1': 0},
  ),
  turnLifecycle: const AonwPlayerTurnLifecycle(
    ownState: AonwPlayerTurnState.active,
    ownSubmitted: false,
    requiredSubmissionCount: 1,
    submittedCount: 0,
  ),
  pendingAction: pendingAction,
  cityFoundingDraft: cityFoundingDraft,
  diplomacy: _diplomacy(),
  units: units ?? [_unit()],
  cities: const [],
  artifacts: const [],
  fieldImprovements: const [],
  roads: const [],
);

AonwSessionStamp _stamp({
  required int revision,
  required String stateDigest,
  String? rulesetHash,
}) => AonwSessionStamp(
  revision: revision,
  stateDigest: stateDigest,
  mapHash: 'a' * 64,
  rulesetHash: rulesetHash ?? 'c' * 64,
);

AonwPlayerUnitView _unit({
  int col = 0,
  int row = 0,
  int? hitPoints = 7,
  int? maximumHitPoints = 10,
}) => AonwPlayerUnitView(
  id: 'unit-1',
  ownerPlayerId: 'player-1',
  kind: AonwUnitKind.commander,
  name: 'Commander',
  coordinate: AonwCoordinate(col: col, row: row),
  movementUnits: 8,
  posture: AonwUnitPosture.active,
  hitPoints: hitPoints,
  maximumHitPoints: maximumHitPoints,
  workerBuildCharges: 0,
  workerJob: null,
  workerAssignment: null,
);

AonwPlayerDiplomacyView _diplomacy() => const AonwPlayerDiplomacyView(
  relations: [],
  proposals: [],
  messages: [],
  resourceTradeAgreements: [],
);

AonwPlayerResearchView _research({int progress = 4}) => AonwPlayerResearchView(
  activeTechnology: AonwTechnologyId.agriculture,
  activeProgress: progress,
  activeEffectiveCost: 20,
  scienceOverflow: 0,
  scienceYield: AonwScienceYieldBreakdown(
    total: 0,
    byCityId: const {},
    sources: const [],
  ),
);

AonwPlayerVictoryView _victory({required int turn, required int score}) =>
    AonwPlayerVictoryView(
      conquestEnabled: true,
      dominationEnabled: true,
      dominationRequiredControlPercent: 60,
      dominationRequiredHoldTurns: 5,
      culturalEnabled: true,
      culturalRequiredArtifacts: 6,
      culturalRequiredHoldTurns: 5,
      scoreFallbackEnabled: true,
      turnLimit: 20,
      remainingTurns: 20 - turn,
      scoreByPlayerId: {'player-1': score},
      domination: const [
        AonwDominationVictoryProgress(
          playerId: 'player-1',
          controlledPassableHexes: 2,
          totalPassableHexes: 6,
          holdTurns: 0,
        ),
      ],
      ownCultural: const AonwCulturalVictoryProgress(
        uniqueStoredArtifacts: 1,
        holdTurns: 0,
      ),
      mapObjectives: const [],
    );

AonwCommandResult _command({
  required AonwSessionStamp stamp,
  required AonwPlayerViewPatch patch,
  bool accepted = true,
}) => AonwCommandResult(
  stamp: stamp,
  outcome: accepted
      ? const AonwCommandAccepted()
      : const AonwCommandRejected(AonwCommandRejectionCode.staleRevision),
  events: const [],
  evidence: null,
  viewPatch: patch,
);

AonwPlayerViewPatch _patch({
  required int fromRevision,
  required int toRevision,
  required int turn,
  AonwTurnMode turnMode = AonwTurnMode.sequential,
  AonwPlayerTurnLifecycle? turnLifecycle,
  AonwGameOutcome? outcome,
  AonwPlayerFogView? fog,
  AonwPlayerEconomyView? economy,
  AonwPlayerResearchView? research,
  AonwPlayerVictoryView? victory,
  AonwPlayerDiplomacyView? diplomacy,
  AonwPendingActionView? pendingAction,
  AonwCityFoundingDraft? cityFoundingDraft,
  List<AonwPlayerUnitView> upsertedUnits = const [],
  List<String> removedUnitIds = const [],
}) => AonwPlayerViewPatch(
  fromRevision: fromRevision,
  toRevision: toRevision,
  turn: turn,
  turnMode: turnMode,
  fog: fog,
  economy: economy,
  research: research,
  victory: victory,
  turnLifecycle: turnLifecycle,
  outcome: outcome,
  upsertedUnits: upsertedUnits,
  removedUnitIds: removedUnitIds,
  upsertedCities: const [],
  removedCityIds: const [],
  upsertedArtifacts: const [],
  removedArtifactIds: const [],
  upsertedFieldImprovements: const [],
  removedFieldImprovementCoordinates: const [],
  upsertedRoads: const [],
  removedRoadCoordinates: const [],
  pendingAction: pendingAction,
  cityFoundingDraft: cityFoundingDraft,
  diplomacy: diplomacy,
);

AonwCityFoundingDraft _draft({String founderUnitId = 'unit-1'}) =>
    AonwCityFoundingDraft(
      founderUnitId: founderUnitId,
      center: const AonwCoordinate(col: 1, row: 1),
      controlledHexes: const [AonwCoordinate(col: 1, row: 1)],
    );
