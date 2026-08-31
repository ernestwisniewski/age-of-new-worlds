import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gamepads/gamepads.dart';

import '../presentation/input/map_input.dart';

abstract final class MapGamepadMapper {
  static const _commands = <GamepadButton, MapInputCommand>{
    GamepadButton.dpadUp: MapInputCommand.cursorUp,
    GamepadButton.dpadDown: MapInputCommand.cursorDown,
    GamepadButton.dpadLeft: MapInputCommand.cursorLeft,
    GamepadButton.dpadRight: MapInputCommand.cursorRight,
    GamepadButton.a: MapInputCommand.activate,
    GamepadButton.b: MapInputCommand.cancel,
    GamepadButton.y: MapInputCommand.toggleReference,
  };

  static MapInputCommand? commandFor(GamepadButton? button, double value) {
    if (button == null || value < 0.5) return null;
    return _commands[button];
  }
}

final class GamepadMapInputSource
    implements MapInputSource, LifecycleAwareMapInputSource {
  GamepadMapInputSource({Stream<NormalizedGamepadEvent>? events}) {
    _subscription = (events ?? Gamepads.normalizedEvents).listen(
      _onEvent,
      onError: _onError,
    );
  }

  final _commands = StreamController<MapInputCommand>.broadcast(sync: true);
  late final StreamSubscription<NormalizedGamepadEvent> _subscription;
  var _active = true;
  var _closed = false;

  @override
  Stream<MapInputCommand> get commands => _commands.stream;

  void _onEvent(NormalizedGamepadEvent event) {
    final command = MapGamepadMapper.commandFor(event.button, event.value);
    if (!_closed && _active && command != null) _commands.add(command);
  }

  void _onError(Object error, StackTrace stackTrace) {
    debugPrintStack(
      label: 'Gamepad input unavailable: $error',
      stackTrace: stackTrace,
    );
  }

  @override
  void setActive(bool active) {
    if (!_closed) _active = active;
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _subscription.cancel();
    await _commands.close();
  }
}
