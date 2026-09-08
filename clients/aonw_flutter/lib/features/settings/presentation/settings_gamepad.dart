part of 'settings_screen.dart';

final class _GamepadSettings extends StatelessWidget {
  const _GamepadSettings({required this.settings, required this.onChanged});

  final ClientSettings settings;
  final ValueChanged<ClientSettings> onChanged;

  void _update(ClientGamepadSettings value) =>
      onChanged(settings.copyWith(gamepad: value));

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final gamepad = settings.gamepad;
    return AonwPanel(
      maxWidth: 720,
      child: ExpansionTile(
        key: const PageStorageKey('gamepad-settings'),
        tilePadding: EdgeInsets.zero,
        title: Text(
          l10n.gamepadSettings,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        children: [
          SwitchListTile.adaptive(
            key: const ValueKey('gamepad-enabled-setting'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.gamepadEnabled),
            value: gamepad.enabled,
            onChanged: context.withGameSoundValue(
              (value) => _update(gamepad.copyWith(enabled: value)),
            ),
          ),
          if (gamepad.enabled) ...[
            ..._controls(context),
            const SizedBox(height: AonwSpacing.md),
            _GamepadBindingsSettings(settings: gamepad, onChanged: _update),
          ],
        ],
      ),
    );
  }

  List<Widget> _controls(BuildContext context) {
    final l10n = context.aonwL10n;
    final gamepad = settings.gamepad;
    return [
      _LabeledSlider(
        key: const ValueKey('gamepad-deadzone-setting'),
        label: l10n.gamepadDeadzone,
        value: gamepad.deadzone,
        minimum: 0,
        maximum: 0.6,
        divisions: 12,
        valueLabel: '${(gamepad.deadzone * 100).round()}%',
        onChanged: (value) => _update(gamepad.copyWith(deadzone: value)),
      ),
      _LabeledSlider(
        key: const ValueKey('gamepad-camera-sensitivity-setting'),
        label: l10n.gamepadCameraSensitivity,
        value: gamepad.cameraSensitivity,
        minimum: 0.2,
        maximum: 2,
        divisions: 18,
        valueLabel: '${gamepad.cameraSensitivity.toStringAsFixed(1)}×',
        onChanged: (value) =>
            _update(gamepad.copyWith(cameraSensitivity: value)),
      ),
      SwitchListTile.adaptive(
        key: const ValueKey('gamepad-invert-camera-y-setting'),
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.gamepadInvertCameraY),
        value: gamepad.invertCameraY,
        onChanged: context.withGameSoundValue(
          (value) => _update(gamepad.copyWith(invertCameraY: value)),
        ),
      ),
    ];
  }
}
