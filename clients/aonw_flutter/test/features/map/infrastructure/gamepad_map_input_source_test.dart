import 'dart:async';

import 'package:aonw_flutter/features/map/infrastructure/gamepad_map_input_source.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';

void main() {
  test('maps pressed standard gamepad buttons to map input commands', () {
    expect(
      MapGamepadMapper.commandFor(GamepadButton.dpadUp, 1),
      MapInputCommand.cursorUp,
    );
    expect(
      MapGamepadMapper.commandFor(GamepadButton.a, 1),
      MapInputCommand.activate,
    );
    expect(
      MapGamepadMapper.commandFor(GamepadButton.b, 1),
      MapInputCommand.cancel,
    );
    expect(
      MapGamepadMapper.commandFor(GamepadButton.y, 1),
      MapInputCommand.toggleReference,
    );
  });

  test('ignores releases and unrelated buttons', () {
    expect(MapGamepadMapper.commandFor(GamepadButton.a, 0), isNull);
    expect(MapGamepadMapper.commandFor(GamepadButton.leftBumper, 1), isNull);
    expect(MapGamepadMapper.commandFor(null, 1), isNull);
  });

  test('drops gamepad events while lifecycle input is inactive', () async {
    final events = StreamController<NormalizedGamepadEvent>(sync: true);
    final source = GamepadMapInputSource(events: events.stream);
    final commands = <MapInputCommand>[];
    final subscription = source.commands.listen(commands.add);
    final event = NormalizedGamepadEvent(
      gamepadId: 'pad-1',
      timestamp: 1,
      button: GamepadButton.a,
      value: 1,
      rawEvent: GamepadEvent(
        gamepadId: 'pad-1',
        timestamp: 1,
        type: KeyType.button,
        key: 'a',
        value: 1,
      ),
    );

    source.setActive(false);
    events.add(event);
    expect(commands, isEmpty);

    source.setActive(true);
    events.add(event);
    expect(commands, [MapInputCommand.activate]);

    await subscription.cancel();
    await source.close();
    await events.close();
  });
}
