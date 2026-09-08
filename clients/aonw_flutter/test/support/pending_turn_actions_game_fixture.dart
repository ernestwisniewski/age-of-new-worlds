part of 'map_test_fixture.dart';

extension _PendingTurnActionsGameFixture on FakeGameSession {
  /// Unspecified pending work is empty; navigation scenarios supply their list.
  PendingTurnActionsView _emptyPendingTurnActions(int revision) {
    final player =
        [
          scene?.player,
          moveResult?.player,
          unitActionResult?.player,
          turnResult?.player,
          logisticsResult?.player,
          workerResult?.player,
          productionResult?.player,
          artifactResult?.player,
          researchResult?.player,
          diplomacyResult?.player,
          combatResult?.player,
          cityResult?.player,
          ...handoffPlayers.values,
          ...aiTurnResults.map((result) => result.player),
        ].whereType<PlayerMapView>().firstWhere(
          (player) => player.stamp.revision == revision,
          orElse: () =>
              throw StateError('No recipient fixture for revision $revision.'),
        );
    return PendingTurnActionsView(
      stamp: player.stamp,
      actorPlayerId: player.actorPlayerId,
      canActivate: true,
      actions: const [],
    );
  }
}
