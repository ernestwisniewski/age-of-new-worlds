part of 'settings_screen.dart';

String _buttonActionLabel(AonwLocalizations l10n, GamepadButtonAction value) =>
    {
      GamepadButtonAction.confirm: l10n.gamepadActionConfirm,
      GamepadButtonAction.cancel: l10n.gamepadActionCancel,
      GamepadButtonAction.moveMode: l10n.gamepadActionMoveMode,
      GamepadButtonAction.inspect: l10n.gamepadActionInspect,
      GamepadButtonAction.hudFocusPrevious: l10n.gamepadActionHudPrevious,
      GamepadButtonAction.hudFocusNext: l10n.gamepadActionHudNext,
      GamepadButtonAction.focusPrevious: l10n.gamepadActionPrevious,
      GamepadButtonAction.focusNext: l10n.gamepadActionNext,
      GamepadButtonAction.primaryAction: l10n.gamepadActionPrimary,
      GamepadButtonAction.dpadUp: l10n.gamepadActionUp,
      GamepadButtonAction.dpadDown: l10n.gamepadActionDown,
      GamepadButtonAction.dpadLeft: l10n.gamepadActionLeft,
      GamepadButtonAction.dpadRight: l10n.gamepadActionRight,
      GamepadButtonAction.zoomIn: l10n.gamepadActionZoomIn,
      GamepadButtonAction.zoomOut: l10n.gamepadActionZoomOut,
    }[value]!;

String _axisActionLabel(AonwLocalizations l10n, GamepadAxisAction value) => {
  GamepadAxisAction.cursorX: l10n.gamepadActionCursorX,
  GamepadAxisAction.cursorY: l10n.gamepadActionCursorY,
  GamepadAxisAction.cameraX: l10n.gamepadActionCameraX,
  GamepadAxisAction.cameraY: l10n.gamepadActionCameraY,
  GamepadAxisAction.zoomIn: l10n.gamepadActionZoomIn,
  GamepadAxisAction.zoomOut: l10n.gamepadActionZoomOut,
}[value]!;

String _buttonControlLabel(
  AonwLocalizations l10n,
  GamepadButtonControl value,
) => {
  GamepadButtonControl.a: 'A',
  GamepadButtonControl.b: 'B',
  GamepadButtonControl.x: 'X',
  GamepadButtonControl.y: 'Y',
  GamepadButtonControl.leftBumper: 'LB',
  GamepadButtonControl.rightBumper: 'RB',
  GamepadButtonControl.leftTrigger: 'LT',
  GamepadButtonControl.rightTrigger: 'RT',
  GamepadButtonControl.back: 'Back',
  GamepadButtonControl.start: 'Start',
  GamepadButtonControl.leftStick: 'L3',
  GamepadButtonControl.rightStick: 'R3',
  GamepadButtonControl.home: l10n.gamepadControlHome,
  GamepadButtonControl.touchpad: l10n.gamepadControlTouchpad,
  GamepadButtonControl.dpadUp: l10n.gamepadActionUp,
  GamepadButtonControl.dpadDown: l10n.gamepadActionDown,
  GamepadButtonControl.dpadLeft: l10n.gamepadActionLeft,
  GamepadButtonControl.dpadRight: l10n.gamepadActionRight,
}[value]!;

String _axisControlLabel(AonwLocalizations l10n, GamepadAxisControl value) => {
  GamepadAxisControl.leftStickX: l10n.gamepadControlLeftStickX,
  GamepadAxisControl.leftStickY: l10n.gamepadControlLeftStickY,
  GamepadAxisControl.rightStickX: l10n.gamepadControlRightStickX,
  GamepadAxisControl.rightStickY: l10n.gamepadControlRightStickY,
  GamepadAxisControl.leftTrigger: l10n.gamepadControlLeftTrigger,
  GamepadAxisControl.rightTrigger: l10n.gamepadControlRightTrigger,
}[value]!;
