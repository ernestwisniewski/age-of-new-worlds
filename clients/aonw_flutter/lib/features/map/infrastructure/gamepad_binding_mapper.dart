import '../../settings/application/client_gamepad_settings.dart';
import '../presentation/input/map_gamepad_input.dart';

/// Tracks physical state so aliases and analog/digital triggers cannot release each other.
final class GamepadBindingMapper {
  ClientGamepadSettings _settings = const ClientGamepadSettings();
  final _buttons = <GamepadButtonControl>{};
  final _axes = <GamepadAxisControl, double>{};
  final _blockedButtons = <GamepadButtonControl>{};
  final _blockedAxes = <GamepadAxisControl>{};

  bool configure(ClientGamepadSettings settings) {
    final changed = _settings.bindings != settings.bindings;
    _settings = settings;
    if (!changed) return false;
    _blockedButtons.addAll(_buttons);
    _blockedAxes.addAll(_axes.keys);
    _buttons.clear();
    _axes.clear();
    return true;
  }

  void reset() {
    _buttons.clear();
    _axes.clear();
    _blockedButtons.clear();
    _blockedAxes.clear();
  }

  MapGamepadInput button(GamepadButtonControl control, bool pressed) {
    if (_blockedButtons.contains(control)) {
      if (!pressed) _blockedButtons.remove(control);
    } else if (pressed) {
      _buttons.add(control);
    } else {
      _buttons.remove(control);
    }
    return _input();
  }

  MapGamepadInput axis(GamepadAxisControl control, double value) {
    if (_blockedAxes.contains(control)) {
      if (value.abs() <= _settings.deadzone) _blockedAxes.remove(control);
    } else if (value == 0) {
      _axes.remove(control);
    } else {
      _axes[control] = value.clamp(-1, 1);
    }
    return _input();
  }

  MapGamepadInput _input() {
    final bindings = _settings.bindings;
    final pressed = {
      for (final control in _buttons) ?bindings.buttons[control],
    };
    final axes = {
      for (final entry in _axes.entries) ?bindings.axes[entry.key]: entry.value,
    };
    return _renderInput(pressed, axes);
  }
}

MapGamepadInput _renderInput(
  Set<GamepadButtonAction> pressed,
  Map<GamepadAxisAction, double> axes,
) => MapGamepadInput(
  activate: pressed.contains(GamepadButtonAction.confirm),
  cancel: pressed.contains(GamepadButtonAction.cancel),
  toggleMoveTargeting: pressed.contains(GamepadButtonAction.moveMode),
  inspectHex: pressed.contains(GamepadButtonAction.inspect),
  hudFocusPrevious: pressed.contains(GamepadButtonAction.hudFocusPrevious),
  hudFocusNext: pressed.contains(GamepadButtonAction.hudFocusNext),
  focusPrevious: pressed.contains(GamepadButtonAction.focusPrevious),
  focusNext: pressed.contains(GamepadButtonAction.focusNext),
  primaryAction: pressed.contains(GamepadButtonAction.primaryAction),
  dpadUp: pressed.contains(GamepadButtonAction.dpadUp),
  dpadDown: pressed.contains(GamepadButtonAction.dpadDown),
  dpadLeft: pressed.contains(GamepadButtonAction.dpadLeft),
  dpadRight: pressed.contains(GamepadButtonAction.dpadRight),
  cursorX: axes[GamepadAxisAction.cursorX] ?? 0,
  cursorY: axes[GamepadAxisAction.cursorY] ?? 0,
  cameraX: axes[GamepadAxisAction.cameraX] ?? 0,
  cameraY: axes[GamepadAxisAction.cameraY] ?? 0,
  zoomIn: _zoom(
    pressed,
    axes,
    GamepadButtonAction.zoomIn,
    GamepadAxisAction.zoomIn,
  ),
  zoomOut: _zoom(
    pressed,
    axes,
    GamepadButtonAction.zoomOut,
    GamepadAxisAction.zoomOut,
  ),
);

double _zoom(
  Set<GamepadButtonAction> pressed,
  Map<GamepadAxisAction, double> axes,
  GamepadButtonAction button,
  GamepadAxisAction axis,
) => pressed.contains(button) ? 1 : axes[axis] ?? 0;
