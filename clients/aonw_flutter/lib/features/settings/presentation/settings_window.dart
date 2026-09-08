part of 'settings_screen.dart';

final class _WindowSettings extends StatelessWidget {
  const _WindowSettings();

  @override
  Widget build(BuildContext context) {
    final controller = WindowSettingsScope.of(context);
    if (controller == null || !controller.isSupported) {
      return const SizedBox.shrink();
    }
    final settings = controller.settings;
    final l10n = context.aonwL10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: AonwSpacing.md),
      child: _SettingsSection(
        title: l10n.windowSettingsTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WindowModePicker(controller: controller),
            if (settings.isBusy)
              Semantics(liveRegion: true, child: Text(l10n.windowSettingsBusy)),
            if (settings.failure case final failure?) ...[
              Semantics(
                liveRegion: true,
                child: Text(l10n.windowSettingsFailure(failure.name)),
              ),
              if (failure == WindowSettingsFailure.load)
                TextButton(
                  onPressed: settings.isBusy
                      ? null
                      : context.withGameSound(
                          () => unawaited(controller.load()),
                        ),
                  child: Text(l10n.retry),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _WindowModePicker extends StatelessWidget {
  const _WindowModePicker({required this.controller});

  final WindowSettingsController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return DropdownButtonHideUnderline(
      child: DropdownButton<WindowMode>(
        key: const ValueKey('window-mode-setting'),
        value: controller.settings.mode,
        isExpanded: true,
        itemHeight: null,
        style: Theme.of(context).textTheme.bodyLarge,
        items: [
          for (final mode in WindowMode.values)
            DropdownMenuItem(
              value: mode,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AonwSpacing.sm),
                child: Text(
                  mode == WindowMode.fullscreen
                      ? l10n.windowModeFullscreen
                      : l10n.windowModeWindowed,
                ),
              ),
            ),
        ],
        onChanged: controller.settings.isBusy
            ? null
            : context.withGameSoundValue((value) {
                if (value != null) unawaited(controller.setMode(value));
              }),
      ),
    );
  }
}
