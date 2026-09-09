import 'dart:async';

import 'package:aonw_flutter/features/local_game/application/local_handoff_state.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/hex_inspection_session_port.dart';
import 'package:aonw_flutter/features/map/application/hex_inspection_state.dart';
import 'package:aonw_flutter/features/map/application/hex_inspection_workflow.dart';
import 'package:aonw_flutter/features/map/application/map_coordinator.dart';
import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/read_model/hex_inspection_view.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/hex_inspection_test_fixture.dart';
import '../../../support/map_test_fixture.dart';

void main() {
  test(
    'inspection preserves selection, movement targeting and route',
    () async {
      final harness = _Harness();
      final interaction = MapInteractionState(
        selected: (col: 1, row: 0),
        selectedUnitId: 'preview-commander',
        moveTargeting: true,
        route: testRoutePlanView(),
      );
      harness.state = harness.ready.withInteraction(interaction);
      final request = harness.inspect((col: 2, row: 0));
      expect(harness.ready.inspection, isA<HexInspectionLoading>());
      expect(harness.ready.interaction, same(interaction));
      harness.complete(0, (col: 2, row: 0));
      await request;
      expect((harness.ready.inspection as HexInspectionReady).view.coordinate, (
        col: 2,
        row: 0,
      ));
      expect(harness.ready.interaction, same(interaction));
      harness.close();
      expect(harness.ready.inspection, isNull);
      expect(harness.ready.interaction, same(interaction));
    },
  );

  test('later inspection wins regardless of response order', () async {
    final harness = _Harness();
    final first = harness.inspect((col: 0, row: 0));
    final second = harness.inspect((col: 1, row: 0));
    harness.complete(1, (col: 1, row: 0));
    await second;
    final latest = harness.ready.inspection;
    harness.complete(0, (col: 0, row: 0));
    await first;
    expect(harness.ready.inspection, same(latest));
  });

  test(
    'close and dispose discard both late success and late failure',
    () async {
      for (final dispose in [false, true]) {
        for (final failure in [false, true]) {
          final harness = _Harness();
          final request = harness.inspect((col: 0, row: 0));
          if (dispose) {
            harness.disposed = true;
          } else {
            harness.close();
          }
          final before = harness.state;
          if (failure) {
            harness.pending[0].completeError(StateError('late'));
          } else {
            harness.complete(0, (col: 0, row: 0));
          }
          await request;
          expect(harness.state, same(before));
          expect(harness.diagnostics, isEmpty);
        }
      }
    },
  );

  test(
    'every recipient identity change invalidates loaded and pending inspection',
    () async {
      for (final player in _differentRecipients()) {
        final harness = _Harness();
        final request = harness.inspect((col: 0, row: 0));
        harness.state = harness.ready.withRecipient(player);
        expect(harness.ready.inspection, isNull);
        harness.complete(0, (col: 0, row: 0));
        await request;
        expect(harness.ready.inspection, isNull);
        final loaded = HexInspectionReady(
          testHexInspectionView(scene: harness.scene),
        );
        final original = GameSessionReady.initial(
          harness.scene,
        ).withInspection(loaded);
        expect(original.withRecipient(player).inspection, isNull);
        expect(
          original.withRecipient(harness.scene.player).inspection,
          same(loaded),
        );
      }
    },
  );

  test(
    'map replacement and handoff discard pending private profiles',
    () async {
      for (final handoff in [false, true]) {
        final harness = _Harness();
        final request = harness.inspect((col: 0, row: 0));
        harness.state = handoff
            ? harness.ready.withLocalHandoff(
                const LocalHandoffState.switching(
                  playerId: 'other',
                  playerName: 'Other',
                ),
              )
            : GameSessionReady.initial(testMapScene(mapId: 'replacement'));
        harness.complete(0, (col: 0, row: 0));
        await request;
        expect(harness.ready.inspection, isNull);
      }
    },
  );

  test('out-of-map requests do not disturb an existing inspection', () async {
    final harness = _Harness();
    final first = harness.inspect((col: 0, row: 0));
    final before = harness.state;
    await harness.inspect((col: 99, row: 0));
    expect(harness.state, same(before));
    expect(harness.pending, hasLength(1));
    harness.complete(0, (col: 0, row: 0));
    await first;
  });

  test(
    'wrong response coordinate and fingerprint fail as incompatible',
    () async {
      for (final wrongCoordinate in [false, true]) {
        final harness = _Harness();
        final request = harness.inspect((col: 0, row: 0));
        final scene = wrongCoordinate
            ? harness.scene
            : harness.scene.withPlayer(_player(digest: 'd' * 64));
        harness.pending[0].complete(
          testHexInspectionView(
            scene: scene,
            coordinate: wrongCoordinate ? (col: 1, row: 0) : (col: 0, row: 0),
          ),
        );
        await request;
        expect(
          (harness.ready.inspection as HexInspectionFailure).code,
          HexInspectionFailureCode.responseIncompatible,
        );
      }
    },
  );

  test(
    'resync updates the recipient and leaves the old inspection closed',
    () async {
      final harness = _Harness();
      final request = harness.inspect((col: 0, row: 0));
      final next = _player(revision: 1);
      harness.pending[0].completeError(
        HexInspectionSessionException(
          code: 'recipient_resynchronized',
          message: 'resync',
          resyncedPlayer: next,
        ),
      );
      await request;
      expect(harness.ready.recipient, same(next));
      expect(harness.ready.inspection, isNull);
    },
  );

  test('foreign resync is rejected without switching the recipient', () async {
    final harness = _Harness();
    final request = harness.inspect((col: 0, row: 0));
    harness.pending[0].completeError(
      HexInspectionSessionException(
        code: 'recipient_resynchronized',
        message: 'foreign',
        resyncedPlayer: _player(actor: 'other'),
      ),
    );
    await request;
    expect(harness.ready.recipient, same(harness.scene.player));
    expect(
      (harness.ready.inspection as HexInspectionFailure).code,
      HexInspectionFailureCode.responseIncompatible,
    );
  });

  test(
    'coordinator uses the required port and B only dismisses inspection',
    () async {
      final scene = testMapScene(units: [testVisibleUnit()]);
      final inspection = FakeHexInspectionSession(scene: scene);
      final controller = MapCoordinator(
        capabilities: testGameSessionCapabilities(
          FakeGameSession.success(scene),
          cityPlanning: FakeCityPlanningSession(),
          hexInspection: inspection,
        ),
      );
      addTearDown(controller.dispose);
      await controller.load();
      controller.selectUnit('preview-commander');
      await Future<void>.delayed(Duration.zero);
      final selected = (controller.state as GameSessionReady).interaction;
      expect(selected.selectedUnitId, 'preview-commander');
      controller.inspectHex((col: 2, row: 0));
      await Future<void>.delayed(Duration.zero);
      expect(
        (controller.state as GameSessionReady).inspection,
        isA<HexInspectionReady>(),
      );
      expect(inspection.requests.single.coordinate, (col: 2, row: 0));
      controller.cancelInteraction();
      final ready = controller.state as GameSessionReady;
      expect(ready.inspection, isNull);
      expect(ready.interaction, same(selected));
    },
  );
}

final class _Harness {
  _Harness() {
    state = GameSessionReady.initial(scene);
    workflow = HexInspectionWorkflow(
      session: FakeHexInspectionSession(
        scene: scene,
        onInspect: (_, _) {
          final completer = Completer<HexInspectionView>();
          pending.add(completer);
          return completer.future;
        },
      ),
      diagnosticReporter: (code, _, _) => diagnostics.add(code),
    );
  }
  final scene = testMapScene();
  late GameSessionState state;
  late final HexInspectionWorkflow workflow;
  final pending = <Completer<HexInspectionView>>[];
  final diagnostics = <String>[];
  var disposed = false;
  GameSessionReady get ready => state as GameSessionReady;
  Future<void> inspect(MapHexCoordinate coordinate) => workflow.inspect(
    coordinate: coordinate,
    readState: () => state,
    publish: (value) => state = value,
    isDisposed: () => disposed,
  );
  void close() =>
      workflow.close(readState: () => state, publish: (value) => state = value);
  void complete(int index, MapHexCoordinate coordinate) => pending[index]
      .complete(testHexInspectionView(scene: scene, coordinate: coordinate));
}

Iterable<PlayerMapView> _differentRecipients() => [
  _player(actor: 'other'),
  _player(revision: 1),
  _player(digest: 'd' * 64),
  _player(mapHash: 'd' * 64),
  _player(rulesetHash: 'd' * 64),
];
PlayerMapView _player({
  String actor = 'preview-player',
  int revision = 0,
  String? digest,
  String? mapHash,
  String? rulesetHash,
}) => PlayerMapView.preview(
  actorPlayerId: actor,
  stamp: SessionStampView(
    revision: revision,
    stateDigest: digest ?? 'b' * 64,
    mapHash: mapHash ?? 'a' * 64,
    rulesetHash: rulesetHash ?? 'c' * 64,
  ),
  turn: 1,
  pendingAction: null,
  units: const [],
);
