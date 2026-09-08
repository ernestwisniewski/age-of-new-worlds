import 'package:aonw_flutter/features/settings/application/client_gamepad_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults contain the reference actions and cancel aliases', () {
    final bindings = GamepadBindings.defaults;
    expect(bindings.buttons.values.toSet(), GamepadButtonAction.values.toSet());
    expect(bindings.axes.values.toSet(), GamepadAxisAction.values.toSet());
    expect(bindings.buttonsFor(GamepadButtonAction.cancel), [
      GamepadButtonControl.b,
      GamepadButtonControl.back,
    ]);
    expect(bindings.buttonsFor(GamepadButtonAction.primaryAction), [
      GamepadButtonControl.start,
    ]);
    expect(
      bindings.axisFor(GamepadAxisAction.cameraY),
      GamepadAxisControl.rightStickY,
    );
  });

  test(
    'button reassignment removes conflicts and supports explicit unbinding',
    () {
      final bindings = GamepadBindings.defaults.bindButton(
        GamepadButtonAction.confirm,
        GamepadButtonControl.b,
      );
      expect(bindings.buttonsFor(GamepadButtonAction.confirm), [
        GamepadButtonControl.b,
      ]);
      expect(bindings.buttonsFor(GamepadButtonAction.cancel), [
        GamepadButtonControl.back,
      ]);
      expect(bindings.buttons.containsKey(GamepadButtonControl.a), isFalse);
      final unbound = bindings.bindButton(GamepadButtonAction.cancel, null);
      expect(unbound.buttonsFor(GamepadButtonAction.cancel), isEmpty);
      expect(GamepadBindings.defaults.buttonsFor(GamepadButtonAction.confirm), [
        GamepadButtonControl.a,
      ]);
    },
  );

  test(
    'axis reassignment has no hidden fallback and reset preserves scalar options',
    () {
      final bindings = GamepadBindings.defaults.bindAxis(
        GamepadAxisAction.cameraX,
        GamepadAxisControl.leftStickX,
      );
      expect(bindings.axisFor(GamepadAxisAction.cursorX), isNull);
      expect(
        bindings.axisFor(GamepadAxisAction.cameraX),
        GamepadAxisControl.leftStickX,
      );
      expect(
        bindings.axes.containsKey(GamepadAxisControl.rightStickX),
        isFalse,
      );
      final settings = ClientGamepadSettings(
        enabled: false,
        deadzone: 0.5,
        bindings: bindings,
      );
      expect(
        settings.copyWith(bindings: GamepadBindings.defaults),
        const ClientGamepadSettings(enabled: false, deadzone: 0.5),
      );
      expect(
        bindings
            .bindAxis(GamepadAxisAction.cameraX, null)
            .axisFor(GamepadAxisAction.cameraX),
        isNull,
      );
    },
  );

  test('bindings are immutable values independent of map insertion order', () {
    final buttons = {GamepadButtonControl.a: GamepadButtonAction.confirm};
    final bindings = GamepadBindings(buttons: buttons, axes: {});
    buttons.clear();
    expect(bindings.buttons, hasLength(1));
    expect(() => bindings.buttons.clear(), throwsUnsupportedError);
    expect(() => bindings.axes.clear(), throwsUnsupportedError);
    final reverse = GamepadBindings(
      buttons: Map.fromEntries(
        GamepadBindings.defaults.buttons.entries.toList().reversed,
      ),
      axes: Map.fromEntries(
        GamepadBindings.defaults.axes.entries.toList().reversed,
      ),
    );
    expect(reverse, GamepadBindings.defaults);
    expect(reverse.hashCode, GamepadBindings.defaults.hashCode);
  });
}
