part of 'map_feedback_mapper_test.dart';

AonwPlayerViewSnapshot _snapshot({
  int revision = 1,
  bool cities = true,
  AonwCoordinate unitCoordinate = const AonwCoordinate(col: 0, row: 1),
  bool hasUnit = true,
  List<AonwCoordinate>? visible,
}) => AonwPlayerViewSnapshot(
  stamp: AonwSessionStamp(
    revision: revision,
    stateDigest: '$revision'.padLeft(64, 'd'),
    mapHash: 'a' * 64,
    rulesetHash: 'c' * 64,
  ),
  turn: 1,
  turnMode: AonwTurnMode.sequential,
  participants: const [
    AonwPlayerParticipantView(
      id: 'preview-player',
      name: 'Player',
      colorValue: 0xff68a7e8,
      country: AonwPlayerCountry.poland,
      kind: AonwPlayerKind.human,
    ),
  ],
  fog: AonwPlayerFogView(
    enabled: visible != null,
    discoveredHexes: visible ?? const [],
    visibleHexes: visible ?? const [],
  ),
  economy: AonwPlayerEconomyView.empty(),
  research: AonwPlayerResearchView.empty(),
  victory: AonwPlayerVictoryView.empty(),
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
  pendingAction: null,
  cityFoundingDraft: null,
  diplomacy: const AonwPlayerDiplomacyView(
    relations: [],
    proposals: [],
    messages: [],
    resourceTradeAgreements: [],
  ),
  units: hasUnit
      ? [
          AonwPlayerUnitView(
            id: 'unit',
            ownerPlayerId: 'preview-player',
            kind: AonwUnitKind.commander,
            name: 'Commander',
            coordinate: unitCoordinate,
            movementUnits: 12,
            posture: AonwUnitPosture.active,
            workerBuildCharges: 0,
            workerJob: null,
            workerAssignment: null,
          ),
        ]
      : const [],
  cities: cities
      ? const [
          AonwPlayerCityView(
            id: 'city',
            ownerPlayerId: 'preview-player',
            name: 'City',
            center: AonwCoordinate(col: 1, row: 0),
            visibleControlledHexes: [AonwCoordinate(col: 1, row: 0)],
            ownedDetails: null,
          ),
        ]
      : const [],
  artifacts: const [],
  fieldImprovements: const [],
  roads: const [],
);

AonwCommandResult _command(
  AonwPlayerViewSnapshot snapshot,
  List<AonwClientEvent> events, {
  bool accepted = true,
  int? fromRevision,
  AonwClientEvidence? evidence,
}) => AonwCommandResult(
  stamp: snapshot.stamp,
  outcome: accepted
      ? const AonwCommandAccepted()
      : const AonwCommandRejected(AonwCommandRejectionCode.staleRevision),
  events: events,
  evidence: evidence,
  viewPatch: AonwPlayerViewPatch(
    fromRevision: fromRevision ?? snapshot.stamp.revision - 1,
    toRevision: snapshot.stamp.revision,
    turn: snapshot.turn,
    turnMode: snapshot.turnMode,
    turnLifecycle: null,
    outcome: null,
    pendingAction: null,
    cityFoundingDraft: null,
    diplomacy: null,
    upsertedUnits: const [],
    removedUnitIds: const [],
    upsertedCities: const [],
    removedCityIds: const [],
    upsertedArtifacts: const [],
    removedArtifactIds: const [],
    upsertedFieldImprovements: const [],
    removedFieldImprovementCoordinates: const [],
    upsertedRoads: const [],
    removedRoadCoordinates: const [],
  ),
);

const _events = <AonwClientEvent>[
  AonwCityFoundedEvent(cityId: 'city', ownerPlayerId: 'preview-player'),
  AonwCityProducedUnitEvent(
    cityId: 'city',
    unitType: AonwUnitKind.worker,
    producedUnitId: 'worker',
  ),
  AonwCityClaimedHexEvent(
    cityId: 'city',
    coordinate: AonwCoordinate(col: 2, row: 1),
  ),
  AonwTechnologyResearchedEvent(
    playerId: 'preview-player',
    technology: AonwTechnologyId.navigation,
  ),
];
