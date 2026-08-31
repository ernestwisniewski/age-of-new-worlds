part of 'main_menu_screen.dart';

final class _MenuPanel extends StatelessWidget {
  const _MenuPanel({
    required this.showBottomLinks,
    required this.showSynopsis,
    required this.onOpenSinglePlayer,
    required this.onOpenMultiplayer,
    required this.onOpenHotseat,
    required this.onOpenLoadGame,
    required this.onOpenSettings,
    required this.onOpenInstructions,
    required this.onOpenCredits,
    required this.onOpenFeedback,
    required this.onExit,
    required this.serverUpdateRequired,
  });

  final bool showBottomLinks;
  final bool showSynopsis;
  final VoidCallback onOpenSinglePlayer;
  final VoidCallback? onOpenMultiplayer;
  final VoidCallback? onOpenHotseat;
  final VoidCallback onOpenLoadGame;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenInstructions;
  final VoidCallback onOpenCredits;
  final VoidCallback onOpenFeedback;
  final AppExitRequest? onExit;
  final bool serverUpdateRequired;

  @override
  Widget build(BuildContext context) {
    final items = _itemsFor(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AonwColorTokens.background.withAlpha(236),
            AonwColorTokens.background.withAlpha(172),
            AonwColorTokens.background.withAlpha(54),
            AonwColorTokens.background.withAlpha(0),
          ],
          stops: const [0, 0.58, 0.82, 1],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 28, 12),
        child: _MenuPanelContent(panel: this, items: items),
      ),
    );
  }

  List<_MenuItem> _itemsFor(BuildContext context) {
    final l10n = context.aonwL10n;
    return [
      _MenuItem(
        key: const ValueKey('single-player'),
        icon: Icons.person_outline,
        label: l10n.singlePlayer,
        sublabel: l10n.singlePlayerSublabel,
        onPressed: onOpenSinglePlayer,
        primary: true,
      ),
      _MenuItem(
        key: const ValueKey('multiplayer'),
        icon: Icons.public,
        label: l10n.multiplayerTitle,
        sublabel: l10n.multiplayerSublabel,
        onPressed: onOpenMultiplayer,
        disabledMessage: l10n.multiplayerUnavailable,
      ),
      _MenuItem(
        key: const ValueKey('hotseat'),
        icon: Icons.groups_outlined,
        label: l10n.hotseat,
        sublabel: l10n.hotseatSublabel,
        onPressed: onOpenHotseat,
        disabledMessage: l10n.hotseatUnavailable,
      ),
      _MenuItem(
        key: const ValueKey('load-game'),
        icon: Icons.folder_open_outlined,
        label: l10n.loadGame,
        sublabel: l10n.loadGameSublabel,
        onPressed: onOpenLoadGame,
      ),
      _MenuItem(
        key: const ValueKey('menu-settings'),
        icon: Icons.settings_outlined,
        label: l10n.settingsTitle,
        onPressed: onOpenSettings,
      ),
      _MenuItem(
        key: const ValueKey('exit-game'),
        icon: Icons.logout,
        label: l10n.exitGame,
        onPressed: onExit == null ? null : () => unawaited(onExit!()),
      ),
    ];
  }
}

final class _MenuPanelContent extends StatelessWidget {
  const _MenuPanelContent({required this.panel, required this.items});

  final _MenuPanel panel;
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const _MenuLogo(),
      const SizedBox(height: 6),
      const AonwGoldDivider(width: 146),
      const SizedBox(height: 10),
      _MenuSynopsis(
        compact: panel.showBottomLinks,
        visible: panel.showSynopsis,
        serverUpdateRequired: panel.serverUpdateRequired,
      ),
      const SizedBox(height: 12),
      Expanded(
        child: SingleChildScrollView(
          child: Column(
            children: [
              for (final item in items) ...[
                _MenuButton(item: item),
                const SizedBox(height: 9),
              ],
            ],
          ),
        ),
      ),
      if (panel.showBottomLinks) ...[
        const SizedBox(height: 8),
        _BottomLinks(
          onOpenInstructions: panel.onOpenInstructions,
          onOpenCredits: panel.onOpenCredits,
          onOpenFeedback: panel.onOpenFeedback,
        ),
      ],
    ],
  );
}

final class _MenuItem {
  const _MenuItem({
    required this.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.sublabel,
    this.disabledMessage,
    this.primary = false,
  });

  final Key key;
  final IconData icon;
  final String label;
  final String? sublabel;
  final String? disabledMessage;
  final VoidCallback? onPressed;
  final bool primary;
}
