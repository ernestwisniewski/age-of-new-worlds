import 'package:flutter/services.dart';

import 'map_input.dart';

enum MapTurnShortcut { previous, next, primary }

abstract final class MapKeyboardShortcuts {
  static final commands =
      Map<LogicalKeyboardKey, MapInputCommand>.unmodifiable({
        LogicalKeyboardKey.enter: MapInputCommand.activate,
        LogicalKeyboardKey.escape: MapInputCommand.cancel,
        LogicalKeyboardKey.keyR: MapInputCommand.toggleMapViewMode,
        LogicalKeyboardKey.keyM: MapInputCommand.toggleMoveTargeting,
        LogicalKeyboardKey.keyI: MapInputCommand.inspectHex,
      });

  static final turns = Map<LogicalKeyboardKey, MapTurnShortcut>.unmodifiable({
    LogicalKeyboardKey.bracketLeft: MapTurnShortcut.previous,
    LogicalKeyboardKey.bracketRight: MapTurnShortcut.next,
    LogicalKeyboardKey.space: MapTurnShortcut.primary,
  });

  static bool get hasModifiers {
    final keyboard = HardwareKeyboard.instance;
    return keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed ||
        keyboard.isShiftPressed;
  }
}
