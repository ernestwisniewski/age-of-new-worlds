import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/platform/app_platform_actions.dart';
import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_menu_backdrop.dart';
import '../../../design_system/widgets/aonw_panel.dart';
import '../../../l10n/l10n.dart';

final class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({
    required this.onOpenSinglePlayer,
    required this.onOpenMultiplayer,
    required this.onOpenHotseat,
    required this.onOpenLoadGame,
    required this.onOpenSettings,
    required this.onOpenInstructions,
    required this.onOpenCredits,
    required this.onOpenFeedback,
    this.onExit,
    this.serverUpdateRequired = false,
    super.key,
  });

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
  Widget build(BuildContext context) => Scaffold(
    body: AonwMenuBackdrop(
      child: SafeArea(
        child: _MenuLayout(
          child: _MenuContent(
            onOpenSinglePlayer: onOpenSinglePlayer,
            onOpenMultiplayer: onOpenMultiplayer,
            onOpenHotseat: onOpenHotseat,
            onOpenLoadGame: onOpenLoadGame,
            onOpenSettings: onOpenSettings,
            onOpenInstructions: onOpenInstructions,
            onOpenCredits: onOpenCredits,
            onOpenFeedback: onOpenFeedback,
            onExit: onExit,
            serverUpdateRequired: serverUpdateRequired,
          ),
        ),
      ),
    ),
  );
}

final class _MenuLayout extends StatelessWidget {
  const _MenuLayout({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _buildLayout);

  Widget _buildLayout(BuildContext context, BoxConstraints constraints) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(AonwSpacing.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight - (AonwSpacing.lg * 2),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: child,
            ),
          ),
        ),
      );
}

final class _MenuContent extends StatelessWidget {
  const _MenuContent({
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
    final l10n = context.aonwL10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _MenuLogo(),
        const SizedBox(height: AonwSpacing.sm),
        Text(
          l10n.mainMenuWelcome,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AonwColorTokens.textPrimary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AonwSpacing.lg),
        _MenuActions(
          onOpenSinglePlayer: onOpenSinglePlayer,
          onOpenMultiplayer: onOpenMultiplayer,
          onOpenHotseat: onOpenHotseat,
          onOpenLoadGame: onOpenLoadGame,
          onOpenSettings: onOpenSettings,
          onExit: onExit,
        ),
        if (serverUpdateRequired) ...[
          const SizedBox(height: AonwSpacing.md),
          _UpdateNotice(message: l10n.serverUpdateSoon),
        ],
        const SizedBox(height: AonwSpacing.md),
        _BottomLinks(
          onOpenInstructions: onOpenInstructions,
          onOpenCredits: onOpenCredits,
          onOpenFeedback: onOpenFeedback,
        ),
      ],
    );
  }
}

final class _MenuLogo extends StatelessWidget {
  const _MenuLogo();

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Image.asset(
      aonwLogoAsset,
      width: 270,
      height: 178,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    ),
  );
}

final class _MenuActions extends StatelessWidget {
  const _MenuActions({
    required this.onOpenSinglePlayer,
    required this.onOpenMultiplayer,
    required this.onOpenHotseat,
    required this.onOpenLoadGame,
    required this.onOpenSettings,
    required this.onExit,
  });

  final VoidCallback onOpenSinglePlayer;
  final VoidCallback? onOpenMultiplayer;
  final VoidCallback? onOpenHotseat;
  final VoidCallback onOpenLoadGame;
  final VoidCallback onOpenSettings;
  final AppExitRequest? onExit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final entries = [
      _MenuEntry(
        const ValueKey('single-player'),
        Icons.person_outline,
        l10n.singlePlayer,
        onOpenSinglePlayer,
        sublabel: l10n.singlePlayerSublabel,
        primary: true,
      ),
      _MenuEntry(
        const ValueKey('multiplayer'),
        Icons.public,
        l10n.multiplayerTitle,
        onOpenMultiplayer,
        sublabel: l10n.multiplayerSublabel,
        disabledMessage: l10n.multiplayerUnavailable,
      ),
      _MenuEntry(
        const ValueKey('hotseat'),
        Icons.groups_outlined,
        l10n.hotseat,
        onOpenHotseat,
        sublabel: l10n.hotseatSublabel,
        disabledMessage: l10n.hotseatUnavailable,
      ),
      _MenuEntry(
        const ValueKey('load-game'),
        Icons.folder_open_outlined,
        l10n.loadGame,
        onOpenLoadGame,
        sublabel: l10n.loadGameSublabel,
      ),
      _MenuEntry(
        const ValueKey('menu-settings'),
        Icons.settings_outlined,
        l10n.settingsTitle,
        onOpenSettings,
      ),
      _MenuEntry(
        const ValueKey('exit-game'),
        Icons.logout,
        l10n.exitGame,
        onExit == null ? null : () => unawaited(onExit!()),
      ),
    ];
    return AonwPanel(
      semanticLabel: l10n.mainMenuTitle,
      padding: const EdgeInsets.all(AonwSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final entry in entries) _MenuButton(entry: entry)],
      ),
    );
  }
}

final class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.entry});

  final _MenuEntry entry;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      children: [
        Icon(entry.icon, size: 21),
        const SizedBox(width: AonwSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.label),
              if (entry.sublabel case final text?)
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AonwColorTokens.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, size: 18),
      ],
    );
    final style = ButtonStyle(
      alignment: Alignment.centerLeft,
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: AonwSpacing.lg),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: AonwTypography.headingFamily,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final button = Padding(
      key: entry.key,
      padding: const EdgeInsets.only(bottom: AonwSpacing.sm),
      child: SizedBox(
        height: 58,
        child: entry.primary
            ? FilledButton(
                onPressed: entry.onPressed,
                style: style,
                child: child,
              )
            : OutlinedButton(
                onPressed: entry.onPressed,
                style: style,
                child: child,
              ),
      ),
    );
    return entry.onPressed == null && entry.disabledMessage != null
        ? Tooltip(message: entry.disabledMessage!, child: button)
        : button;
  }
}

final class _MenuEntry {
  const _MenuEntry(
    this.key,
    this.icon,
    this.label,
    this.onPressed, {
    this.sublabel,
    this.disabledMessage,
    this.primary = false,
  });

  final Key key;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final String? sublabel;
  final String? disabledMessage;
  final bool primary;
}

final class _BottomLinks extends StatelessWidget {
  const _BottomLinks({
    required this.onOpenInstructions,
    required this.onOpenCredits,
    required this.onOpenFeedback,
  });

  final VoidCallback onOpenInstructions;
  final VoidCallback onOpenCredits;
  final VoidCallback onOpenFeedback;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: AonwSpacing.sm,
    runSpacing: AonwSpacing.sm,
    children: [
      TextButton.icon(
        key: const ValueKey('menu-help'),
        onPressed: onOpenInstructions,
        icon: const Icon(Icons.menu_book_outlined),
        label: Text(context.aonwL10n.instructions),
      ),
      TextButton.icon(
        key: const ValueKey('menu-credits'),
        onPressed: onOpenCredits,
        icon: const Icon(Icons.star_border),
        label: Text(context.aonwL10n.creditsTitle),
      ),
      TextButton.icon(
        key: const ValueKey('menu-feedback'),
        onPressed: onOpenFeedback,
        icon: const Icon(Icons.chat_bubble_outline),
        label: Text(context.aonwL10n.feedbackTitle),
      ),
    ],
  );
}

final class _UpdateNotice extends StatelessWidget {
  const _UpdateNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => AonwPanel(
    semanticLabel: message,
    liveRegion: true,
    child: Row(
      children: [
        const Icon(Icons.system_update_alt, color: AonwColorTokens.brandLight),
        const SizedBox(width: AonwSpacing.md),
        Expanded(child: Text(message)),
      ],
    ),
  );
}
