part of 'shared_preferences_client_settings_store.dart';

extension _AudioPreferences on SharedPreferencesClientSettingsStore {
  Future<ClientAudioSettings> _loadAudio() async {
    const defaults = ClientAudioSettings();
    return ClientAudioSettings(
      soundsEnabled:
          await _preferences.getBool('aonw.settings.audio.soundsEnabled') ??
          defaults.soundsEnabled,
      soundVolume: await _audioVolume('soundVolume', defaults.soundVolume),
      musicEnabled:
          await _preferences.getBool('aonw.settings.audio.musicEnabled') ??
          defaults.musicEnabled,
      musicVolume: await _audioVolume('musicVolume', defaults.musicVolume),
      natureEnabled:
          await _preferences.getBool('aonw.settings.audio.natureEnabled') ??
          defaults.natureEnabled,
      natureVolume: await _audioVolume('natureVolume', defaults.natureVolume),
    );
  }

  Future<double> _audioVolume(String name, double fallback) async => _bounded(
    await _preferences.getDouble('aonw.settings.audio.$name'),
    minimum: 0,
    maximum: 1,
    fallback: fallback,
  );

  Future<void> _saveAudio(ClientAudioSettings audio) async {
    await _preferences.setBool(
      'aonw.settings.audio.soundsEnabled',
      audio.soundsEnabled,
    );
    await _preferences.setDouble(
      'aonw.settings.audio.soundVolume',
      audio.soundVolume,
    );
    await _preferences.setBool(
      'aonw.settings.audio.musicEnabled',
      audio.musicEnabled,
    );
    await _preferences.setDouble(
      'aonw.settings.audio.musicVolume',
      audio.musicVolume,
    );
    await _preferences.setBool(
      'aonw.settings.audio.natureEnabled',
      audio.natureEnabled,
    );
    await _preferences.setDouble(
      'aonw.settings.audio.natureVolume',
      audio.natureVolume,
    );
  }
}
