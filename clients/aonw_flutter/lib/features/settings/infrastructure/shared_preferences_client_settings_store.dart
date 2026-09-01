import 'package:shared_preferences/shared_preferences.dart';

import '../application/client_settings.dart';
import '../application/client_settings_store.dart';

final class SharedPreferencesClientSettingsStore
    implements ClientSettingsStore {
  SharedPreferencesClientSettingsStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _masterVolumeKey = 'aonw.settings.masterVolume';
  static const _cameraSensitivityKey = 'aonw.settings.cameraSensitivity';
  static const _reducedMotionKey = 'aonw.settings.reducedMotion';
  static const _highContrastKey = 'aonw.settings.highContrast';
  static const _showMapElevationWallsKey =
      'aonw.settings.showMapElevationWalls';

  final SharedPreferencesAsync _preferences;

  @override
  Future<ClientSettings> load() async {
    final masterVolume = await _preferences.getDouble(_masterVolumeKey);
    final cameraSensitivity = await _preferences.getDouble(
      _cameraSensitivityKey,
    );
    final reducedMotion = await _preferences.getBool(_reducedMotionKey);
    final highContrast = await _preferences.getBool(_highContrastKey);
    final showMapElevationWalls = await _preferences.getBool(
      _showMapElevationWallsKey,
    );
    return ClientSettings(
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
      highContrast: highContrast ?? ClientSettings.defaults.highContrast,
      showMapElevationWalls:
          showMapElevationWalls ??
          ClientSettings.defaults.showMapElevationWalls,
    );
  }

  @override
  Future<void> save(ClientSettings settings) async {
    await _preferences.setDouble(_masterVolumeKey, settings.masterVolume);
    await _preferences.setDouble(
      _cameraSensitivityKey,
      settings.cameraSensitivity,
    );
    await _preferences.setBool(_reducedMotionKey, settings.reducedMotion);
    await _preferences.setBool(_highContrastKey, settings.highContrast);
    await _preferences.setBool(
      _showMapElevationWallsKey,
      settings.showMapElevationWalls,
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
