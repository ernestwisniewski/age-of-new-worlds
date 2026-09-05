import 'package:shared_preferences/shared_preferences.dart';

import '../application/client_settings.dart';
import '../application/client_settings_store.dart';

final class SharedPreferencesClientSettingsStore
    implements ClientSettingsStore {
  SharedPreferencesClientSettingsStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _cinematicCameraKey = 'aonw.settings.cinematicCamera';
  static const _masterVolumeKey = 'aonw.settings.masterVolume';
  static const _cameraSensitivityKey = 'aonw.settings.cameraSensitivity';
  static const _smoothCameraMovementKey = 'aonw.settings.smoothCameraMovement';
  static const _reducedMotionKey = 'aonw.settings.reducedMotion';
  static const _highContrastKey = 'aonw.settings.highContrast';
  static const _showMapGridKey = 'aonw.settings.showMapGrid';
  static const _showMapElevationWallsKey =
      'aonw.settings.showMapElevationWalls';
  static const _showMapTerrainIconsKey = 'aonw.settings.showMapTerrainIcons';
  static const _showMapResourceIconsKey = 'aonw.settings.showMapResourceIcons';
  static const _showMapHeightBadgesKey = 'aonw.settings.showMapHeightBadges';

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

  final SharedPreferencesAsync _preferences;

  @override
  Future<ClientSettings> load() async {
    final masterVolume = await _preferences.getDouble(_masterVolumeKey);
    final cameraSensitivity = await _preferences.getDouble(
      _cameraSensitivityKey,
    );
    final reducedMotion = await _preferences.getBool(_reducedMotionKey);
    final highContrast = await _preferences.getBool(_highContrastKey);
    final showMapGrid = await _preferences.getBool(_showMapGridKey);
    final showMapElevationWalls = await _preferences.getBool(
      _showMapElevationWallsKey,
    );
    final showMapTerrainIcons = await _preferences.getBool(
      _showMapTerrainIconsKey,
    );
    final showMapResourceIcons = await _preferences.getBool(
      _showMapResourceIconsKey,
    );
    final showMapHeightBadges = await _preferences.getBool(
      _showMapHeightBadgesKey,
    );
    final camera = await _loadCamera();
    final animations = await _loadAnimations();
    return ClientSettings(
      showUnitMovementAnimations: animations.movement,
      showCombatAnimations: animations.combat,
      showUnitIdleAnimations: animations.idle,
      showRouteAnimations: animations.route,
      cinematicCamera: camera.cinematicCamera,
      focusOwnUnitMovement: camera.focusOwnUnitMovement,
      followOwnUnitMovement: camera.followOwnUnitMovement,
      focusForeignUnitMovement: camera.focusForeignUnitMovement,
      followForeignUnitMovement: camera.followForeignUnitMovement,
      masterVolume: _bounded(
        masterVolume,
        minimum: 0,
        maximum: 1,
        fallback: ClientSettings.defaults.masterVolume,
      ),
      cameraSensitivity: _bounded(
        cameraSensitivity,
        minimum: 0.5,
        maximum: 2,
        fallback: ClientSettings.defaults.cameraSensitivity,
      ),
      reducedMotion: reducedMotion ?? ClientSettings.defaults.reducedMotion,
      smoothCameraMovement: camera.smoothCameraMovement,
      highContrast: highContrast ?? ClientSettings.defaults.highContrast,
      showMapGrid: showMapGrid ?? ClientSettings.defaults.showMapGrid,
      showMapElevationWalls:
          showMapElevationWalls ??
          ClientSettings.defaults.showMapElevationWalls,
      showMapTerrainIcons:
          showMapTerrainIcons ?? ClientSettings.defaults.showMapTerrainIcons,
      showMapResourceIcons:
          showMapResourceIcons ?? ClientSettings.defaults.showMapResourceIcons,
      showMapHeightBadges:
          showMapHeightBadges ?? ClientSettings.defaults.showMapHeightBadges,
    );
  }

  @override
  Future<void> save(ClientSettings settings) async {
    await _saveCamera(settings);
    await _saveAnimations(settings);
    await _preferences.setDouble(_masterVolumeKey, settings.masterVolume);
    await _preferences.setDouble(
      _cameraSensitivityKey,
      settings.cameraSensitivity,
    );
    await _preferences.setBool(_reducedMotionKey, settings.reducedMotion);
    await _preferences.setBool(_highContrastKey, settings.highContrast);
    await _preferences.setBool(_showMapGridKey, settings.showMapGrid);
    await _preferences.setBool(
      _showMapElevationWallsKey,
      settings.showMapElevationWalls,
    );
    await _preferences.setBool(
      _showMapTerrainIconsKey,
      settings.showMapTerrainIcons,
    );
    await _preferences.setBool(
      _showMapResourceIconsKey,
      settings.showMapResourceIcons,
    );
    await _preferences.setBool(
      _showMapHeightBadgesKey,
      settings.showMapHeightBadges,
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
