import 'package:aonw_flutter/features/local_game/application/local_handoff_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';

import 'map_handoff_gamepad_fixture.dart';

void main() {
  testWidgets('handoff captures controller input until a fresh confirmation', (
    tester,
  ) async {
    final h = await HandoffGamepadHarness.mount(tester);
    await h.press(tester, GamepadButton.a, hold: true);
    await h.handoff(tester);
    expect(h.ready.localHandoff.phase, LocalHandoffPhase.awaitingConfirmation);
    final camera = h.game.mapCamera.debugTransform!;
    final cursor = h.controller.cursor.value;
    h.axis(GamepadAxis.rightStickX, 1);
    h.axis(GamepadAxis.rightTrigger, 1);
    await tester.pump(const Duration(milliseconds: 600));
    expect(h.ready.localHandoff.blocksGameplay, isTrue);
    expect(h.game.mapCamera.debugTransform!.worldCenter, camera.worldCenter);
    expect(h.game.mapCamera.debugTransform!.zoom, camera.zoom);
    h.axis(GamepadAxis.rightStickX, 0);
    h.axis(GamepadAxis.rightTrigger, 0);
    h.setButton(GamepadButton.a, 0);
    await tester.pump();
    for (final button in [
      GamepadButton.b,
      GamepadButton.x,
      GamepadButton.y,
      GamepadButton.start,
      GamepadButton.dpadRight,
    ]) {
      await h.press(tester, button);
    }
    expect(h.ready.localHandoff.blocksGameplay, isTrue);
    expect(h.controller.cursor.value, cursor);
    expect(h.session.endTurnCalls, 1);
    await h.press(tester, GamepadButton.a, hold: true);
    expect(h.ready.localHandoff.phase, LocalHandoffPhase.idle);
    await tester.pump(const Duration(milliseconds: 600));
    expect(h.ready.interaction.selected, isNull);
    expect(h.session.endTurnCalls, 1);
    expect(h.settingsOpened, 0);
    h.setButton(GamepadButton.a, 0);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('handoff hides map semantics and traps keyboard focus', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final h = await HandoffGamepadHarness.mount(tester);
    await tester.tap(find.byKey(const ValueKey('open-settings')));
    expect(h.settingsOpened, 1);
    await h.handoff(tester);
    expect(h.ready.localHandoff.phase, LocalHandoffPhase.awaitingConfirmation);
    expect(find.bySemanticsLabel('Open settings'), findsNothing);
    for (var i = 0; i < 12; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(h.ready.localHandoff.blocksGameplay, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(h.ready.localHandoff.phase, LocalHandoffPhase.idle);
    expect(h.settingsOpened, 1);
    expect(h.session.endTurnCalls, 1);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
