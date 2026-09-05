part of 'settings_screen.dart';

final class _AudioSettings extends StatelessWidget {
  const _AudioSettings({required this.settings, required this.onChanged});

  final ClientSettings settings;
  final ValueChanged<ClientSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final audio = settings.audio;
    final l10n = context.aonwL10n;
    return Column(
      children: [
        _AudioChannelSetting(
          name: 'sound',
          icon: Icons.graphic_eq_rounded,
          label: l10n.gameSoundsLabel,
          volumeLabel: l10n.soundVolumeLabel,
          enabled: audio.soundsEnabled,
          volume: audio.soundVolume,
          onEnabled: (value) => _update(audio.copyWith(soundsEnabled: value)),
          onVolume: (value) => _update(audio.copyWith(soundVolume: value)),
        ),
        const SizedBox(height: AonwSpacing.sm),
        _AudioChannelSetting(
          name: 'music',
          icon: Icons.music_note_outlined,
          label: l10n.gameMusicLabel,
          volumeLabel: l10n.musicVolumeLabel,
          enabled: audio.musicEnabled,
          volume: audio.musicVolume,
          onEnabled: (value) => _update(audio.copyWith(musicEnabled: value)),
          onVolume: (value) => _update(audio.copyWith(musicVolume: value)),
        ),
        const SizedBox(height: AonwSpacing.sm),
        _AudioChannelSetting(
          name: 'nature',
          icon: Icons.forest_outlined,
          label: l10n.natureSoundsLabel,
          volumeLabel: l10n.natureVolumeLabel,
          enabled: audio.natureEnabled,
          volume: audio.natureVolume,
          onEnabled: (value) => _update(audio.copyWith(natureEnabled: value)),
          onVolume: (value) => _update(audio.copyWith(natureVolume: value)),
        ),
      ],
    );
  }

  void _update(ClientAudioSettings audio) =>
      onChanged(settings.copyWith(audio: audio));
}

final class _AudioChannelSetting extends StatelessWidget {
  const _AudioChannelSetting({
    required this.name,
    required this.icon,
    required this.label,
    required this.volumeLabel,
    required this.enabled,
    required this.volume,
    required this.onEnabled,
    required this.onVolume,
  });

  final String name;
  final IconData icon;
  final String label;
  final String volumeLabel;
  final bool enabled;
  final double volume;
  final ValueChanged<bool> onEnabled;
  final ValueChanged<double> onVolume;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SwitchListTile.adaptive(
        key: ValueKey('$name-enabled-setting'),
        contentPadding: EdgeInsets.zero,
        secondary: Icon(icon),
        title: Text(label),
        value: enabled,
        onChanged: onEnabled,
      ),
      if (enabled)
        _LabeledSlider(
          key: ValueKey('$name-volume-setting'),
          label: volumeLabel,
          value: volume,
          minimum: 0,
          maximum: 1,
          divisions: 20,
          valueLabel: '${(volume * 100).round()}%',
          onChanged: onVolume,
        ),
    ],
  );
}
