part of 'shared_preferences_client_settings_store.dart';

const _showFpsKey = 'aonw.settings.performance.showFps';
const _showMapZoomKey = 'aonw.settings.performance.showMapZoom';

extension _PerformanceSettings on SharedPreferencesClientSettingsStore {
  Future<ClientPerformanceSettings> _loadPerformance() async =>
      ClientPerformanceSettings(
        showFps: await _preferences.getBool(_showFpsKey) ?? false,
        showMapZoom: await _preferences.getBool(_showMapZoomKey) ?? false,
      );

  Future<void> _savePerformance(ClientPerformanceSettings settings) async {
    await _preferences.setBool(_showFpsKey, settings.showFps);
    await _preferences.setBool(_showMapZoomKey, settings.showMapZoom);
  }
}
