import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_coordinator.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/research/application/research_session_port.dart';
import 'package:aonw_flutter/features/research/application/research_state.dart';
import 'package:aonw_flutter/features/research/read_model/research_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  test(
    'loads selects once and refreshes options at the new revision',
    () async {
      final session = FakeGameSession.success(
        testMapScene(),
        researchResult: ResearchCommandResultView.accepted(
          player: _player(revision: 1),
        ),
      );
      final controller = _controller(session);
      addTearDown(controller.dispose);

      await controller.load();
      await pumpEventQueue();
      expect(session.researchOptionCalls, 1);
      expect(
        (controller.state as GameSessionReady).research.options?.options,
        hasLength(TechnologyIdView.values.length),
      );

      controller.selectTechnology(TechnologyIdView.agriculture);
      controller.selectTechnology(TechnologyIdView.agriculture);
      await pumpEventQueue();

      final ready = controller.state as GameSessionReady;
      expect(session.researchCommandCalls, 1);
      expect(session.lastResearchExpectedRevision, 1);
      expect(session.lastResearchTechnology, TechnologyIdView.agriculture);
      expect(session.researchOptionCalls, 2);
      expect(ready.recipient.stamp.revision, 1);
      expect(ready.research.options?.stamp.revision, 1);
      expect(ready.research.commandPending, isFalse);
    },
  );

  test('keeps engine research rejection typed', () async {
    final session = FakeGameSession.success(
      testMapScene(),
      researchResult: const ResearchCommandResultView.rejected(
        rejectionCode: ResearchRejectionCodeView.technologyNotAvailable,
      ),
    );
    final controller = _controller(session);
    addTearDown(controller.dispose);

    await controller.load();
    await pumpEventQueue();
    controller.selectTechnology(TechnologyIdView.agriculture);
    await pumpEventQueue();

    final failure = (controller.state as GameSessionReady).research.failure;
    expect(failure?.code, ResearchFailureCode.rejected);
    expect(
      failure?.rejectionCode,
      ResearchRejectionCodeView.technologyNotAvailable,
    );
  });
}

MapCoordinator _controller(FakeGameSession session) =>
    MapCoordinator(capabilities: testGameSessionCapabilities(session));

PlayerMapView _player({required int revision}) => PlayerMapView.preview(
  actorPlayerId: 'preview-player',
  stamp: testSessionStamp(revision: revision, stateDigest: 'd' * 64),
  turn: 1,
  pendingAction: null,
  units: const [],
);
