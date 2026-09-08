part of 'settings_screen.dart';

final class _AiSettings extends StatelessWidget {
  const _AiSettings({required this.settings, required this.onChanged});

  final ClientSettings settings;
  final ValueChanged<ClientSettings> onChanged;

  @override
  Widget build(BuildContext context) => _MapSetting(
    key: const ValueKey('ai-battery-saver-setting'),
    title: context.aonwL10n.aiBatterySaver,
    description: context.aonwL10n.aiBatterySaverDescription,
    value: settings.ai.batterySaver,
    onChanged: (value) => onChanged(
      settings.copyWith(ai: settings.ai.copyWith(batterySaver: value)),
    ),
  );
}
