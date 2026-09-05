final class ClientAudioSettings {
  const ClientAudioSettings({
    this.soundsEnabled = true,
    this.soundVolume = 0.25,
    this.musicEnabled = true,
    this.musicVolume = 0.2,
    this.natureEnabled = true,
    this.natureVolume = 0.4,
  }) : assert(soundVolume >= 0 && soundVolume <= 1),
       assert(musicVolume >= 0 && musicVolume <= 1),
       assert(natureVolume >= 0 && natureVolume <= 1);

  final bool soundsEnabled;
  final double soundVolume;
  final bool musicEnabled;
  final double musicVolume;
  final bool natureEnabled;
  final double natureVolume;

  ClientAudioSettings copyWith({
    bool? soundsEnabled,
    double? soundVolume,
    bool? musicEnabled,
    double? musicVolume,
    bool? natureEnabled,
    double? natureVolume,
  }) => ClientAudioSettings(
    soundsEnabled: soundsEnabled ?? this.soundsEnabled,
    soundVolume: soundVolume ?? this.soundVolume,
    musicEnabled: musicEnabled ?? this.musicEnabled,
    musicVolume: musicVolume ?? this.musicVolume,
    natureEnabled: natureEnabled ?? this.natureEnabled,
    natureVolume: natureVolume ?? this.natureVolume,
  );

  @override
  bool operator ==(Object other) =>
      other is ClientAudioSettings && other._identity == _identity;

  @override
  int get hashCode => _identity.hashCode;

  Object get _identity => (
    soundsEnabled,
    soundVolume,
    musicEnabled,
    musicVolume,
    natureEnabled,
    natureVolume,
  );
}
