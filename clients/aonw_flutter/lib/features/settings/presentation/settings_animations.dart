part of 'settings_screen.dart';

final class _AnimationSettings extends StatelessWidget {
  const _AnimationSettings({required this.settings, required this.onChanged});

  final ClientSettings settings;
  final ValueChanged<ClientSettings> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SwitchListTile.adaptive(
        key: const ValueKey('unit-movement-animations-setting'),
        contentPadding: EdgeInsets.zero,
        title: Text(context.aonwL10n.showUnitMovementAnimations),
        value: settings.showUnitMovementAnimations,
        onChanged: (value) =>
            onChanged(settings.copyWith(showUnitMovementAnimations: value)),
      ),
      SwitchListTile.adaptive(
        key: const ValueKey('combat-animations-setting'),
        contentPadding: EdgeInsets.zero,
        title: Text(context.aonwL10n.showCombatAnimations),
        value: settings.showCombatAnimations,
        onChanged: (value) =>
            onChanged(settings.copyWith(showCombatAnimations: value)),
      ),
    ],
  );
}
