part of 'settings_screen.dart';

final class _MovementCameraSettings extends StatelessWidget {
  const _MovementCameraSettings({
    required this.settings,
    required this.onChanged,
  });
  final ClientSettings settings;
  final ValueChanged<ClientSettings> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SwitchListTile.adaptive(
        key: const ValueKey('focusOwnUnitMovement-setting'),
        contentPadding: EdgeInsets.zero,
        title: Text(context.aonwL10n.focusOwnUnitMovement),
        value: settings.focusOwnUnitMovement,
        onChanged: (value) =>
            onChanged(settings.copyWith(focusOwnUnitMovement: value)),
      ),
      SwitchListTile.adaptive(
        key: const ValueKey('followOwnUnitMovement-setting'),
        contentPadding: EdgeInsets.zero,
        title: Text(context.aonwL10n.followOwnUnitMovement),
        value: settings.followOwnUnitMovement,
        onChanged: (value) =>
            onChanged(settings.copyWith(followOwnUnitMovement: value)),
      ),
      SwitchListTile.adaptive(
        key: const ValueKey('focusForeignUnitMovement-setting'),
        contentPadding: EdgeInsets.zero,
        title: Text(context.aonwL10n.focusForeignUnitMovement),
        value: settings.focusForeignUnitMovement,
        onChanged: (value) =>
            onChanged(settings.copyWith(focusForeignUnitMovement: value)),
      ),
      SwitchListTile.adaptive(
        key: const ValueKey('followForeignUnitMovement-setting'),
        contentPadding: EdgeInsets.zero,
        title: Text(context.aonwL10n.followForeignUnitMovement),
        value: settings.followForeignUnitMovement,
        onChanged: (value) =>
            onChanged(settings.copyWith(followForeignUnitMovement: value)),
      ),
    ],
  );
}
