import 'package:aonw_flutter/features/diplomacy/application/diplomacy_session_port.dart';
import 'package:aonw_flutter/features/diplomacy/application/diplomacy_state.dart';
import 'package:aonw_flutter/features/diplomacy/read_model/diplomacy_view.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_coordinator.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  test('correlates one action and applies only its recipient patch', () async {
    final session = FakeGameSession.success(
      testMapScene(diplomacy: _diplomacy()),
      diplomacyResult: DiplomacyCommandResultView.accepted(
        player: _player(revision: 1, status: DiplomaticRelationStatusView.war),
      ),
    );
    final controller = _controller(session);
    addTearDown(controller.dispose);
    await controller.load();
    await pumpEventQueue();

    const action = DeclareWarActionView('player-2');
    controller.executeDiplomacyAction(action);
    controller.executeDiplomacyAction(action);
    await pumpEventQueue();

    final ready = controller.state as GameSessionReady;
    expect(session.diplomacyCommandCalls, 1);
    expect(session.lastDiplomacyExpectedRevision, 0);
    expect(session.lastDiplomacyAction, same(action));
    expect(ready.recipient.stamp.revision, 1);
    expect(
      ready.recipient.diplomacy.relationWith('player-2')?.status,
      DiplomaticRelationStatusView.war,
    );
    expect(ready.diplomacy.commandPending, isFalse);
  });

  test('keeps an engine rejection typed without optimistic residue', () async {
    final session = FakeGameSession.success(
      testMapScene(diplomacy: _diplomacy()),
      diplomacyResult: const DiplomacyCommandResultView.rejected(
        rejectionCode: DiplomacyRejectionCodeView.diplomacyTruceActive,
      ),
    );
    final controller = _controller(session);
    addTearDown(controller.dispose);
    await controller.load();
    await pumpEventQueue();
    controller.executeDiplomacyAction(const DeclareWarActionView('player-2'));
    await pumpEventQueue();

    final ready = controller.state as GameSessionReady;
    expect(ready.recipient.stamp.revision, 0);
    expect(ready.diplomacy.failure?.code, DiplomacyFailureCode.rejected);
    expect(
      ready.diplomacy.failure?.rejectionCode,
      DiplomacyRejectionCodeView.diplomacyTruceActive,
    );
  });
}

MapCoordinator _controller(FakeGameSession session) =>
    MapCoordinator(capabilities: testGameSessionCapabilities(session));

PlayerMapView _player({
  required int revision,
  required DiplomaticRelationStatusView status,
}) => PlayerMapView.preview(
  actorPlayerId: 'preview-player',
  stamp: testSessionStamp(revision: revision, stateDigest: 'd' * 64),
  turn: 1,
  pendingAction: null,
  units: const [],
  diplomacy: _diplomacy(status: status),
);

DiplomacyView _diplomacy({
  DiplomaticRelationStatusView status = DiplomaticRelationStatusView.neutral,
}) => DiplomacyView(
  relations: [
    DiplomaticRelationView(
      counterpartPlayerId: 'player-2',
      status: status,
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
