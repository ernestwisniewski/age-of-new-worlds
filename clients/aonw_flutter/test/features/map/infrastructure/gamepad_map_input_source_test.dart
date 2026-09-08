import 'dart:async';

import 'package:aonw_flutter/features/map/infrastructure/gamepad_map_input_source.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_gamepad_input.dart';
import 'package:aonw_flutter/features/settings/application/client_gamepad_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';

part 'gamepad_binding_input_test_cases.dart';

void main() {
  bindingInputTests();
  test('publishes action button state for frame-edge dispatch', () async {
    final events = StreamController<NormalizedGamepadEvent>(sync: true);
    final source = GamepadMapInputSource(events: events.stream);
    final inputs = <MapGamepadInput>[];
    final subscription = source.continuousInputs.listen(inputs.add);

    events.add(_button(GamepadButton.a, 1));
    expect(inputs.last.activate, isTrue);
    events.add(_button(GamepadButton.a, 0));
    expect(inputs.last, MapGamepadInput.idle);
    events.add(_button(GamepadButton.back, 1));
    expect(inputs.last.cancel, isTrue);
    events.add(_button(GamepadButton.back, 0));
    events.add(_button(GamepadButton.y, 1));
    expect(inputs.last.inspectHex, isTrue);

    await subscription.cancel();
    await source.close();
    await events.close();
  });

  test('maps stick clicks and bumpers to HUD focus edges', () async {
    final events = StreamController<NormalizedGamepadEvent>(sync: true);
    final source = GamepadMapInputSource(events: events.stream);
    final frames = MapGamepadFrameController();
    final inputs = <MapGamepadInput>[];
    final subscription = source.continuousInputs.listen(inputs.add);
    for (final button in [
      GamepadButton.leftStick,
      GamepadButton.rightStick,
      GamepadButton.leftBumper,
      GamepadButton.rightBumper,
    ]) {
      events.add(_button(button, 1));
      final pressed = frames.advance(input: inputs.last, dt: 0);
      final expected = switch (button) {
        GamepadButton.leftStick => pressed.hudFocusPreviousPressed,
        GamepadButton.rightStick => pressed.hudFocusNextPressed,
        GamepadButton.leftBumper => pressed.focusPreviousPressed,
        _ => pressed.focusNextPressed,
      };
      expect(expected, isTrue);
      expect(pressed.isIdle, isFalse);
      expect(frames.advance(input: inputs.last, dt: 1).hasFocusAction, isFalse);
      frames.prime(inputs.last);
      expect(frames.advance(input: inputs.last, dt: 1).hasFocusAction, isFalse);
      events.add(_button(button, 0));
      frames.advance(input: inputs.last, dt: 0);
    }
    await subscription.cancel();
    await source.close();
    await events.close();
  });

  test('X toggles once per press and is primed across input owners', () async {
    final events = StreamController<NormalizedGamepadEvent>(sync: true);
    final source = GamepadMapInputSource(events: events.stream);
    final inputs = <MapGamepadInput>[];
    final subscription = source.continuousInputs.listen(inputs.add);
    final frames = MapGamepadFrameController();
    events.add(_button(GamepadButton.x, 1));
    expect(inputs.last.toggleMoveTargeting, isTrue);
    expect(
      frames.advance(input: inputs.last, dt: 0).toggleMoveTargetingPressed,
      isTrue,
    );
    expect(
      frames.advance(input: inputs.last, dt: 1).toggleMoveTargetingPressed,
      isFalse,
    );
    frames.prime(inputs.last);
    expect(
      frames.advance(input: inputs.last, dt: 1).toggleMoveTargetingPressed,
      isFalse,
    );
    events.add(_button(GamepadButton.x, 0));
    frames.advance(input: inputs.last, dt: 0);
    expect(inputs.last, MapGamepadInput.idle);
    events.add(_button(GamepadButton.x, 1));
    expect(
      frames.advance(input: inputs.last, dt: 0).toggleMoveTargetingPressed,
      isTrue,
    );
    await subscription.cancel();
    await source.close();
    await events.close();
  });

  test('Start emits one primary action per press', () async {
    final events = StreamController<NormalizedGamepadEvent>(sync: true);
    final source = GamepadMapInputSource(events: events.stream);
    final inputs = <MapGamepadInput>[];
    final subscription = source.continuousInputs.listen(inputs.add);

    events.add(_button(GamepadButton.start, 1));
    final frames = MapGamepadFrameController();
    expect(inputs.single.primaryAction, isTrue);
    expect(
      frames.advance(input: inputs.last, dt: 0).primaryActionPressed,
      isTrue,
    );
    expect(
      frames.advance(input: inputs.last, dt: 1).primaryActionPressed,
      isFalse,
    );
    frames.prime(inputs.last);
    expect(
      frames.advance(input: inputs.last, dt: 1).primaryActionPressed,
      isFalse,
    );
    events.add(_button(GamepadButton.start, 0));
    frames.advance(input: inputs.last, dt: 0);
    events.add(_button(GamepadButton.start, 1));
    expect(
      frames.advance(input: inputs.last, dt: 0).primaryActionPressed,
      isTrue,
    );

    await subscription.cancel();
    await source.close();
    await events.close();
  });

  test('publishes the original stick, trigger and D-pad state', () async {
    final events = StreamController<NormalizedGamepadEvent>(sync: true);
    final source = GamepadMapInputSource(events: events.stream);
    final inputs = <MapGamepadInput>[];
    final subscription = source.continuousInputs.listen(inputs.add);

    events.add(_axis(GamepadAxis.leftStickY, 0.7));
    events.add(_axis(GamepadAxis.rightStickX, -0.6));
    events.add(_axis(GamepadAxis.rightTrigger, 0.8));
    events.add(_button(GamepadButton.dpadLeft, 1));

    expect(
      inputs.last,
      const MapGamepadInput(
        cursorY: 0.7,
        cameraX: -0.6,
        zoomIn: 0.8,
        dpadLeft: true,
      ),
    );

    events.add(_button(GamepadButton.dpadLeft, 0));
    expect(inputs.last.dpadLeft, isFalse);

    await subscription.cancel();
    await source.close();
    await events.close();
  });

  test(
    'clears held continuous input when lifecycle becomes inactive',
    () async {
      final events = StreamController<NormalizedGamepadEvent>(sync: true);
      final source = GamepadMapInputSource(events: events.stream);
      final inputs = <MapGamepadInput>[];
      final subscription = source.continuousInputs.listen(inputs.add);

      events.add(_axis(GamepadAxis.rightStickY, 1));
      source.setActive(false);

      expect(inputs, [const MapGamepadInput(cameraY: 1), MapGamepadInput.idle]);

      await subscription.cancel();
      await source.close();
      await events.close();
    },
  );

  test('drops gamepad events while lifecycle input is inactive', () async {
    final events = StreamController<NormalizedGamepadEvent>(sync: true);
    final source = GamepadMapInputSource(events: events.stream);
    final inputs = <MapGamepadInput>[];
    final subscription = source.continuousInputs.listen(inputs.add);
    final event = _button(GamepadButton.a, 1);

    source.setActive(false);
    events.add(event);
    expect(inputs, isEmpty);

    source.setActive(true);
    events.add(event);
    expect(inputs, [const MapGamepadInput(activate: true)]);

    await subscription.cancel();
    await source.close();
    await events.close();
  });
}

NormalizedGamepadEvent _axis(GamepadAxis axis, double value) =>
    NormalizedGamepadEvent(
      gamepadId: 'pad-1',
      timestamp: 1,
      axis: axis,
      value: value,
      rawEvent: GamepadEvent(
        gamepadId: 'pad-1',
        timestamp: 1,
        type: KeyType.analog,
        key: axis.name,
        value: value,
      ),
    );

NormalizedGamepadEvent _button(GamepadButton button, double value) =>
    NormalizedGamepadEvent(
      gamepadId: 'pad-1',
      timestamp: 1,
      button: button,
      value: value,
      rawEvent: GamepadEvent(
        gamepadId: 'pad-1',
        timestamp: 1,
        type: KeyType.button,
        key: button.name,
        value: value,
      ),
    );
