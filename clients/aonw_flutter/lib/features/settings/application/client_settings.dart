import '../../map/read_model/map_view_mode.dart';

import 'client_ai_settings.dart';
import 'client_audio_settings.dart';
import 'client_automation_settings.dart';
import 'client_gamepad_settings.dart';
import 'client_language.dart';
import 'client_performance_settings.dart';
import 'client_text_scale.dart';

export 'client_ai_settings.dart';
export 'client_audio_settings.dart';
export 'client_automation_settings.dart';
export 'client_gamepad_settings.dart';
export 'client_language.dart';
export 'client_performance_settings.dart';
export 'client_text_scale.dart';

final class ClientSettings {
  const ClientSettings({
    this.preferredMapViewMode = MapViewMode.graphic,
    this.language = ClientLanguage.system,
    this.textScale = ClientTextScale.standard,
    this.gamepad = const ClientGamepadSettings(),
    this.audio = const ClientAudioSettings(),
    this.ai = const ClientAiSettings(),
    this.automation = const ClientAutomationSettings(),
    this.performance = const ClientPerformanceSettings(),
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
    this.showUnitMovementAnimations = true,
    this.showCombatAnimations = true,
    this.showUnitIdleAnimations = true,
    this.showRouteAnimations = true,
    this.focusOwnUnitMovement = true,
    this.followOwnUnitMovement = false,
    this.focusForeignUnitMovement = false,
    this.followForeignUnitMovement = false,
  }) : assert(cameraSensitivity >= 0.5 && cameraSensitivity <= 2);

  static const defaults = ClientSettings(
    cameraSensitivity: 1,
    reducedMotion: false,
    highContrast: false,
    showMapGrid: false,
    showMapElevationWalls: false,
    showMapTerrainIcons: false,
    showMapResourceIcons: true,
    showMapHeightBadges: false,
  );

  final MapViewMode preferredMapViewMode;
  final ClientLanguage language;
  final ClientTextScale textScale;
  final ClientGamepadSettings gamepad;
  final ClientAudioSettings audio;
  final ClientAiSettings ai;
  final ClientAutomationSettings automation;
  final ClientPerformanceSettings performance;
  final double cameraSensitivity;
  final bool smoothCameraMovement;
  final bool cinematicCamera;
  final bool showUnitMovementAnimations;
  final bool showCombatAnimations;
  final bool showUnitIdleAnimations;
  final bool showRouteAnimations;
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
    MapViewMode? preferredMapViewMode,
    ClientLanguage? language,
    ClientTextScale? textScale,
    ClientGamepadSettings? gamepad,
    ClientAudioSettings? audio,
    ClientAiSettings? ai,
    ClientAutomationSettings? automation,
    ClientPerformanceSettings? performance,
    double? cameraSensitivity,
    bool? smoothCameraMovement,
    bool? cinematicCamera,
    bool? showUnitMovementAnimations,
    bool? showCombatAnimations,
    bool? showUnitIdleAnimations,
    bool? showRouteAnimations,
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
    preferredMapViewMode: preferredMapViewMode ?? this.preferredMapViewMode,
    language: language ?? this.language,
    textScale: textScale ?? this.textScale,
    gamepad: gamepad ?? this.gamepad,
    audio: audio ?? this.audio,
    ai: ai ?? this.ai,
    automation: automation ?? this.automation,
    performance: performance ?? this.performance,
    cameraSensitivity: cameraSensitivity ?? this.cameraSensitivity,
    smoothCameraMovement: smoothCameraMovement ?? this.smoothCameraMovement,
    cinematicCamera: cinematicCamera ?? this.cinematicCamera,
    showUnitMovementAnimations:
        showUnitMovementAnimations ?? this.showUnitMovementAnimations,
    showCombatAnimations: showCombatAnimations ?? this.showCombatAnimations,
    showUnitIdleAnimations:
        showUnitIdleAnimations ?? this.showUnitIdleAnimations,
    showRouteAnimations: showRouteAnimations ?? this.showRouteAnimations,
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
      _sameClientOptions(other) &&
      other.cameraSensitivity == cameraSensitivity &&
      _sameCamera(other) &&
      _sameAnimations(other) &&
      _sameAccessibility(other) &&
      _sameMapDisplay(other);

  bool _sameClientOptions(ClientSettings other) =>
      other.language == language &&
      other.gamepad == gamepad &&
      other.audio == audio &&
      other.ai == ai &&
      other.automation == automation &&
      other.performance == performance;

  bool _sameAccessibility(ClientSettings other) =>
      other.textScale == textScale &&
      other.reducedMotion == reducedMotion &&
      other.highContrast == highContrast;

  bool _sameAnimations(ClientSettings other) =>
      other.showUnitMovementAnimations == showUnitMovementAnimations &&
      other.showCombatAnimations == showCombatAnimations &&
      other.showUnitIdleAnimations == showUnitIdleAnimations &&
      other.showRouteAnimations == showRouteAnimations;

  bool _sameCamera(ClientSettings other) =>
      other.smoothCameraMovement == smoothCameraMovement &&
      other.cinematicCamera == cinematicCamera &&
      other.focusOwnUnitMovement == focusOwnUnitMovement &&
      other.followOwnUnitMovement == followOwnUnitMovement &&
      other.focusForeignUnitMovement == focusForeignUnitMovement &&
      other.followForeignUnitMovement == followForeignUnitMovement;

  bool _sameMapDisplay(ClientSettings other) =>
      other.preferredMapViewMode == preferredMapViewMode &&
      other.showMapGrid == showMapGrid &&
      other.showMapElevationWalls == showMapElevationWalls &&
      other.showMapTerrainIcons == showMapTerrainIcons &&
      other.showMapResourceIcons == showMapResourceIcons &&
      other.showMapHeightBadges == showMapHeightBadges;

  @override
  int get hashCode => Object.hashAll([
    preferredMapViewMode,
    language,
    textScale,
    gamepad,
    audio,
    ai,
    automation,
    performance,
    cameraSensitivity,
    smoothCameraMovement,
    cinematicCamera,
    showUnitMovementAnimations,
    showCombatAnimations,
    showUnitIdleAnimations,
    showRouteAnimations,
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
  ]);
}
