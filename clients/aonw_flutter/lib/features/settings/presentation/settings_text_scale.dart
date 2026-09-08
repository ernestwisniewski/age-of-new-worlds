part of 'settings_screen.dart';

final class _TextScaleSetting extends StatelessWidget {
  const _TextScaleSetting({required this.settings, required this.onChanged});

  final ClientSettings settings;
  final ValueChanged<ClientSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final labels = <ClientTextScale, String>{
      ClientTextScale.standard: l10n.textScaleStandard,
      ClientTextScale.large: l10n.textScaleLarge,
      ClientTextScale.extraLarge: l10n.textScaleExtraLarge,
    };
    return InputDecorator(
      decoration: InputDecoration(
        labelText: l10n.textSize,
        helperText: l10n.textSizeDescription,
        helperMaxLines: 4,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ClientTextScale>(
          key: const ValueKey('text-scale-setting'),
          value: settings.textScale,
          isExpanded: true,
          itemHeight: null,
          style: Theme.of(context).textTheme.bodyLarge,
          items: [
            for (final value in ClientTextScale.values)
              DropdownMenuItem(
                value: value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AonwSpacing.sm),
                  child: Text(labels[value]!),
                ),
              ),
          ],
          onChanged: context.withGameSoundValue((value) {
            if (value != null) onChanged(settings.copyWith(textScale: value));
          }),
        ),
      ),
    );
  }
}
