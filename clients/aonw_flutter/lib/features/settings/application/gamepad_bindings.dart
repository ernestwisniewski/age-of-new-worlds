import 'gamepad_controls.dart';

export 'gamepad_controls.dart';

/// Physical controls have a single action; multiple buttons may share an action.
final class GamepadBindings {
  factory GamepadBindings({
    required Map<GamepadButtonControl, GamepadButtonAction> buttons,
    required Map<GamepadAxisControl, GamepadAxisAction> axes,
  }) {
    if (axes.values.toSet().length != axes.length) {
      throw ArgumentError.value(axes, 'axes', 'An axis action must be unique.');
    }
    return GamepadBindings._(Map.unmodifiable(buttons), Map.unmodifiable(axes));
  }

  const GamepadBindings._(this.buttons, this.axes);

  static const defaults = GamepadBindings._(
    {
      GamepadButtonControl.a: GamepadButtonAction.confirm,
      GamepadButtonControl.b: GamepadButtonAction.cancel,
      GamepadButtonControl.back: GamepadButtonAction.cancel,
      GamepadButtonControl.x: GamepadButtonAction.moveMode,
      GamepadButtonControl.y: GamepadButtonAction.inspect,
      GamepadButtonControl.leftStick: GamepadButtonAction.hudFocusPrevious,
      GamepadButtonControl.rightStick: GamepadButtonAction.hudFocusNext,
      GamepadButtonControl.leftBumper: GamepadButtonAction.focusPrevious,
      GamepadButtonControl.rightBumper: GamepadButtonAction.focusNext,
      GamepadButtonControl.start: GamepadButtonAction.primaryAction,
      GamepadButtonControl.dpadUp: GamepadButtonAction.dpadUp,
      GamepadButtonControl.dpadDown: GamepadButtonAction.dpadDown,
      GamepadButtonControl.dpadLeft: GamepadButtonAction.dpadLeft,
      GamepadButtonControl.dpadRight: GamepadButtonAction.dpadRight,
      GamepadButtonControl.rightTrigger: GamepadButtonAction.zoomIn,
      GamepadButtonControl.leftTrigger: GamepadButtonAction.zoomOut,
    },
    {
      GamepadAxisControl.leftStickX: GamepadAxisAction.cursorX,
      GamepadAxisControl.leftStickY: GamepadAxisAction.cursorY,
      GamepadAxisControl.rightStickX: GamepadAxisAction.cameraX,
      GamepadAxisControl.rightStickY: GamepadAxisAction.cameraY,
      GamepadAxisControl.rightTrigger: GamepadAxisAction.zoomIn,
      GamepadAxisControl.leftTrigger: GamepadAxisAction.zoomOut,
    },
  );

  final Map<GamepadButtonControl, GamepadButtonAction> buttons;
  final Map<GamepadAxisControl, GamepadAxisAction> axes;

  List<GamepadButtonControl> buttonsFor(GamepadButtonAction action) => [
    for (final control in GamepadButtonControl.values)
      if (buttons[control] == action) control,
  ];

  GamepadAxisControl? axisFor(GamepadAxisAction action) {
    for (final entry in axes.entries) {
      if (entry.value == action) return entry.key;
    }
    return null;
  }

  GamepadBindings bindButton(
    GamepadButtonAction action,
    GamepadButtonControl? control,
  ) => GamepadBindings(
    buttons: {
      for (final entry in buttons.entries)
        if (entry.value != action && entry.key != control)
          entry.key: entry.value,
      ?control: action,
    },
    axes: axes,
  );

  GamepadBindings bindAxis(
    GamepadAxisAction action,
    GamepadAxisControl? control,
  ) => GamepadBindings(
    buttons: buttons,
    axes: {
      for (final entry in axes.entries)
        if (entry.value != action && entry.key != control)
          entry.key: entry.value,
      ?control: action,
    },
  );

  @override
  bool operator ==(Object other) =>
      other is GamepadBindings &&
      _sameMap(buttons, other.buttons) &&
      _sameMap(axes, other.axes);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(GamepadButtonControl.values.map((key) => buttons[key])),
    Object.hashAll(GamepadAxisControl.values.map((key) => axes[key])),
  );
}

bool _sameMap<K, V>(Map<K, V> a, Map<K, V> b) =>
    a.length == b.length &&
    a.entries.every((entry) => b[entry.key] == entry.value);
