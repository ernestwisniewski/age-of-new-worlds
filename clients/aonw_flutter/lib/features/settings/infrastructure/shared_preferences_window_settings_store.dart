import 'package:shared_preferences/shared_preferences.dart';

import '../application/window_settings.dart';

final class SharedPreferencesWindowSettingsStore
    implements WindowSettingsStore {
  SharedPreferencesWindowSettingsStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _modeKey = 'aonw.settings.windowMode';
  final SharedPreferencesAsync _preferences;

  @override
  Future<WindowMode> load() async {
    final value = await _preferences.getString(_modeKey);
    return WindowMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => WindowMode.fullscreen,
    );
  }

  @override
  Future<void> save(WindowMode mode) =>
      _preferences.setString(_modeKey, mode.name);
}
