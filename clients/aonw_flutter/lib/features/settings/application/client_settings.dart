final class ClientSettings {
  const ClientSettings({
    required this.masterVolume,
    required this.cameraSensitivity,
    required this.reducedMotion,
    required this.highContrast,
    required this.showMapGrid,
    required this.showMapElevationWalls,
    required this.showMapTerrainIcons,
    required this.showMapResourceIcons,
    required this.showMapHeightBadges,
    this.smoothCameraMovement = true,
    this.cinematicCamera = false,
    this.focusOwnUnitMovement = true,
    this.followOwnUnitMovement = false,
    this.focusForeignUnitMovement = false,
    this.followForeignUnitMovement = false,
  }) : assert(masterVolume >= 0 && masterVolume <= 1),
       assert(cameraSensitivity >= 0.5 && cameraSensitivity <= 2);

  static const defaults = ClientSettings(
    masterVolume: 0.8,
    cameraSensitivity: 1,
    reducedMotion: false,
    highContrast: false,
    showMapGrid: false,
    showMapElevationWalls: false,
    showMapTerrainIcons: false,
    showMapResourceIcons: true,
    showMapHeightBadges: false,
  );

  final double masterVolume;
  final double cameraSensitivity;
  final bool smoothCameraMovement;
  final bool cinematicCamera;
  final bool focusOwnUnitMovement;
  final bool followOwnUnitMovement;
  final bool focusForeignUnitMovement;
  final bool followForeignUnitMovement;
  final bool reducedMotion;
  final bool highContrast;
  final bool showMapGrid;
  final bool showMapElevationWalls;
  final bool showMapTerrainIcons;
  final bool showMapResourceIcons;
  final bool showMapHeightBadges;

  ClientSettings copyWith({
    double? masterVolume,
    double? cameraSensitivity,
    bool? smoothCameraMovement,
    bool? cinematicCamera,
    bool? focusOwnUnitMovement,
    bool? followOwnUnitMovement,
    bool? focusForeignUnitMovement,
    bool? followForeignUnitMovement,
    bool? reducedMotion,
    bool? highContrast,
    bool? showMapGrid,
    bool? showMapElevationWalls,
    bool? showMapTerrainIcons,
    bool? showMapResourceIcons,
    bool? showMapHeightBadges,
  }) => ClientSettings(
    masterVolume: masterVolume ?? this.masterVolume,
    cameraSensitivity: cameraSensitivity ?? this.cameraSensitivity,
    smoothCameraMovement: smoothCameraMovement ?? this.smoothCameraMovement,
    cinematicCamera: cinematicCamera ?? this.cinematicCamera,
    focusOwnUnitMovement: focusOwnUnitMovement ?? this.focusOwnUnitMovement,
    followOwnUnitMovement: followOwnUnitMovement ?? this.followOwnUnitMovement,
    focusForeignUnitMovement:
        focusForeignUnitMovement ?? this.focusForeignUnitMovement,
    followForeignUnitMovement:
        followForeignUnitMovement ?? this.followForeignUnitMovement,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    highContrast: highContrast ?? this.highContrast,
    showMapGrid: showMapGrid ?? this.showMapGrid,
    showMapElevationWalls: showMapElevationWalls ?? this.showMapElevationWalls,
    showMapTerrainIcons: showMapTerrainIcons ?? this.showMapTerrainIcons,
    showMapResourceIcons: showMapResourceIcons ?? this.showMapResourceIcons,
    showMapHeightBadges: showMapHeightBadges ?? this.showMapHeightBadges,
  );

  @override
  bool operator ==(Object other) =>
      other is ClientSettings &&
      other.masterVolume == masterVolume &&
      other.cameraSensitivity == cameraSensitivity &&
      _sameCamera(other) &&
      other.reducedMotion == reducedMotion &&
      other.highContrast == highContrast &&
      _sameMapDisplay(other);

  bool _sameCamera(ClientSettings other) =>
      other.smoothCameraMovement == smoothCameraMovement &&
      other.cinematicCamera == cinematicCamera &&
      other.focusOwnUnitMovement == focusOwnUnitMovement &&
      other.followOwnUnitMovement == followOwnUnitMovement &&
      other.focusForeignUnitMovement == focusForeignUnitMovement &&
      other.followForeignUnitMovement == followForeignUnitMovement;

  bool _sameMapDisplay(ClientSettings other) =>
      other.showMapGrid == showMapGrid &&
      other.showMapElevationWalls == showMapElevationWalls &&
      other.showMapTerrainIcons == showMapTerrainIcons &&
      other.showMapResourceIcons == showMapResourceIcons &&
      other.showMapHeightBadges == showMapHeightBadges;

  @override
  int get hashCode => Object.hash(
    masterVolume,
    cameraSensitivity,
    smoothCameraMovement,
    cinematicCamera,
    focusOwnUnitMovement,
    followOwnUnitMovement,
    focusForeignUnitMovement,
    followForeignUnitMovement,
    reducedMotion,
    highContrast,
    showMapGrid,
    showMapElevationWalls,
    showMapTerrainIcons,
    showMapResourceIcons,
    showMapHeightBadges,
  );
}
