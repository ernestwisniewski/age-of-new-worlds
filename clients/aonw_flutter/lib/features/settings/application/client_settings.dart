final class ClientSettings {
  const ClientSettings({
    required this.masterVolume,
    required this.cameraSensitivity,
    required this.reducedMotion,
    required this.highContrast,
    required this.showMapElevationWalls,
  }) : assert(masterVolume >= 0 && masterVolume <= 1),
       assert(cameraSensitivity >= 0.5 && cameraSensitivity <= 2);

  static const defaults = ClientSettings(
    masterVolume: 0.8,
    cameraSensitivity: 1,
    reducedMotion: false,
    highContrast: false,
    showMapElevationWalls: false,
  );

  final double masterVolume;
  final double cameraSensitivity;
  final bool reducedMotion;
  final bool highContrast;
  final bool showMapElevationWalls;

  ClientSettings copyWith({
    double? masterVolume,
    double? cameraSensitivity,
    bool? reducedMotion,
    bool? highContrast,
    bool? showMapElevationWalls,
  }) => ClientSettings(
    masterVolume: masterVolume ?? this.masterVolume,
    cameraSensitivity: cameraSensitivity ?? this.cameraSensitivity,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    highContrast: highContrast ?? this.highContrast,
    showMapElevationWalls: showMapElevationWalls ?? this.showMapElevationWalls,
  );

  @override
  bool operator ==(Object other) =>
      other is ClientSettings &&
      other.masterVolume == masterVolume &&
      other.cameraSensitivity == cameraSensitivity &&
      other.reducedMotion == reducedMotion &&
      other.highContrast == highContrast &&
      other.showMapElevationWalls == showMapElevationWalls;

  @override
  int get hashCode => Object.hash(
    masterVolume,
    cameraSensitivity,
    reducedMotion,
    highContrast,
    showMapElevationWalls,
  );
}
