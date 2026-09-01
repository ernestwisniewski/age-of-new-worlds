part of 'player_map_view_mapper_test.dart';

void registerPlayerVictoryViewMapperCases(PlayerMapViewMapper mapper) {
  test(
    'maps engine-owned victory rules, live score, and recipient progress',
    () {
      final player = mapper.fromWire(
        _snapshot(const [], victory: _victory()),
        map: testMapScene().map,
        actorPlayerId: 'player-1',
      );

      expect(player.victory.conquestEnabled, isTrue);
      expect(player.victory.dominationRequiredControlPercent, 60);
      expect(player.victory.scoreByPlayerId, {'player-1': 37, 'player-2': 21});
      expect(player.victory.domination.first.controlledPassableHexes, 3);
      expect(player.victory.ownCultural.uniqueStoredArtifacts, 2);
      expect(player.victory.remainingTurns, 13);
      expect(
        () => player.victory.scoreByPlayerId['player-1'] = 0,
        throwsUnsupportedError,
      );
    },
  );

  test('validates disclosure-filtered map objective progress', () {
    const objective = MapObjectiveView(
      id: 'central-ruins',
      type: MapObjectiveType.ruins,
      coordinate: (col: 1, row: 0),
      requiredHoldTurns: 3,
      victoryPoints: 5,
      goldPerTurn: 2,
    );
    final map = testMapScene(objectives: const [objective]).map;
    final visible = mapper.fromWire(
      _snapshot(
        const [],
        victory: _victory(
          mapObjectives: const [
            AonwMapObjectiveProgress(
              objectiveId: 'central-ruins',
              controllerPlayerId: 'player-1',
              holdTurns: 2,
            ),
          ],
        ),
      ),
      map: map,
      actorPlayerId: 'player-1',
    );

    expect(visible.victory.mapObjectives.single.controllerPlayerId, 'player-1');
    expect(
      () => mapper.fromWire(
        _snapshot(
          const [],
          victory: _victory(
            mapObjectives: const [
              AonwMapObjectiveProgress(
                objectiveId: 'central-ruins',
                controllerPlayerId: null,
                holdTurns: 2,
              ),
            ],
          ),
        ),
        map: map,
        actorPlayerId: 'player-1',
      ),
      throwsFormatException,
    );
  });

  test('rejects invalid or unordered victory pressure', () {
    expect(
      () => mapper.fromWire(
        _snapshot(
          const [],
          victory: _victory(
            scoreByPlayerId: const {'player-2': 21, 'player-1': 37},
          ),
        ),
        map: testMapScene().map,
        actorPlayerId: 'player-1',
      ),
      throwsFormatException,
    );
  });
}
