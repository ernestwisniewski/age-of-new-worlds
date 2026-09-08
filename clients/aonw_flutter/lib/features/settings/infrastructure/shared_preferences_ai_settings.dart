part of 'shared_preferences_client_settings_store.dart';

const _aiBatterySaverKey = 'aonw.settings.ai.batterySaver';

extension _AiSettings on SharedPreferencesClientSettingsStore {
  Future<ClientAiSettings> _loadAi() async => ClientAiSettings(
    batterySaver: await _preferences.getBool(_aiBatterySaverKey) ?? false,
  );

  Future<void> _saveAi(ClientAiSettings settings) =>
      _preferences.setBool(_aiBatterySaverKey, settings.batterySaver);
}
