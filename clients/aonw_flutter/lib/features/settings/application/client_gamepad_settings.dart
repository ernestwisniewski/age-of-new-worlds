import 'gamepad_bindings.dart';

export 'gamepad_bindings.dart';

final class ClientGamepadSettings {
  const ClientGamepadSettings({
    this.bindings = GamepadBindings.defaults,
    this.enabled = true,
    this.deadzone = 0.24,
    this.cameraSensitivity = 1,
    this.invertCameraY = false,
  }) : assert(deadzone >= 0 && deadzone <= 0.6),
       assert(cameraSensitivity >= 0.2 && cameraSensitivity <= 2);

  final GamepadBindings bindings;
  final bool enabled;
  final double deadzone;
  final double cameraSensitivity;
  final bool invertCameraY;

  ClientGamepadSettings copyWith({
    GamepadBindings? bindings,
    bool? enabled,
    double? deadzone,
    double? cameraSensitivity,
    bool? invertCameraY,
  }) => ClientGamepadSettings(
    bindings: bindings ?? this.bindings,
    enabled: enabled ?? this.enabled,
    deadzone: deadzone ?? this.deadzone,
    cameraSensitivity: cameraSensitivity ?? this.cameraSensitivity,
    invertCameraY: invertCameraY ?? this.invertCameraY,
  );

  Object get _identity =>
      (enabled, deadzone, cameraSensitivity, invertCameraY, bindings);

  @override
  bool operator ==(Object other) =>
      other is ClientGamepadSettings && _identity == other._identity;

  @override
  int get hashCode => _identity.hashCode;
}
