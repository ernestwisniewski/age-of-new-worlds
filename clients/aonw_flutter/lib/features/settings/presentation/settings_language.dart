part of 'settings_screen.dart';

final class _LanguageSetting extends StatelessWidget {
  const _LanguageSetting({required this.settings, required this.onChanged});

  final ClientSettings settings;
  final ValueChanged<ClientSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final labels = <ClientLanguage, String>{
      ClientLanguage.system: l10n.languageSystem,
      ClientLanguage.polish: 'Polski',
      ClientLanguage.english: 'English',
      ClientLanguage.french: 'Français',
    };
    return DropdownButtonHideUnderline(
      child: DropdownButton<ClientLanguage>(
        key: const ValueKey('language-setting'),
        value: settings.language,
        isExpanded: true,
        itemHeight: null,
        style: Theme.of(context).textTheme.bodyLarge,
        items: [
          for (final language in ClientLanguage.values)
            DropdownMenuItem(
              value: language,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AonwSpacing.sm),
                child: Text(labels[language]!),
              ),
            ),
        ],
        onChanged: context.withGameSoundValue((value) {
          if (value != null) onChanged(settings.copyWith(language: value));
        }),
      ),
    );
  }
}
