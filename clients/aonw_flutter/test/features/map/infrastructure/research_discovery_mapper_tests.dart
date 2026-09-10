part of 'map_feedback_mapper_test.dart';

void researchDiscoveryMapperTests() {
  const own = AonwTechnologyResearchedEvent(
    playerId: 'preview-player',
    technology: AonwTechnologyId.mining,
  );
  const foreign = AonwTechnologyResearchedEvent(
    playerId: 'other',
    technology: AonwTechnologyId.agriculture,
  );
  test('discovery keeps only own completion even without a visible anchor', () {
    final previous = feedbackSnapshot();
    final snapshot = _snapshot(cities: false, hasUnit: false, visible: []);
    final discoveries = mapResearchDiscoveries(
      command: _command(snapshot, [foreign, own]),
      snapshot: snapshot,
      previous: previous.player,
      map: previous.map,
    );
    expect(discoveries.single.technology.name, 'mining');
    expect(discoveries.single.identity, (revision: 1, eventIndex: 1));
    final player = const PlayerMapViewMapper().fromWire(
      snapshot,
      map: previous.map,
      actorPlayerId: previous.player.actorPlayerId,
      recentDiscoveries: discoveries,
    );
    expect(player.recentDiscoveries, discoveries);
    expect(() => player.recentDiscoveries.clear(), throwsUnsupportedError);
    expect(
      const PlayerMapViewMapper()
          .fromWire(
            snapshot,
            map: previous.map,
            actorPlayerId: previous.player.actorPlayerId,
          )
          .recentDiscoveries,
      isEmpty,
    );
  });
  test('discovery journal is bounded and rejects discontinuous history', () {
    final previous = feedbackSnapshot();
    final snapshot = _snapshot();
    final discoveries = mapResearchDiscoveries(
      command: _command(snapshot, List.filled(70, own)),
      snapshot: snapshot,
      previous: previous.player,
      map: previous.map,
    );
    expect(discoveries, hasLength(maximumRecentResearchDiscoveries));
    expect(discoveries.first.identity.eventIndex, 6);
    expect(discoveries.last.identity.eventIndex, 69);
    expect(() => discoveries.clear(), throwsUnsupportedError);
    expect(
      () => mapResearchDiscoveries(
        command: _command(_snapshot(revision: 2), [own]),
        snapshot: _snapshot(revision: 2),
        previous: previous.player,
        map: previous.map,
      ),
      throwsFormatException,
    );
    expect(
      mapResearchDiscoveries(
        command: _command(snapshot, [own], accepted: false),
        snapshot: snapshot,
        previous: previous.player,
        map: previous.map,
      ),
      isEmpty,
    );
  });
}
