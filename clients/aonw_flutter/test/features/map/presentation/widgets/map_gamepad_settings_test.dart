import 'dart:async';

import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_gamepad_input.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/features/settings/application/client_gamepad_settings.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_scope.dart';
import 'package:aonw_flutter/features/turns/read_model/pending_turn_actions_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';
import '../../../../support/map_test_fixture.dart';
import '../../../../support/test_map_input_source.dart';

void main() {
  testWidgets(
    'disabled input stops map actions and camera; enabling primes held A',
    (tester) async {
      final h = await _Harness.mount(
        tester,
        const ClientGamepadSettings(enabled: false),
      );
      final center = h.game.mapCamera.debugTransform!.worldCenter;
      await h.inputFrame(
        tester,
        const MapGamepadInput(activate: true, primaryAction: true, cameraX: 1),
      );
      await tester.pumpAndSettle();
      expect(h.ready.interaction.selected, isNull);
      expect(h.session.pendingTurnActionsRevisions, isEmpty);
      expect(h.game.mapCamera.debugTransform!.worldCenter, center);
      await h.inputFrame(tester, const MapGamepadInput(activate: true));
      await h.configure(tester, const ClientGamepadSettings());
      await tester.pump(const Duration(milliseconds: 400));
      expect(h.ready.interaction.selected, isNull);
      await h.inputFrame(tester, MapGamepadInput.idle);
      await h.inputFrame(tester, const MapGamepadInput(activate: true));
      expect(h.ready.interaction.selected, isNotNull);
      await h.inputFrame(tester, MapGamepadInput.idle);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'map applies independent camera sensitivity, inversion and deadzone',
    (tester) async {
      final h = await _Harness.mount(
        tester,
        const ClientGamepadSettings(
          deadzone: 0.5,
          cameraSensitivity: 0.8,
          invertCameraY: true,
        ),
      );
      final before = h.game.mapCamera.debugTransform!.worldCenter;
      await h.inputFrame(
        tester,
        const MapGamepadInput(cursorX: 0.4, cameraY: 0.4),
      );
      expect(h.ready.interaction.selected, isNull);
      expect(h.game.mapCamera.debugTransform!.worldCenter, before);
      await h.inputFrame(tester, MapGamepadInput.idle);
      await h.inputFrame(tester, const MapGamepadInput(cameraY: 0.75));
      final after = h.game.mapCamera.debugTransform!.worldCenter;
      expect(after.y - before.y, closeTo(-8.32, 0.01));
      expect(after.x, before.x);
      await h.inputFrame(tester, MapGamepadInput.idle);
    },
  );

  testWidgets('changing gamepad settings cancels a pending primary action', (
    tester,
  ) async {
    final h = await _Harness.mount(tester, const ClientGamepadSettings());
    final response = Completer<PendingTurnActionsView>();
    h.session.pendingTurnActionsHandler = (_) => response.future;
    await h.inputFrame(tester, const MapGamepadInput(primaryAction: true));
    expect(h.session.pendingTurnActionsRevisions, [0]);
    await h.configure(tester, const ClientGamepadSettings(enabled: false));
    await h.configure(tester, const ClientGamepadSettings());
    response.complete(
      PendingTurnActionsView(
        stamp: h.ready.recipient.stamp,
        actorPlayerId: h.ready.recipient.actorPlayerId,
        canActivate: true,
        actions: [],
      ),
    );
    await h.inputFrame(tester, MapGamepadInput.idle);
    await tester.pumpAndSettle();
    expect(h.session.endTurnCalls, 0);
  });
}

final class _Harness {
  _Harness() {
    session = FakeGameSession.success(testMapScene(cols: 10, rows: 8));
    controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );
  }
  final settings = ClientSettingsController.ephemeral();
  final input = TestMapInputSource();
  final game = AonwFlameGame();
  late final FakeGameSession session;
  late final MapPresentationController controller;
  GameSessionReady get ready => controller.state as GameSessionReady;

  static Future<_Harness> mount(
    WidgetTester tester,
    ClientGamepadSettings gamepad,
  ) async {
    final h = _Harness();
    addTearDown(h.controller.dispose);
    addTearDown(h.settings.dispose);
    addTearDown(h.input.close);
    await h.settings.update(
      h.settings.settings.copyWith(cameraSensitivity: 1.5, gamepad: gamepad),
    );
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      LocalizedTestApp(
        home: ClientSettingsScope(
          controller: h.settings,
          child: Scaffold(
            body: MapScreen(
              controller: h.controller,
              inputSource: h.input,
              flameGameFactory: () => h.game,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return h;
  }

  Future<void> configure(
    WidgetTester tester,
    ClientGamepadSettings gamepad,
  ) async {
    await settings.update(settings.settings.copyWith(gamepad: gamepad));
    await tester.pump();
    await tester.pump();
  }

  Future<void> inputFrame(WidgetTester tester, MapGamepadInput value) async {
    input.addContinuous(value);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
  }
}
