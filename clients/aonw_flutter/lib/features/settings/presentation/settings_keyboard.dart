part of 'settings_screen.dart';

final class _KeyboardSettings extends StatelessWidget {
  const _KeyboardSettings();

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final entries = <(String, String)>[
      (l10n.keyboardPanKeys, l10n.keyboardPan),
      ('Enter', l10n.keyboardSelect),
      ('M', l10n.keyboardMove),
      ('I', l10n.keyboardInspect),
      ('R', l10n.keyboardMapMode),
      ('[ / ]', l10n.keyboardPending),
      (l10n.keyboardSpace, l10n.keyboardPrimary),
      ('Esc', l10n.keyboardCancel),
      ('Tab / Shift + Tab', l10n.keyboardFocus),
    ];
    return AonwPanel(
      maxWidth: 720,
      child: ExpansionTile(
        key: const PageStorageKey('keyboard-settings'),
        tilePadding: EdgeInsets.zero,
        title: Text(
          l10n.keyboardSettings,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        children: [
          Text(l10n.keyboardScope),
          const SizedBox(height: AonwSpacing.md),
          for (final (keys, action) in entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(keys),
              subtitle: Text(action),
            ),
        ],
      ),
    );
  }
}
