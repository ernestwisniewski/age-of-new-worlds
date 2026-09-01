import 'dart:async';

import 'package:aonw_flutter/features/map/infrastructure/gamepad_map_input_source.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_gamepad_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';

void main() {
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
    expect(inputs.last.toggleMapViewMode, isTrue);

    await subscription.cancel();
    await source.close();
    await events.close();
  });

  test('ignores unrelated button state', () async {
    final events = StreamController<NormalizedGamepadEvent>(sync: true);
    final source = GamepadMapInputSource(events: events.stream);
    final inputs = <MapGamepadInput>[];
    final subscription = source.continuousInputs.listen(inputs.add);

    events.add(_button(GamepadButton.leftBumper, 1));
    expect(inputs, isEmpty);

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
