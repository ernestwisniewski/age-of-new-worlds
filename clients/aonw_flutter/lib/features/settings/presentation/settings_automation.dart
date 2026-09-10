part of 'settings_screen.dart';

final class _AutomationSettings extends StatelessWidget {
  const _AutomationSettings({required this.settings, required this.onChanged});

  final ClientSettings settings;
  final ValueChanged<ClientSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Column(
      children: [
        SwitchListTile.adaptive(
          key: const ValueKey('research-discoveries-setting'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.showResearchDiscoveries),
          value: settings.showResearchDiscoveries,
          onChanged: (value) =>
              onChanged(settings.copyWith(showResearchDiscoveries: value)),
        ),
        _MapSetting(
          key: const ValueKey('advance-actions-setting'),
          title: l10n.advanceActions,
          description: l10n.advanceActionsDescription,
          value: settings.automation.advanceActions,
          onChanged: (value) => onChanged(
            settings.copyWith(
              automation: settings.automation.copyWith(advanceActions: value),
            ),
          ),
        ),
        _MapSetting(
          key: const ValueKey('automatic-end-turn-setting'),
          title: l10n.automaticEndTurn,
          description: l10n.automaticEndTurnDescription,
          value: settings.automation.endTurn,
          onChanged: (value) => onChanged(
            settings.copyWith(
              automation: settings.automation.copyWith(endTurn: value),
            ),
          ),
        ),
      ],
    );
  }
}
