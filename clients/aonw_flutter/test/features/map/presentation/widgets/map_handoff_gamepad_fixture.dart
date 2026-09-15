import 'dart:async';

import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_session_port.dart';
import 'package:aonw_flutter/features/map/infrastructure/gamepad_map_input_source.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/turns/read_model/turn_activity_view.dart';
import 'package:aonw_flutter/features/turns/read_model/turn_command_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';

import '../../../../support/localized_test_app.dart';
import '../../../../support/map_test_fixture.dart';

final class HandoffGamepadHarness {
  HandoffGamepadHarness() {
    input = GamepadMapInputSource(events: events.stream);
    session = FakeGameSession.success(
      testMapScene(cols: 7, rows: 7).withPlayer(_player('player-1', 0)),
      turnResult: TurnCommandResultView.accepted(
        player: _player('player-1', 1),
        activities: const [],
        evidence: TurnKernelEvidenceView(
          processors: [],
          foundedCityIds: [],
          combatExecutionCount: 0,
          resetUnitIds: [],
          movementExecutionCount: 0,
          invalidatedOrderUnitIds: [],
          finishedAutoExploreUnitIds: [],
        ),
      ),
      handoffPlayers: {'player-2': _player('player-2', 1)},
    );
    controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );
  }

  final events = StreamController<NormalizedGamepadEvent>(sync: true);
  late final GamepadMapInputSource input;
  late final FakeGameSession session;
  late final MapPresentationController controller;
  final game = AonwFlameGame();
  var settingsOpened = 0;
  GameSessionReady get ready => controller.state as GameSessionReady;

  static Future<HandoffGamepadHarness> mount(WidgetTester tester) async {
    final harness = HandoffGamepadHarness();
    addTearDown(harness.controller.dispose);
    addTearDown(harness.input.close);
    addTearDown(harness.events.close);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await harness.controller.startLocalMatch(_entry, _setup);
    await tester.pumpWidget(
      LocalizedTestApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(1000, 800),
            disableAnimations: true,
          ),
          child: MapScreen(
            autoLoad: false,
            controller: harness.controller,
            inputSource: harness.input,
            flameGameFactory: () => harness.game,
            onOpenSettings: () => harness.settingsOpened++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return harness;
  }

  Future<void> handoff(WidgetTester tester) async {
    controller.endTurn();
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> press(
    WidgetTester tester,
    GamepadButton button, {
    bool hold = false,
  }) async {
    setButton(button, 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    if (!hold) {
      setButton(button, 0);
      await tester.pump();
    }
  }

  void setButton(GamepadButton button, double value) => events.add(
    NormalizedGamepadEvent(
      gamepadId: 'handoff-pad',
      timestamp: 1,
      button: button,
      value: value,
      rawEvent: GamepadEvent(
        gamepadId: 'handoff-pad',
        timestamp: 1,
        type: KeyType.button,
        key: button.name,
        value: value,
      ),
    ),
  );

  void axis(GamepadAxis axis, double value) => events.add(
    NormalizedGamepadEvent(
      gamepadId: 'handoff-pad',
      timestamp: 1,
      axis: axis,
      value: value,
      rawEvent: GamepadEvent(
        gamepadId: 'handoff-pad',
        timestamp: 1,
        type: KeyType.analog,
        key: axis.name,
        value: value,
      ),
    ),
  );
}

PlayerMapView _player(String actor, int revision) => PlayerMapView.preview(
  actorPlayerId: actor,
  stamp: testSessionStamp(revision: revision),
  turn: 7,
  pendingAction: null,
  units: const [],
);

const _entry = LocalGameCatalogEntryView(
  id: LocalGameScenarioView.starterDuel,
  mapId: 'aonw2_starter',
  rulesetId: 'ruleset',
  columns: 7,
  rows: 7,
  maximumPlayers: 2,
  assets: MapAssetPaths(
    document: 'map',
    bundleManifest: 'manifest',
    scenarioDocument: 'scenario',
    actorPlayerId: 'player-1',
  ),
  participantIds: ['player-1', 'player-2'],
);

final _setup = LocalMatchSetupView(
  assets: _entry.assets,
  fogEnabled: true,
  participants: [
    LocalParticipantSetupView(
      id: 'player-1',
      name: 'Player 1',
      colorValue: 0xff8b2424,
      country: LocalPlayerCountryView.poland,
      control: LocalPlayerControlView.human,
    ),
    LocalParticipantSetupView(
      id: 'player-2',
      name: 'Player 2',
      colorValue: 0xff24608b,
      country: LocalPlayerCountryView.japan,
      control: LocalPlayerControlView.human,
    ),
  ],
);
