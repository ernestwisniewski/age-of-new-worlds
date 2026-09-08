import 'package:aonw_flutter/features/settings/application/gamepad_bindings.dart';
import 'package:aonw_flutter/features/settings/infrastructure/gamepad_bindings_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round trip retains aliases, conflicts and every unbound action', () {
    final moved = GamepadBindings.defaults
        .bindButton(GamepadButtonAction.confirm, GamepadButtonControl.start)
        .bindAxis(GamepadAxisAction.cameraX, GamepadAxisControl.leftStickX);
    for (final bindings in [
      GamepadBindings.defaults,
      moved,
      GamepadBindings(buttons: {}, axes: {}),
    ]) {
      final restored = GamepadBindingsCodec.decode(
        GamepadBindingsCodec.encode(bindings),
      );
      expect(restored, bindings);
      expect(restored.hashCode, bindings.hashCode);
    }
    final restored = GamepadBindingsCodec.decode(
      GamepadBindingsCodec.encode(moved),
    );
    expect(restored.buttonsFor(GamepadButtonAction.primaryAction), isEmpty);
    expect(restored.axisFor(GamepadAxisAction.cursorX), isNull);
  });

  test('missing, malformed and unsupported documents use defaults', () {
    for (final value in <String?>[
      null,
      '',
      'null',
      '[]',
      '{',
      '{}',
      '{"version":2,"buttons":{},"axes":{}}',
      '{"version":1,"buttons":[],"axes":{}}',
      '{"version":1,"buttons":{},"axes":null}',
      '{"version":1,"buttons":{"unknown":"confirm"},"axes":{}}',
      '{"version":1,"buttons":{"a":"unknown"},"axes":{}}',
      '{"version":1,"buttons":{"a":7},"axes":{}}',
      '{"version":1,"buttons":{},"axes":{"leftStickX":"cameraX","rightStickX":"cameraX"}}',
    ]) {
      expect(
        GamepadBindingsCodec.decode(value),
        GamepadBindings.defaults,
        reason: value,
      );
    }
  });
}
