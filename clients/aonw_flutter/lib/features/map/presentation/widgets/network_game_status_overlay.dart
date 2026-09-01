import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../design_system/aonw_tokens.dart';
import '../../../../design_system/widgets/aonw_panel.dart';
import '../../../../design_system/widgets/aonw_progress_indicator.dart';
import '../../../../l10n/l10n.dart';
import '../../application/network_game_session_port.dart';

final class NetworkGameStatusOverlay extends StatelessWidget {
  const NetworkGameStatusOverlay({
    required this.connection,
    required this.onReconnect,
    super.key,
  });

  final NetworkGameConnectionView connection;
  final Future<bool> Function() onReconnect;

  @override
  Widget build(BuildContext context) => switch (connection.phase) {
    NetworkGameConnectionPhase.inactive ||
    NetworkGameConnectionPhase.ready => const SizedBox.shrink(),
    NetworkGameConnectionPhase.failed => Positioned.fill(
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: AonwMessagePanel(
            key: const ValueKey('network-game-failure'),
            semanticLabel: context.aonwL10n.multiplayerTitle,
            title: context.aonwL10n.multiplayerTitle,
            message: context.aonwL10n.multiplayerFailure(
              connection.failureCode!,
            ),
            actionLabel: context.aonwL10n.reconnect,
            onAction: () => unawaited(onReconnect()),
          ),
        ),
      ),
    ),
    final phase => Positioned(
      key: const ValueKey('network-game-progress'),
      top: AonwSpacing.md,
      right: AonwSpacing.md,
      child: AonwPanel(
        padding: const EdgeInsets.all(AonwSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AonwProgressIndicator(
              semanticLabel: context.aonwL10n.networkPhase(phase.name),
              compact: true,
            ),
            const SizedBox(width: AonwSpacing.sm),
            Text(context.aonwL10n.networkPhase(phase.name)),
          ],
        ),
      ),
    ),
  };
}
