import '../../map/read_model/map_view_mode.dart';

import 'client_ai_settings.dart';
import 'client_audio_settings.dart';
import 'client_automation_settings.dart';
import 'client_city_planning_settings.dart';
import 'client_gamepad_settings.dart';
import 'client_language.dart';
import 'client_map_display_settings.dart';
import 'client_performance_settings.dart';
import 'client_text_scale.dart';

export 'client_ai_settings.dart';
export 'client_audio_settings.dart';
export 'client_automation_settings.dart';
export 'client_city_planning_settings.dart';
export 'client_gamepad_settings.dart';
export 'client_language.dart';
export 'client_map_display_settings.dart';
export 'client_performance_settings.dart';
export 'client_text_scale.dart';

final class ClientSettings {
  const ClientSettings({
    this.mapDisplay = const ClientMapDisplaySettings(),
    this.language = ClientLanguage.system,
    this.textScale = ClientTextScale.standard,
    this.gamepad = const ClientGamepadSettings(),
    this.audio = const ClientAudioSettings(),
    this.ai = const ClientAiSettings(),
    this.automation = const ClientAutomationSettings(),
    this.performance = const ClientPerformanceSettings(),
    this.showResearchDiscoveries = true,
    required this.cameraSensitivity,
    required this.reducedMotion,
    required this.highContrast,
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
  );

  ClientCityPlanningSettings get cityPlanning => mapDisplay.cityPlanning;
  bool get showMapCitySites => cityPlanning.showSites;
  bool get showMapCityGrowth => cityPlanning.showGrowth;
  MapViewMode get preferredMapViewMode => mapDisplay.preferredMapViewMode;
  final ClientLanguage language;
  final ClientTextScale textScale;
  final ClientGamepadSettings gamepad;
  final ClientAudioSettings audio;
  final ClientAiSettings ai;
  final ClientAutomationSettings automation;
  final ClientPerformanceSettings performance;
  final bool showResearchDiscoveries;
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
  bool get showMapGrid => mapDisplay.showMapGrid;
  bool get showMapElevationWalls => mapDisplay.showMapElevationWalls;
  bool get showMapTerrainIcons => mapDisplay.showMapTerrainIcons;
  bool get showMapResourceIcons => mapDisplay.showMapResourceIcons;
  bool get showMapHeightBadges => mapDisplay.showMapHeightBadges;

  final ClientMapDisplaySettings mapDisplay;

  ClientSettings copyWith({
    ClientMapDisplaySettings? mapDisplay,
    ClientLanguage? language,
    ClientTextScale? textScale,
    ClientGamepadSettings? gamepad,
    ClientAudioSettings? audio,
    ClientAiSettings? ai,
    ClientAutomationSettings? automation,
    ClientPerformanceSettings? performance,
    bool? showResearchDiscoveries,
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
  }) => ClientSettings(
    mapDisplay: mapDisplay ?? this.mapDisplay,
    language: language ?? this.language,
    textScale: textScale ?? this.textScale,
    gamepad: gamepad ?? this.gamepad,
    audio: audio ?? this.audio,
    ai: ai ?? this.ai,
    automation: automation ?? this.automation,
    performance: performance ?? this.performance,
    showResearchDiscoveries:
        showResearchDiscoveries ?? this.showResearchDiscoveries,
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
      other.performance == performance &&
      other.showResearchDiscoveries == showResearchDiscoveries;

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
      other.showMapCitySites == showMapCitySites &&
      other.showMapCityGrowth == showMapCityGrowth &&
      other.preferredMapViewMode == preferredMapViewMode &&
      other.showMapGrid == showMapGrid &&
      other.showMapElevationWalls == showMapElevationWalls &&
      other.showMapTerrainIcons == showMapTerrainIcons &&
      other.showMapResourceIcons == showMapResourceIcons &&
      other.showMapHeightBadges == showMapHeightBadges;

  @override
  int get hashCode => Object.hashAll([
    showMapCitySites,
    showMapCityGrowth,
    preferredMapViewMode,
    language,
    textScale,
    gamepad,
    audio,
    ai,
    automation,
    performance,
    showResearchDiscoveries,
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
