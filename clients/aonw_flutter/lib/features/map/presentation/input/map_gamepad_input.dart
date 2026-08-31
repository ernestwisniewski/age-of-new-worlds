import 'dart:math' as math;

import 'map_input.dart';

final class MapGamepadInput {
  const MapGamepadInput({
    this.cursorX = 0,
    this.cursorY = 0,
    this.cameraX = 0,
    this.cameraY = 0,
    this.zoomIn = 0,
    this.zoomOut = 0,
    this.dpadUp = false,
    this.dpadDown = false,
    this.dpadLeft = false,
    this.dpadRight = false,
    this.activate = false,
    this.cancel = false,
    this.toggleReference = false,
  });

  static const idle = MapGamepadInput();

  final double cursorX;
  final double cursorY;
  final double cameraX;
  final double cameraY;
  final double zoomIn;
  final double zoomOut;
  final bool dpadUp;
  final bool dpadDown;
  final bool dpadLeft;
  final bool dpadRight;
  final bool activate;
  final bool cancel;
  final bool toggleReference;

  double get zoom => zoomIn - zoomOut;

  bool get isIdle => this == idle;

  MapGamepadInput copyWith({
    double? cursorX,
    double? cursorY,
    double? cameraX,
    double? cameraY,
    double? zoomIn,
    double? zoomOut,
    bool? dpadUp,
    bool? dpadDown,
    bool? dpadLeft,
    bool? dpadRight,
    bool? activate,
    bool? cancel,
    bool? toggleReference,
  }) => MapGamepadInput(
    cursorX: cursorX ?? this.cursorX,
    cursorY: cursorY ?? this.cursorY,
    cameraX: cameraX ?? this.cameraX,
    cameraY: cameraY ?? this.cameraY,
    zoomIn: zoomIn ?? this.zoomIn,
    zoomOut: zoomOut ?? this.zoomOut,
    dpadUp: dpadUp ?? this.dpadUp,
    dpadDown: dpadDown ?? this.dpadDown,
    dpadLeft: dpadLeft ?? this.dpadLeft,
    dpadRight: dpadRight ?? this.dpadRight,
    activate: activate ?? this.activate,
    cancel: cancel ?? this.cancel,
    toggleReference: toggleReference ?? this.toggleReference,
  );

  @override
  bool operator ==(Object other) =>
      other is MapGamepadInput && other._identity == _identity;

  @override
  int get hashCode => _identity.hashCode;

  Object get _identity => (
    cursorX,
    cursorY,
    cameraX,
    cameraY,
    zoomIn,
    zoomOut,
    dpadUp,
    dpadDown,
    dpadLeft,
    dpadRight,
    activate,
    cancel,
    toggleReference,
  );
}

abstract interface class ContinuousMapInputSource {
  Stream<MapGamepadInput> get continuousInputs;
}

final class MapGamepadFrame {
  const MapGamepadFrame({
    this.cursorStep,
    this.cameraX = 0,
    this.cameraY = 0,
    this.zoom = 0,
    this.activatePressed = false,
    this.cancelPressed = false,
    this.toggleReferencePressed = false,
  });

  static const idle = MapGamepadFrame();

  final MapInputCommand? cursorStep;
  final double cameraX;
  final double cameraY;
  final double zoom;
  final bool activatePressed;
  final bool cancelPressed;
  final bool toggleReferencePressed;

  bool get isIdle =>
      cursorStep == null &&
      cameraX == 0 &&
      cameraY == 0 &&
      zoom == 0 &&
      !activatePressed &&
      !cancelPressed &&
      !toggleReferencePressed;
}

final class MapGamepadFrameController {
  MapGamepadFrameController({
    this.deadzone = 0.24,
    this.cameraSensitivity = 1,
    this.initialRepeatDelay = 0.28,
    this.repeatInterval = 0.11,
  });

  final double deadzone;
  final double cameraSensitivity;
  final double initialRepeatDelay;
  final double repeatInterval;

  MapGamepadInput _previous = MapGamepadInput.idle;
  MapInputCommand? _heldCursorDirection;
  var _cursorRepeatRemaining = 0.0;

  bool get isIdle =>
      _previous.isIdle &&
      _heldCursorDirection == null &&
      _cursorRepeatRemaining == 0;

  void prime(MapGamepadInput input) {
    _previous = input;
    _heldCursorDirection = _cursorDirection(input);
    _cursorRepeatRemaining = _heldCursorDirection == null
        ? 0
        : initialRepeatDelay;
  }

  MapGamepadFrame advance({
    required MapGamepadInput input,
    required double dt,
  }) {
    if (input.isIdle && isIdle) return MapGamepadFrame.idle;
    final frame = MapGamepadFrame(
      cursorStep: _advanceCursorRepeat(_cursorDirection(input), dt),
      cameraX: _applyDeadzone(input.cameraX) * cameraSensitivity,
      cameraY: _applyDeadzone(input.cameraY) * cameraSensitivity,
      zoom: _applyDeadzone(input.zoom),
      activatePressed: _pressed(input.activate, _previous.activate),
      cancelPressed: _pressed(input.cancel, _previous.cancel),
      toggleReferencePressed: _pressed(
        input.toggleReference,
        _previous.toggleReference,
      ),
    );
    _previous = input;
    return frame;
  }

  MapInputCommand? _advanceCursorRepeat(MapInputCommand? direction, double dt) {
    if (direction == null) {
      _heldCursorDirection = null;
      _cursorRepeatRemaining = 0;
      return null;
    }
    if (direction != _heldCursorDirection) {
      _heldCursorDirection = direction;
      _cursorRepeatRemaining = initialRepeatDelay;
      return direction;
    }
    _cursorRepeatRemaining -= dt;
    if (_cursorRepeatRemaining > 0) return null;
    _cursorRepeatRemaining += repeatInterval;
    return direction;
  }

  MapInputCommand? _cursorDirection(MapGamepadInput input) {
    final dpadX = _digitalAxis(input.dpadLeft, input.dpadRight);
    final dpadY = _digitalAxis(input.dpadDown, input.dpadUp);
    final x = dpadX == 0 ? _applyDeadzone(input.cursorX) : dpadX.toDouble();
    final y = dpadY == 0 ? _applyDeadzone(input.cursorY) : dpadY.toDouble();
    return _dominantDirection(x, y);
  }

  MapInputCommand? _dominantDirection(double x, double y) {
    if (x == 0 && y == 0) return null;
    if (x.abs() > y.abs()) {
      return x > 0 ? MapInputCommand.cursorRight : MapInputCommand.cursorLeft;
    }
    return y > 0 ? MapInputCommand.cursorUp : MapInputCommand.cursorDown;
  }

  int _digitalAxis(bool negative, bool positive) =>
      (positive ? 1 : 0) - (negative ? 1 : 0);

  double _applyDeadzone(double value) {
    final magnitude = value.abs();
    if (magnitude <= deadzone) return 0;
    final normalized = (magnitude - deadzone) / (1 - deadzone);
    return value.sign * math.min(1, normalized);
  }

  bool _pressed(bool current, bool previous) => current && !previous;
}
