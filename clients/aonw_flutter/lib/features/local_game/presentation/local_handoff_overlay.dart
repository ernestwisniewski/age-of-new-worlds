import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../l10n/l10n.dart';
import '../../map/presentation/input/map_gamepad_navigation.dart';
import '../../map/presentation/widgets/map_gamepad_region.dart';
import '../application/local_handoff_state.dart';

part 'local_handoff_identity.dart';

final class LocalHandoffOverlay extends StatelessWidget {
  const LocalHandoffOverlay({
    required this.state,
    required this.onConfirm,
    required this.onRetry,
    this.playerColorValue,
    this.turnNumber,
    super.key,
  });

  final LocalHandoffState state;
  final VoidCallback onConfirm;
  final VoidCallback onRetry;
  final int? playerColorValue;
  final int? turnNumber;

  @override
  Widget build(BuildContext context) {
    if (!state.blocksGameplay) return const SizedBox.shrink();
    return BlockSemantics(
      child: Stack(
        key: const ValueKey('local-handoff-overlay'),
        children: [
          const ModalBarrier(
            dismissible: false,
            color: AonwColorTokens.background,
          ),
          MapGamepadRegion(
            section: MapHudSection.globalActions,
            priority: MapGamepadPriority.modal,
            scrollBeforeFocus: true,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.all(AonwSpacing.lg),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 2 * AonwSpacing.lg)
                          .clamp(0, double.infinity),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 520,
                        child: _LocalHandoffPanel(
                          state: state,
                          playerColorValue: playerColorValue,
                          turnNumber: turnNumber,
                          onConfirm: onConfirm,
                          onRetry: onRetry,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _LocalHandoffPanel extends StatelessWidget {
  const _LocalHandoffPanel({
    required this.state,
    required this.onConfirm,
    required this.onRetry,
    required this.playerColorValue,
    required this.turnNumber,
  });

  final LocalHandoffState state;
  final VoidCallback onConfirm;
  final VoidCallback onRetry;
  final int? playerColorValue;
  final int? turnNumber;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final playerName = state.playerName!;
    final failed = state.phase == LocalHandoffPhase.failed;
    return Semantics(
      container: true,
      liveRegion: true,
      label: l10n.hotseatHandoffTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LocalHandoffIdentity(
            playerName: playerName,
            colorValue: playerColorValue,
            turnNumber: state.phase == LocalHandoffPhase.awaitingConfirmation
                ? turnNumber
                : null,
          ),
          const SizedBox(height: AonwSpacing.xl),
          Text(
            l10n.hotseatHandoffTitle,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AonwSpacing.md),
          Text(
            failed
                ? l10n.hotseatHandoffFailure
                : l10n.hotseatHandoffBody(playerName),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AonwSpacing.xl),
          _action(l10n, playerName, failed),
        ],
      ),
    );
  }

  Widget _action(AonwLocalizations l10n, String playerName, bool failed) {
    final switching = state.phase == LocalHandoffPhase.switching;
    return FilledButton.icon(
      key: ValueKey(failed ? 'retry-local-handoff' : 'confirm-local-handoff'),
      autofocus: true,
      style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
      onPressed: switching
          ? null
          : failed
          ? onRetry
          : onConfirm,
      icon: switching
          ? const SizedBox.square(
              dimension: AonwSizes.compactProgress,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(failed ? Icons.refresh : Icons.play_arrow),
      label: Text(
        switching
            ? l10n.hotseatHandoffSwitching
            : failed
            ? l10n.retry
            : l10n.hotseatContinueAs(playerName),
        textAlign: TextAlign.center,
      ),
    );
  }
}
