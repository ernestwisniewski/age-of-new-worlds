final class ClientGamepadSettings {
  const ClientGamepadSettings({
    this.enabled = true,
    this.deadzone = 0.24,
    this.cameraSensitivity = 1,
    this.invertCameraY = false,
  }) : assert(deadzone >= 0 && deadzone <= 0.6),
       assert(cameraSensitivity >= 0.2 && cameraSensitivity <= 2);

  final bool enabled;
  final double deadzone;
  final double cameraSensitivity;
  final bool invertCameraY;

  ClientGamepadSettings copyWith({
    bool? enabled,
    double? deadzone,
    double? cameraSensitivity,
    bool? invertCameraY,
  }) => ClientGamepadSettings(
    enabled: enabled ?? this.enabled,
    deadzone: deadzone ?? this.deadzone,
    cameraSensitivity: cameraSensitivity ?? this.cameraSensitivity,
    invertCameraY: invertCameraY ?? this.invertCameraY,
  );

  Object get _identity => (enabled, deadzone, cameraSensitivity, invertCameraY);

  @override
  bool operator ==(Object other) =>
      other is ClientGamepadSettings && _identity == other._identity;

  @override
  int get hashCode => _identity.hashCode;
}
