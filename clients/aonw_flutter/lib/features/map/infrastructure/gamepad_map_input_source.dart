import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gamepads/gamepads.dart';

import '../presentation/input/map_gamepad_input.dart';
import '../presentation/input/map_input.dart';

final class GamepadMapInputSource
    implements
        MapInputSource,
        ContinuousMapInputSource,
        LifecycleAwareMapInputSource {
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
  MapGamepadInput _continuousInput = MapGamepadInput.idle;
  String? _activeGamepadId;
  var _active = true;
  var _closed = false;

  @override
  Stream<MapInputCommand> get commands => const Stream.empty();

  @override
  Stream<MapGamepadInput> get continuousInputs => _continuousInputs.stream;

  void _onEvent(NormalizedGamepadEvent event) {
    if (_closed || !_active || !_accepts(event)) return;
    final next = _applyContinuousEvent(_continuousInput, event);
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
    _replaceContinuousInput(MapGamepadInput.idle);
    return true;
  }

  MapGamepadInput _applyContinuousEvent(
    MapGamepadInput input,
    NormalizedGamepadEvent event,
  ) {
    final axis = event.axis;
    if (axis != null) return _applyAxis(input, axis, event.value);
    final pressed = event.value != 0;
    final button = event.button;
    if (button == null) return input;
    return _applyButton(input, button, pressed);
  }

  MapGamepadInput _applyButton(
    MapGamepadInput input,
    GamepadButton button,
    bool pressed,
  ) {
    if (_isDpad(button)) return _applyDpadButton(input, button, pressed);
    if (_isTrigger(button)) return _applyTriggerButton(input, button, pressed);
    return _applyActionButton(input, button, pressed);
  }

  MapGamepadInput _applyActionButton(
    MapGamepadInput input,
    GamepadButton button,
    bool pressed,
  ) => switch (button) {
    GamepadButton.a => input.copyWith(activate: pressed),
    GamepadButton.b || GamepadButton.back => input.copyWith(cancel: pressed),
    GamepadButton.y => input.copyWith(toggleMapViewMode: pressed),
    _ => input,
  };

  MapGamepadInput _applyTriggerButton(
    MapGamepadInput input,
    GamepadButton button,
    bool pressed,
  ) => switch (button) {
    GamepadButton.rightTrigger => input.copyWith(zoomIn: pressed ? 1 : 0),
    GamepadButton.leftTrigger => input.copyWith(zoomOut: pressed ? 1 : 0),
    _ => input,
  };

  MapGamepadInput _applyDpadButton(
    MapGamepadInput input,
    GamepadButton button,
    bool pressed,
  ) => switch (button) {
    GamepadButton.dpadUp => input.copyWith(dpadUp: pressed),
    GamepadButton.dpadDown => input.copyWith(dpadDown: pressed),
    GamepadButton.dpadLeft => input.copyWith(dpadLeft: pressed),
    GamepadButton.dpadRight => input.copyWith(dpadRight: pressed),
    _ => input,
  };

  bool _isDpad(GamepadButton button) => switch (button) {
    GamepadButton.dpadUp ||
    GamepadButton.dpadDown ||
    GamepadButton.dpadLeft ||
    GamepadButton.dpadRight => true,
    _ => false,
  };

  bool _isTrigger(GamepadButton button) => switch (button) {
    GamepadButton.leftTrigger || GamepadButton.rightTrigger => true,
    _ => false,
  };

  MapGamepadInput _applyAxis(
    MapGamepadInput input,
    GamepadAxis axis,
    double value,
  ) => switch (axis) {
    GamepadAxis.leftStickX => input.copyWith(cursorX: value),
    GamepadAxis.leftStickY => input.copyWith(cursorY: value),
    GamepadAxis.rightStickX => input.copyWith(cameraX: value),
    GamepadAxis.rightStickY => input.copyWith(cameraY: value),
    GamepadAxis.rightTrigger => input.copyWith(zoomIn: value),
    GamepadAxis.leftTrigger => input.copyWith(zoomOut: value),
  };

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
    if (!active) _replaceContinuousInput(MapGamepadInput.idle);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _subscription.cancel();
    await _continuousInputs.close();
  }
}
