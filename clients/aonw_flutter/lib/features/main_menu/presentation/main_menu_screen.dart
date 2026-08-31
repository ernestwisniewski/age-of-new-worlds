import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/platform/app_platform_actions.dart';
import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_gold_divider.dart';
import '../../../design_system/widgets/aonw_menu_backdrop.dart';
import '../../../l10n/l10n.dart';

part 'main_menu_panel.dart';
part 'main_menu_widgets.dart';
part 'main_menu_info_widgets.dart';

const _wideMenuInfoBreakpoint = 700.0;

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
    backgroundColor: AonwColorTokens.background,
    body: AonwMenuBackdrop(child: LayoutBuilder(builder: _buildMenuLayout)),
  );

  Widget _buildMenuLayout(BuildContext context, BoxConstraints constraints) =>
      Stack(
        fit: StackFit.expand,
        children: [
          const _MenuBackgroundOverlay(),
          SafeArea(child: _buildMenuPanel(context, constraints)),
          if (constraints.maxWidth >= _wideMenuInfoBreakpoint)
            Positioned(
              right: 18,
              bottom: 18,
              child: SafeArea(
                child: _WideInfoColumn(
                  serverUpdateRequired: serverUpdateRequired,
                  onOpenInstructions: onOpenInstructions,
                  onOpenCredits: onOpenCredits,
                  onOpenFeedback: onOpenFeedback,
                ),
              ),
            ),
        ],
      );

  Widget _buildMenuPanel(BuildContext context, BoxConstraints constraints) {
    final compact = constraints.maxWidth < 700;
    final showBottomLinks = constraints.maxWidth < _wideMenuInfoBreakpoint;
    final panelWidth = compact
        ? constraints.maxWidth
        : constraints.maxWidth.clamp(340.0, 390.0).toDouble();
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        key: const ValueKey('main-menu-panel'),
        width: panelWidth,
        child: _MenuPanel(
          showBottomLinks: showBottomLinks,
          showSynopsis: constraints.maxHeight >= 760,
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
    );
  }
}
