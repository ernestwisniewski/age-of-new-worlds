import 'package:shared_preferences/shared_preferences.dart';

import '../../map/read_model/map_view_mode.dart';
import '../application/client_settings.dart';
import '../application/client_settings_store.dart';
import 'gamepad_bindings_codec.dart';

part 'shared_preferences_map_settings.dart';
part 'shared_preferences_ai_settings.dart';
part 'shared_preferences_audio_settings.dart';
part 'shared_preferences_automation_settings.dart';
part 'shared_preferences_performance_settings.dart';
part 'shared_preferences_gamepad_settings.dart';

final class SharedPreferencesClientSettingsStore
    implements ClientSettingsStore {
  SharedPreferencesClientSettingsStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _languageKey = 'aonw.settings.language';
  static const _textScaleKey = 'aonw.settings.textScale';
  static const _cinematicCameraKey = 'aonw.settings.cinematicCamera';
  static const _cameraSensitivityKey = 'aonw.settings.cameraSensitivity';
  static const _smoothCameraMovementKey = 'aonw.settings.smoothCameraMovement';
  static const _reducedMotionKey = 'aonw.settings.reducedMotion';
  static const _highContrastKey = 'aonw.settings.highContrast';
  static const _focusOwnUnitMovementKey = 'aonw.settings.focusOwnUnitMovement';
  static const _followOwnUnitMovementKey =
      'aonw.settings.followOwnUnitMovement';
  static const _focusForeignUnitMovementKey =
      'aonw.settings.focusForeignUnitMovement';
  static const _followForeignUnitMovementKey =
      'aonw.settings.followForeignUnitMovement';

  static const _unitMovementAnimationsKey =
      'aonw.settings.showUnitMovementAnimations';
  static const _combatAnimationsKey = 'aonw.settings.showCombatAnimations';
  static const _idleAnimationsKey = 'aonw.settings.showUnitIdleAnimations';
  static const _routeAnimationsKey = 'aonw.settings.showRouteAnimations';

  static const _discoveriesKey = 'aonw.settings.showResearchDiscoveries';

  final SharedPreferencesAsync _preferences;

  @override
  Future<ClientSettings> load() async {
    final cameraSensitivity = await _preferences.getDouble(
      _cameraSensitivityKey,
    );
    final reducedMotion = await _preferences.getBool(_reducedMotionKey);
    final highContrast = await _preferences.getBool(_highContrastKey);
    final map = await _loadMap();
    final camera = await _loadCamera();
    final animations = await _loadAnimations();
    return ClientSettings(
      language: await _loadLanguage(),
      showResearchDiscoveries:
          await _preferences.getBool(_discoveriesKey) ?? true,
      textScale: await _loadTextScale(),
      gamepad: await _loadGamepad(),
      showUnitMovementAnimations: animations.movement,
      showCombatAnimations: animations.combat,
      showUnitIdleAnimations: animations.idle,
      showRouteAnimations: animations.route,
      cinematicCamera: camera.cinematicCamera,
      focusOwnUnitMovement: camera.focusOwnUnitMovement,
      followOwnUnitMovement: camera.followOwnUnitMovement,
      focusForeignUnitMovement: camera.focusForeignUnitMovement,
      followForeignUnitMovement: camera.followForeignUnitMovement,
      audio: await _loadAudio(),
      ai: await _loadAi(),
      automation: await _loadAutomation(),
      performance: await _loadPerformance(),
      cameraSensitivity: _bounded(
        cameraSensitivity,
        minimum: 0.5,
        maximum: 2,
        fallback: ClientSettings.defaults.cameraSensitivity,
      ),
      reducedMotion: reducedMotion ?? ClientSettings.defaults.reducedMotion,
      smoothCameraMovement: camera.smoothCameraMovement,
      highContrast: highContrast ?? ClientSettings.defaults.highContrast,
      mapDisplay: ClientMapDisplaySettings(
        cityPlanning: ClientCityPlanningSettings(
          showSites: map.citySites,
          showGrowth: map.cityGrowth,
        ),
        preferredMapViewMode: map.viewMode,
        showMapGrid: map.grid,
        showMapElevationWalls: map.walls,
        showMapTerrainIcons: map.terrain,
        showMapResourceIcons: map.resources,
        showMapHeightBadges: map.heights,
      ),
    );
  }

  @override
  Future<void> save(ClientSettings settings) async {
    await _preferences.setString(_languageKey, settings.language.storageValue);
    await _preferences.setString(_textScaleKey, settings.textScale.name);
    await _saveCamera(settings);
    await _saveAnimations(settings);
    await _saveAudio(settings.audio);
    await _saveAi(settings.ai);
    await _saveAutomation(settings.automation);
    await _savePerformance(settings.performance);
    await _saveGamepad(settings.gamepad);
    await _preferences.setDouble(
      _cameraSensitivityKey,
      settings.cameraSensitivity,
    );
    await _preferences.setBool(_reducedMotionKey, settings.reducedMotion);
    await _preferences.setBool(_highContrastKey, settings.highContrast);
    await _saveMap(settings);
    await _preferences.setBool(
      _discoveriesKey,
      settings.showResearchDiscoveries,
    );
  }

  Future<ClientLanguage> _loadLanguage() async {
    final value = await _preferences.getString(_languageKey);
    return ClientLanguage.values.firstWhere(
      (language) => language.storageValue == value,
      orElse: () => ClientLanguage.system,
    );
  }

  Future<ClientTextScale> _loadTextScale() async {
    final value = await _preferences.getString(_textScaleKey);
    return ClientTextScale.values.firstWhere(
      (scale) => scale.name == value,
      orElse: () => ClientTextScale.standard,
    );
  }

  Future<({bool movement, bool combat, bool idle, bool route})>
  _loadAnimations() async => (
    route:
        await _preferences.getBool(_routeAnimationsKey) ??
        ClientSettings.defaults.showRouteAnimations,
    idle:
        await _preferences.getBool(_idleAnimationsKey) ??
        ClientSettings.defaults.showUnitIdleAnimations,
    movement:
        await _preferences.getBool(_unitMovementAnimationsKey) ??
        ClientSettings.defaults.showUnitMovementAnimations,
    combat:
        await _preferences.getBool(_combatAnimationsKey) ??
        ClientSettings.defaults.showCombatAnimations,
  );

  Future<void> _saveAnimations(ClientSettings settings) async {
    await _preferences.setBool(
      _routeAnimationsKey,
      settings.showRouteAnimations,
    );
    await _preferences.setBool(
      _idleAnimationsKey,
      settings.showUnitIdleAnimations,
    );
    await _preferences.setBool(
      _unitMovementAnimationsKey,
      settings.showUnitMovementAnimations,
    );
    await _preferences.setBool(
      _combatAnimationsKey,
      settings.showCombatAnimations,
    );
  }

  Future<
    ({
      bool cinematicCamera,
      bool smoothCameraMovement,
      bool focusOwnUnitMovement,
      bool followOwnUnitMovement,
      bool focusForeignUnitMovement,
      bool followForeignUnitMovement,
    })
  >
  _loadCamera() async => (
    cinematicCamera:
        await _preferences.getBool(_cinematicCameraKey) ??
        ClientSettings.defaults.cinematicCamera,
    smoothCameraMovement:
        await _preferences.getBool(_smoothCameraMovementKey) ??
        ClientSettings.defaults.smoothCameraMovement,
    focusOwnUnitMovement:
        await _preferences.getBool(_focusOwnUnitMovementKey) ??
        ClientSettings.defaults.focusOwnUnitMovement,
    followOwnUnitMovement:
        await _preferences.getBool(_followOwnUnitMovementKey) ??
        ClientSettings.defaults.followOwnUnitMovement,
    focusForeignUnitMovement:
        await _preferences.getBool(_focusForeignUnitMovementKey) ??
        ClientSettings.defaults.focusForeignUnitMovement,
    followForeignUnitMovement:
        await _preferences.getBool(_followForeignUnitMovementKey) ??
        ClientSettings.defaults.followForeignUnitMovement,
  );

  Future<void> _saveCamera(ClientSettings settings) async {
    await _preferences.setBool(_cinematicCameraKey, settings.cinematicCamera);
    await _preferences.setBool(
      _smoothCameraMovementKey,
      settings.smoothCameraMovement,
    );
    await _preferences.setBool(
      _focusOwnUnitMovementKey,
      settings.focusOwnUnitMovement,
    );
    await _preferences.setBool(
      _followOwnUnitMovementKey,
      settings.followOwnUnitMovement,
    );
    await _preferences.setBool(
      _focusForeignUnitMovementKey,
      settings.focusForeignUnitMovement,
    );
    await _preferences.setBool(
      _followForeignUnitMovementKey,
      settings.followForeignUnitMovement,
    );
  }
}

double _bounded(
  double? value, {
  required double minimum,
  required double maximum,
  required double fallback,
}) {
  if (value == null || !value.isFinite || value < minimum || value > maximum) {
    return fallback;
  }
  return value;
}
