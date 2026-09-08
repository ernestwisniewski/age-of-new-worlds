part of 'settings_screen.dart';

final class _GamepadBindingsSettings extends StatelessWidget {
  const _GamepadBindingsSettings({
    required this.settings,
    required this.onChanged,
  });

  final ClientGamepadSettings settings;
  final ValueChanged<ClientGamepadSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.gamepadButtonBindings,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AonwSpacing.sm),
        for (final action in GamepadButtonAction.values)
          _button(context, action),
        const SizedBox(height: AonwSpacing.md),
        Text(
          l10n.gamepadAxisBindings,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AonwSpacing.sm),
        for (final action in GamepadAxisAction.values) _axis(context, action),
        OutlinedButton.icon(
          key: const ValueKey('gamepad-reset-bindings'),
          onPressed: context.withGameSound(
            () => onChanged(
              settings.copyWith(bindings: GamepadBindings.defaults),
            ),
          ),
          icon: const Icon(Icons.restore),
          label: Text(l10n.gamepadResetBindings),
        ),
      ],
    );
  }

  Widget _button(BuildContext context, GamepadButtonAction action) {
    final l10n = context.aonwL10n;
    final selected = settings.bindings.buttonsFor(action);
    return _GamepadBindingField<GamepadButtonControl>(
      key: ValueKey('gamepad-button-${action.name}'),
      label: _buttonActionLabel(l10n, action),
      value: selected.firstOrNull,
      currentLabel: selected.isEmpty
          ? l10n.gamepadUnassigned
          : selected
                .map((value) => _buttonControlLabel(l10n, value))
                .join(' / '),
      values: GamepadButtonControl.values,
      labelFor: (value) => _buttonControlLabel(l10n, value),
      assignmentFor: (value) {
        final assigned = settings.bindings.buttons[value];
        return assigned == null || assigned == action
            ? null
            : l10n.gamepadAssignedTo(_buttonActionLabel(l10n, assigned));
      },
      onChanged: (value) => onChanged(
        settings.copyWith(
          bindings: settings.bindings.bindButton(action, value),
        ),
      ),
    );
  }

  Widget _axis(BuildContext context, GamepadAxisAction action) {
    final l10n = context.aonwL10n;
    final selected = settings.bindings.axisFor(action);
    return _GamepadBindingField<GamepadAxisControl>(
      key: ValueKey('gamepad-axis-${action.name}'),
      label: _axisActionLabel(l10n, action),
      value: selected,
      currentLabel: selected == null
          ? l10n.gamepadUnassigned
          : _axisControlLabel(l10n, selected),
      values: GamepadAxisControl.values,
      labelFor: (value) => _axisControlLabel(l10n, value),
      assignmentFor: (value) {
        final assigned = settings.bindings.axes[value];
        return assigned == null || assigned == action
            ? null
            : l10n.gamepadAssignedTo(_axisActionLabel(l10n, assigned));
      },
      onChanged: (value) => onChanged(
        settings.copyWith(bindings: settings.bindings.bindAxis(action, value)),
      ),
    );
  }
}

final class _GamepadBindingField<T extends Enum> extends StatelessWidget {
  const _GamepadBindingField({
    required this.label,
    required this.value,
    required this.currentLabel,
    required this.values,
    required this.labelFor,
    required this.assignmentFor,
    required this.onChanged,
    super.key,
  });

  final String label;
  final T? value;
  final String currentLabel;
  final List<T> values;
  final String Function(T) labelFor;
  final String? Function(T) assignmentFor;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AonwSpacing.sm),
    child: InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          style: Theme.of(context).textTheme.bodyLarge,
          hint: Text(currentLabel),
          isExpanded: true,
          itemHeight: null,
          menuMaxHeight: 360,
          onChanged: context.withGameSoundValue(onChanged),
          selectedItemBuilder: (context) => [
            for (var index = 0; index <= values.length; index++)
              SizedBox(
                height: 48 * MediaQuery.textScalerOf(context).scale(16) / 16,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    currentLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
          items: [
            DropdownMenuItem<T>(
              key: const ValueKey('gamepad-binding-unassigned'),
              child: Text(context.aonwL10n.gamepadUnassigned),
            ),
            for (final control in values) _item(context, control),
          ],
        ),
      ),
    ),
  );

  DropdownMenuItem<T> _item(BuildContext context, T control) =>
      DropdownMenuItem<T>(
        value: control,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AonwSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(labelFor(control)),
              if (assignmentFor(control) case final assignment?)
                Text(
                  assignment,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      );
}
