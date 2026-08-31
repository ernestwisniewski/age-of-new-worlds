import 'package:aonw_flutter/features/artifacts/application/artifact_session_port.dart';
import 'package:aonw_flutter/features/artifacts/application/artifact_state.dart';
import 'package:aonw_flutter/features/artifacts/read_model/artifact_view.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_coordinator.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  test(
    'correlates one excavation command and applies its projection',
    () async {
      const artifactId = 'artifact-crown';
      final unit = testVisibleUnit();
      const onMap = WorldArtifactView(
        id: artifactId,
        kind: WorldArtifactKindView.ancientImperialCrown,
        location: MapArtifactLocationView((col: 0, row: 0)),
      );
      const excavation = WorldArtifactView(
        id: artifactId,
        kind: WorldArtifactKindView.ancientImperialCrown,
        location: ExcavationArtifactLocationView(
          unitId: 'preview-commander',
          coordinate: (col: 0, row: 0),
          remainingTurns: 2,
        ),
      );
      final session = FakeGameSession.success(
        testMapScene(units: [unit], artifacts: const [onMap]),
        reachableResult: testReachableView(),
        artifactResult: ArtifactCommandResultView.accepted(
          player: _player(
            revision: 1,
            unit: testVisibleUnit(excavatingArtifactId: artifactId),
            artifact: excavation,
          ),
        ),
      );
      final controller = _controller(session);
      addTearDown(controller.dispose);

      await controller.load();
      controller.select(unit.coordinate);
      await pumpEventQueue();
      const action = StartArtifactExcavationActionView(
        unitId: 'preview-commander',
      );
      controller.executeArtifactAction(action);
      controller.executeArtifactAction(action);
      await pumpEventQueue();

      expect(session.artifactCommandCalls, 1);
      expect(session.lastArtifactExpectedRevision, 0);
      expect(session.lastArtifactAction, same(action));
      final ready = controller.state as GameSessionReady;
      expect(ready.recipient.stamp.revision, 1);
      expect(
        ready.recipient.artifactById(artifactId)?.location,
        isA<ExcavationArtifactLocationView>(),
      );
      expect(ready.interaction.artifact?.commandPending, isFalse);
    },
  );

  test('keeps a trade rejection typed without client fallback', () async {
    final city = testCityView();
    const artifact = WorldArtifactView(
      id: 'artifact-crown',
      kind: WorldArtifactKindView.ancientImperialCrown,
      location: StoredArtifactLocationView('preview-city'),
    );
    final session = FakeGameSession.success(
      testMapScene(
        cities: [city],
        artifacts: const [artifact],
        diplomaticCounterpartPlayerIds: const ['player-two'],
      ),
      cityInspection: testCityInspectionView(),
      artifactResult: const ArtifactCommandResultView.rejected(
        rejectionCode: ArtifactRejectionCodeView.artifactTradeBlockedByWar,
      ),
    );
    final controller = _controller(session);
    addTearDown(controller.dispose);

    await controller.load();
    controller.select(city.center);
    await pumpEventQueue();
    controller.executeArtifactAction(
      const TradeArtifactActionView(
        targetPlayerId: 'player-two',
        offeredArtifactId: 'artifact-crown',
        offeredGold: 0,
      ),
    );
    await pumpEventQueue();

    final artifactState =
        (controller.state as GameSessionReady).interaction.artifact!;
    expect(artifactState.failure?.code, ArtifactFailureCode.rejected);
    expect(
      artifactState.failure?.rejectionCode,
      ArtifactRejectionCodeView.artifactTradeBlockedByWar,
    );
  });
}

MapCoordinator _controller(FakeGameSession session) =>
    MapCoordinator(capabilities: testGameSessionCapabilities(session));

PlayerMapView _player({
  required int revision,
  required VisibleUnitView unit,
  required WorldArtifactView artifact,
}) => PlayerMapView.preview(
  actorPlayerId: 'preview-player',
  stamp: testSessionStamp(revision: revision, stateDigest: 'd' * 64),
  turn: 1,
  pendingAction: null,
  units: [unit],
  artifacts: [artifact],
);
