part of 'shared_preferences_client_settings_store.dart';

extension _GamepadPreferences on SharedPreferencesClientSettingsStore {
  Future<ClientGamepadSettings> _loadGamepad() async {
    const defaults = ClientGamepadSettings();
    return ClientGamepadSettings(
      enabled:
          await _preferences.getBool('aonw.settings.gamepad.enabled') ??
          defaults.enabled,
      deadzone: _bounded(
        await _preferences.getDouble('aonw.settings.gamepad.deadzone'),
        minimum: 0,
        maximum: 0.6,
        fallback: defaults.deadzone,
      ),
      cameraSensitivity: _bounded(
        await _preferences.getDouble('aonw.settings.gamepad.cameraSensitivity'),
        minimum: 0.2,
        maximum: 2,
        fallback: defaults.cameraSensitivity,
      ),
      invertCameraY:
          await _preferences.getBool('aonw.settings.gamepad.invertCameraY') ??
          defaults.invertCameraY,
    );
  }

  Future<void> _saveGamepad(ClientGamepadSettings gamepad) async {
    await _preferences.setBool(
      'aonw.settings.gamepad.enabled',
      gamepad.enabled,
    );
    await _preferences.setDouble(
      'aonw.settings.gamepad.deadzone',
      gamepad.deadzone,
    );
    await _preferences.setDouble(
      'aonw.settings.gamepad.cameraSensitivity',
      gamepad.cameraSensitivity,
    );
    await _preferences.setBool(
      'aonw.settings.gamepad.invertCameraY',
      gamepad.invertCameraY,
    );
  }
}
