part of 'shared_preferences_client_settings_store.dart';

const _showMapGridKey = 'aonw.settings.showMapGrid';
const _showMapElevationWallsKey = 'aonw.settings.showMapElevationWalls';
const _showMapTerrainIconsKey = 'aonw.settings.showMapTerrainIcons';
const _showMapResourceIconsKey = 'aonw.settings.showMapResourceIcons';
const _showMapHeightBadgesKey = 'aonw.settings.showMapHeightBadges';

const _preferredMapViewModeKey = 'aonw.settings.preferredMapViewMode';

extension _MapSettings on SharedPreferencesClientSettingsStore {
  Future<
    ({
      MapViewMode viewMode,
      bool grid,
      bool walls,
      bool terrain,
      bool resources,
      bool heights,
    })
  >
  _loadMap() async => (
    viewMode: await _loadMapViewMode(),
    grid:
        await _preferences.getBool(_showMapGridKey) ??
        ClientSettings.defaults.showMapGrid,
    walls:
        await _preferences.getBool(_showMapElevationWallsKey) ??
        ClientSettings.defaults.showMapElevationWalls,
    terrain:
        await _preferences.getBool(_showMapTerrainIconsKey) ??
        ClientSettings.defaults.showMapTerrainIcons,
    resources:
        await _preferences.getBool(_showMapResourceIconsKey) ??
        ClientSettings.defaults.showMapResourceIcons,
    heights:
        await _preferences.getBool(_showMapHeightBadgesKey) ??
        ClientSettings.defaults.showMapHeightBadges,
  );

  Future<MapViewMode> _loadMapViewMode() async {
    final value = await _preferences.getString(_preferredMapViewModeKey);
    return MapViewMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => MapViewMode.graphic,
    );
  }

  Future<void> _saveMap(ClientSettings settings) async {
    await _preferences.setString(
      _preferredMapViewModeKey,
      settings.preferredMapViewMode.name,
    );
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
}
