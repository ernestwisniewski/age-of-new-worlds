import 'package:aonw_flutter/features/audio/application/game_audio_port.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/workers/application/worker_state.dart';
import 'package:aonw_flutter/features/workers/application/worker_workflow.dart';
import 'package:aonw_flutter/features/workers/read_model/worker_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  test(
    'only explicit successful opening sounds; preview and cancel stay local',
    () async {
      final (controller, session) = _controller();
      final sounds = <GameSoundCue>[];
      controller.bindInteractionSounds(sounds.add);
      await controller.load();
      controller.setWorkerActionsOpen(true);
      expect(sounds, isEmpty);
      controller.selectUnit('preview-commander');
      await pumpEventQueue();
      expect(sounds, isEmpty);
      final initial = controller.state as GameSessionReady;
      controller.previewWorkerImprovement(
        'preview-commander',
        FieldImprovementKind.farm,
      );
      controller.executeWorkerAction(_confirm());
      expect(session.workerCommandCalls, 0);
      expect(controller.state, same(initial));
      controller.setWorkerActionsOpen(true);
      controller.setWorkerActionsOpen(true);
      expect(sounds, [GameSoundCue.uiPanelOpen]);
      controller.previewWorkerImprovement('missing', FieldImprovementKind.farm);
      controller.previewWorkerImprovement(
        'preview-commander',
        FieldImprovementKind.mine,
      );
      expect(_worker(controller).previewedImprovement, isNull);
      controller.previewWorkerImprovement(
        'preview-commander',
        FieldImprovementKind.farm,
      );
      expect(
        _worker(controller).previewedImprovement,
        FieldImprovementKind.farm,
      );
      controller.setWorkerActionsOpen(false);
      expect(_worker(controller).actionsOpen, isFalse);
      expect(_worker(controller).previewedImprovement, isNull);
      controller.executeWorkerAction(_confirm());
      controller.setWorkerActionsOpen(true);
      expect(_worker(controller).previewedImprovement, isNull);
      expect(sounds, [GameSoundCue.uiPanelOpen, GameSoundCue.uiPanelOpen]);
      expect(session.workerCommandCalls, 0);
      expect(
        (controller.state as GameSessionReady).recipient,
        same(initial.recipient),
      );
    },
  );

  test(
    'reselection drops the preview and rejects stale confirmation',
    () async {
      final (controller, session) = _controller();
      await controller.load();
      controller.selectUnit('preview-commander');
      await pumpEventQueue();
      controller.setWorkerActionsOpen(true);
      controller.previewWorkerImprovement(
        'preview-commander',
        FieldImprovementKind.farm,
      );
      controller.select(null);
      controller.executeWorkerAction(_confirm());
      controller.selectUnit('preview-commander');
      await pumpEventQueue();
      expect(_worker(controller).actionsOpen, isFalse);
      controller.executeWorkerAction(_confirm());
      expect(session.workerCommandCalls, 0);
    },
  );

  for (final change in ['revision', 'digest', 'actor', 'map', 'ruleset']) {
    test('recipient $change invalidates preview and stale options', () {
      final unit = testVisibleUnit(kind: VisibleUnitKind.worker);
      final scene = testMapScene(units: [unit]);
      final session = FakeGameSession.success(scene);
      var state = GameSessionReady.initial(scene).withInteraction(
        MapInteractionState(
          selectedUnitId: unit.id,
          worker: WorkerState(
            unitId: unit.id,
            options: _options(unit),
            actionsOpen: true,
            previewedImprovement: FieldImprovementKind.farm,
          ),
        ),
      );
      state = state.withRecipient(
        PlayerMapView.preview(
          pendingAction: null,
          actorPlayerId: change == 'actor'
              ? 'other'
              : scene.player.actorPlayerId,
          stamp: SessionStampView(
            revision: change == 'revision' ? 1 : 0,
            stateDigest: change == 'digest'
                ? 'changed'
                : scene.player.stamp.stateDigest,
            mapHash: change == 'map'
                ? 'changed-map'
                : scene.player.stamp.mapHash,
            rulesetHash: change == 'ruleset'
                ? 'changed-ruleset'
                : scene.player.stamp.rulesetHash,
          ),
          turn: 1,
          units: [unit],
        ),
      );
      expect(state.interaction.worker?.actionsOpen, isFalse);
      expect(state.interaction.worker?.previewedImprovement, isNull);
      final workflow = WorkerWorkflow(
        session: session,
        diagnosticReporter: (_, _, _) {},
      );
      workflow.setActionsOpen(
        unitId: unit.id,
        open: true,
        readState: () => state,
        publish: (value) => state = value,
      );
      workflow.execute(
        action: _confirm(),
        readState: () => state,
        publish: (value) => state = value,
        isDisposed: () => false,
      );
      expect(state.interaction.worker?.actionsOpen, isFalse);
      expect(session.workerCommandCalls, 0);
    });
  }

  for (final preview in [
    FieldImprovementKind.farm,
    FieldImprovementKind.mine,
  ]) {
    test(
      'restores a recipient worker selection with queried options ($preview)',
      () async {
        final unit = testVisibleUnit(kind: VisibleUnitKind.worker);
        final session = FakeGameSession.success(
          testMapScene(
            units: [unit],
            pendingAction: PendingWorkerActionSelectionView(
              unitId: unit.id,
              improvement: preview,
            ),
          ),
          reachableResult: testReachableView(unitId: unit.id),
          workerOptionsResult: _options(unit),
        );
        final controller = MapPresentationController(
          capabilities: testGameSessionCapabilities(session),
        );
        addTearDown(controller.dispose);
        final sounds = <GameSoundCue>[];
        controller.bindInteractionSounds(sounds.add);
        await controller.load();
        controller.selectUnit(unit.id);
        await pumpEventQueue();
        expect(_worker(controller).actionsOpen, isTrue);
        expect(
          _worker(controller).previewedImprovement,
          preview == FieldImprovementKind.farm ? preview : isNull,
        );
        expect(sounds, isEmpty);
        expect(session.workerCommandCalls, 0);
      },
    );
  }

  test('a busy worker cannot open improvement selection', () async {
    final (controller, session) = _controller(
      job: const FieldImprovementJobView(
        target: (col: 0, row: 0),
        improvement: FieldImprovementKind.farm,
        remainingTurns: 2,
        totalTurns: 3,
      ),
    );
    await controller.load();
    controller.selectUnit('preview-commander');
    await pumpEventQueue();
    controller.setWorkerActionsOpen(true);
    expect(_worker(controller).actionsOpen, isFalse);
    expect(session.workerCommandCalls, 0);
  });
}

(MapPresentationController, FakeGameSession) _controller({WorkerJobView? job}) {
  final unit = testVisibleUnit(kind: VisibleUnitKind.worker, workerJob: job);
  final session = FakeGameSession.success(
    testMapScene(units: [unit]),
    reachableResult: testReachableView(unitId: unit.id),
    workerOptionsResult: _options(unit),
  );
  final controller = MapPresentationController(
    capabilities: testGameSessionCapabilities(session),
  );
  addTearDown(controller.dispose);
  return (controller, session);
}

WorkerState _worker(MapPresentationController controller) =>
    (controller.state as GameSessionReady).interaction.worker!;

ConfirmWorkerImprovementActionView _confirm() =>
    const ConfirmWorkerImprovementActionView(
      unitId: 'preview-commander',
      improvement: FieldImprovementKind.farm,
    );

WorkerOptionsView _options(VisibleUnitView unit) => WorkerOptionsView(
  stamp: testSessionStamp(),
  unitId: unit.id,
  coordinate: unit.coordinate,
  improvements: const [
    WorkerImprovementOptionView(
      improvement: FieldImprovementKind.farm,
      buildTurns: 3,
    ),
  ],
  canAssign: false,
  canBuildRoad: false,
  automation: null,
);
