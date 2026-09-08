import 'dart:async';

import 'package:aonw_flutter/app/navigation/aonw_app.dart';
import 'package:aonw_flutter/app/navigation/aonw_router.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/infrastructure/gamepad_map_input_source.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/settings/application/client_gamepad_settings.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:aonw_flutter/features/turns/read_model/pending_turn_actions_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';

import '../../support/map_test_fixture.dart';
import '../../support/recording_game_audio.dart';

void main() {
  testWidgets('app applies stored bindings to menu and updates them live', (
    tester,
  ) async {
    final h = _Harness();
    addTearDown(h.events.close);
    await h.settings.update(
      h.settings.settings.copyWith(
        gamepad: ClientGamepadSettings(
          bindings: GamepadBindings.defaults
              .bindButton(GamepadButtonAction.confirm, GamepadButtonControl.y)
              .bindButton(GamepadButtonAction.cancel, GamepadButtonControl.x),
        ),
      ),
    );
    await tester.pumpWidget(h.app());
    await tester.pumpAndSettle();
    await h.press(tester, GamepadButton.dpadDown);
    await h.press(tester, GamepadButton.a);
    expect(find.byKey(const ValueKey('main-menu-panel')), findsOneWidget);
    await h.press(tester, GamepadButton.y);
    expect(find.text('Play with the computer'), findsOneWidget);
    await h.press(tester, GamepadButton.x);
    expect(find.byKey(const ValueKey('main-menu-panel')), findsOneWidget);
    await h.settings.update(
      h.settings.settings.copyWith(gamepad: const ClientGamepadSettings()),
    );
    await tester.pumpAndSettle();
    await h.press(tester, GamepadButton.y);
    expect(find.byKey(const ValueKey('main-menu-panel')), findsOneWidget);
    await h.press(tester, GamepadButton.a);
    expect(find.text('Play with the computer'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'the same source dispatches a rebound primary action on the map',
    (tester) async {
      final h = _Harness();
      addTearDown(h.events.close);
      await h.settings.update(
        h.settings.settings.copyWith(
          gamepad: ClientGamepadSettings(
            bindings: GamepadBindings.defaults.bindButton(
              GamepadButtonAction.primaryAction,
              GamepadButtonControl.home,
            ),
          ),
        ),
      );
      await tester.pumpWidget(h.app(route: AonwRoute.map));
      await tester.pumpAndSettle();
      await h.press(tester, GamepadButton.start);
      expect(h.session.pendingTurnActionsRevisions, isEmpty);
      await h.press(tester, GamepadButton.home);
      expect(h.session.pendingTurnActionsRevisions, [0]);
      expect(
        (h.controller.state as GameSessionReady).interaction.selectedUnitId,
        'preview-commander',
      );
      expect(h.session.endTurnCalls, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}

final class _Harness {
  _Harness() {
    final scene = testMapScene(units: [testVisibleUnit()]);
    session = FakeGameSession.success(
      scene,
      reachableResult: testReachableView(),
    );
    session.pendingTurnActionsResult = PendingTurnActionsView(
      stamp: scene.player.stamp,
      actorPlayerId: scene.player.actorPlayerId,
      canActivate: true,
      actions: [
        const PendingUnitTurnActionView(
          unitId: 'preview-commander',
          coordinate: (col: 0, row: 0),
        ),
      ],
    );
    source = GamepadMapInputSource(events: events.stream);
    controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );
  }
  final settings = ClientSettingsController.ephemeral();
  final events = StreamController<NormalizedGamepadEvent>(sync: true);
  late final FakeGameSession session;
  late final GamepadMapInputSource source;
  late final MapPresentationController controller;
  final audio = RecordingGameAudio();

  Widget app({AonwRoute route = AonwRoute.menu}) => AonwApp(
    mapController: controller,
    mapInputSource: source,
    settingsController: settings,
    audio: audio,
    initialRoute: route,
  );

  Future<void> press(WidgetTester tester, GamepadButton button) async {
    void emit(double value) => events.add(
      NormalizedGamepadEvent(
        gamepadId: 'test-pad',
        timestamp: 1,
        button: button,
        value: value,
        rawEvent: GamepadEvent(
          gamepadId: 'test-pad',
          timestamp: 1,
          type: KeyType.button,
          key: button.name,
          value: value,
        ),
      ),
    );
    emit(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    emit(0);
    await tester.pumpAndSettle();
  }
}
