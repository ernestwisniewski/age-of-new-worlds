import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gamepads/gamepads.dart';

import '../../settings/application/client_gamepad_settings.dart';
import '../../settings/application/configurable_gamepad_input.dart';
import '../presentation/input/map_gamepad_input.dart';
import '../presentation/input/map_input.dart';
import 'gamepad_binding_mapper.dart';

final class GamepadMapInputSource
    implements
        MapInputSource,
        ContinuousMapInputSource,
        LifecycleAwareMapInputSource,
        ConfigurableGamepadInput {
  GamepadMapInputSource({Stream<NormalizedGamepadEvent>? events}) {
    _subscription = (events ?? Gamepads.normalizedEvents).listen(
      _onEvent,
      onError: _onError,
    );
  }

  final _continuousInputs = StreamController<MapGamepadInput>.broadcast(
    sync: true,
  );
  late final StreamSubscription<NormalizedGamepadEvent> _subscription;
  final _bindings = GamepadBindingMapper();
  MapGamepadInput _continuousInput = MapGamepadInput.idle;
  String? _activeGamepadId;
  var _active = true;
  var _closed = false;

  @override
  Stream<MapInputCommand> get commands => const Stream.empty();

  @override
  Stream<MapGamepadInput> get continuousInputs => _continuousInputs.stream;

  void _onEvent(NormalizedGamepadEvent event) {
    if (_closed || !_active || !event.value.isFinite || !_accepts(event)) {
      return;
    }
    final next = _applyContinuousEvent(event);
    if (next == _continuousInput) return;
    _continuousInput = next;
    _continuousInputs.add(next);
  }

  bool _accepts(NormalizedGamepadEvent event) {
    final current = _activeGamepadId;
    if (current == null) {
      _activeGamepadId = event.gamepadId;
      return true;
    }
    if (current == event.gamepadId) return true;
    if (event.value.abs() <= 0.5) return false;
    _activeGamepadId = event.gamepadId;
    _bindings.reset();
    _replaceContinuousInput(MapGamepadInput.idle);
    return true;
  }

  MapGamepadInput _applyContinuousEvent(NormalizedGamepadEvent event) {
    if (event.axis case final axis?) {
      return _bindings.axis(_axisControls[axis]!, event.value);
    }
    if (event.button case final button?) {
      return _bindings.button(_buttonControls[button]!, event.value != 0);
    }
    return _continuousInput;
  }

  @override
  void configureGamepad(ClientGamepadSettings settings) {
    if (_closed) return;
    if (_bindings.configure(settings)) {
      _replaceContinuousInput(MapGamepadInput.idle);
    }
  }

  void _replaceContinuousInput(MapGamepadInput input) {
    if (_continuousInput == input) return;
    _continuousInput = input;
    if (!_closed) _continuousInputs.add(input);
  }

  void _onError(Object error, StackTrace stackTrace) {
    debugPrintStack(
      label: 'Gamepad input unavailable: $error',
      stackTrace: stackTrace,
    );
  }

  @override
  void setActive(bool active) {
    if (_closed || _active == active) return;
    _active = active;
    if (!active) {
      _bindings.reset();
      _replaceContinuousInput(MapGamepadInput.idle);
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _subscription.cancel();
    await _continuousInputs.close();
  }
}

const _buttonControls = {
  GamepadButton.a: GamepadButtonControl.a,
  GamepadButton.b: GamepadButtonControl.b,
  GamepadButton.x: GamepadButtonControl.x,
  GamepadButton.y: GamepadButtonControl.y,
  GamepadButton.leftBumper: GamepadButtonControl.leftBumper,
  GamepadButton.rightBumper: GamepadButtonControl.rightBumper,
  GamepadButton.leftTrigger: GamepadButtonControl.leftTrigger,
  GamepadButton.rightTrigger: GamepadButtonControl.rightTrigger,
  GamepadButton.back: GamepadButtonControl.back,
  GamepadButton.start: GamepadButtonControl.start,
  GamepadButton.home: GamepadButtonControl.home,
  GamepadButton.leftStick: GamepadButtonControl.leftStick,
  GamepadButton.rightStick: GamepadButtonControl.rightStick,
  GamepadButton.dpadUp: GamepadButtonControl.dpadUp,
  GamepadButton.dpadDown: GamepadButtonControl.dpadDown,
  GamepadButton.dpadLeft: GamepadButtonControl.dpadLeft,
  GamepadButton.dpadRight: GamepadButtonControl.dpadRight,
  GamepadButton.touchpad: GamepadButtonControl.touchpad,
};

const _axisControls = {
  GamepadAxis.leftStickX: GamepadAxisControl.leftStickX,
  GamepadAxis.leftStickY: GamepadAxisControl.leftStickY,
  GamepadAxis.rightStickX: GamepadAxisControl.rightStickX,
  GamepadAxis.rightStickY: GamepadAxisControl.rightStickY,
  GamepadAxis.leftTrigger: GamepadAxisControl.leftTrigger,
  GamepadAxis.rightTrigger: GamepadAxisControl.rightTrigger,
};
