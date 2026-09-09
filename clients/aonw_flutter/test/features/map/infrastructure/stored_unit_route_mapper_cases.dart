part of 'player_map_view_mapper_test.dart';

const _storedRouteSteps = [
  AonwPersistedMovementStep(
    coordinate: AonwCoordinate(col: 0, row: 0),
    enterCostUnits: 0,
    cumulativeCostUnits: 0,
  ),
  AonwPersistedMovementStep(
    coordinate: AonwCoordinate(col: 1, row: 0),
    enterCostUnits: 2,
    cumulativeCostUnits: 2,
  ),
];

void registerStoredUnitRouteCases(PlayerMapViewMapper mapper) {
  PlayerMapView read(
    AonwOwnedUnitDetails details, {
    String owner = 'player-1',
  }) => mapper.fromWire(
    _snapshot([_unit('unit-a', ownerPlayerId: owner, ownedDetails: details)]),
    map: testMapScene().map,
    actorPlayerId: 'player-1',
  );

  test('retains exact immutable steps and rejects foreign private routes', () {
    final details = _routeDetails(_storedRouteSteps);
    final route = read(details).units.single.queuedRoute!;
    expect(route.steps.map((step) => step.coordinate), [
      (col: 0, row: 0),
      (col: 1, row: 0),
    ]);
    expect(route.steps.last.enterCostUnits, 2);
    expect(route.steps.last.cumulativeCostUnits, 2);
    expect(() => route.steps.clear(), throwsUnsupportedError);
    expect(() => read(details, owner: 'player-2'), throwsFormatException);
  });

  test(
    'rejects missing, displaced, out-of-map and inconsistent route steps',
    () {
      for (final steps in <List<AonwPersistedMovementStep>>[
        [],
        [_storedRouteSteps.first],
        [_storedRouteSteps.last, _storedRouteSteps.first],
        [
          _storedRouteSteps.first,
          const AonwPersistedMovementStep(
            coordinate: AonwCoordinate(col: 10000, row: 0),
            enterCostUnits: 2,
            cumulativeCostUnits: 2,
          ),
        ],
        [
          _storedRouteSteps.first,
          const AonwPersistedMovementStep(
            coordinate: AonwCoordinate(col: 1, row: 0),
            enterCostUnits: 2,
            cumulativeCostUnits: 3,
          ),
        ],
      ]) {
        expect(() => read(_routeDetails(steps)), throwsFormatException);
      }
      expect(
        () => read(
          _routeDetails(
            _storedRouteSteps,
            target: const AonwCoordinate(col: 2, row: 0),
          ),
        ),
        throwsFormatException,
      );
    },
  );
}

AonwOwnedUnitDetails _routeDetails(
  List<AonwPersistedMovementStep> steps, {
  AonwCoordinate target = const AonwCoordinate(col: 1, row: 0),
}) => AonwOwnedUnitDetails(
  army: const [],
  queuedPath: AonwQueuedMovePath(target: target, steps: steps),
  merchantTradeRoute: null,
  workerJob: null,
  cityFoundingJob: null,
  workerAssignment: null,
  excavatingArtifactId: null,
  workerBuildCharges: 0,
  experiencePoints: 0,
);
