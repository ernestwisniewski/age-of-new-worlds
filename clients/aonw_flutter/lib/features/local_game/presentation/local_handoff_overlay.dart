import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_panel.dart';
import '../../../l10n/l10n.dart';
import '../application/local_handoff_state.dart';

final class LocalHandoffOverlay extends StatelessWidget {
  const LocalHandoffOverlay({
    required this.state,
    required this.onConfirm,
    required this.onRetry,
    super.key,
  });

  final LocalHandoffState state;
  final VoidCallback onConfirm;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (!state.blocksGameplay) return const SizedBox.shrink();
    return Stack(
      key: const ValueKey('local-handoff-overlay'),
      children: [
        const ModalBarrier(
          dismissible: false,
          color: AonwColorTokens.background,
        ),
        _LocalHandoffPanel(
          state: state,
          onConfirm: onConfirm,
          onRetry: onRetry,
        ),
      ],
    );
  }
}

final class _LocalHandoffPanel extends StatelessWidget {
  const _LocalHandoffPanel({
    required this.state,
    required this.onConfirm,
    required this.onRetry,
  });

  final LocalHandoffState state;
  final VoidCallback onConfirm;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final playerName = state.playerName!;
    final failed = state.phase == LocalHandoffPhase.failed;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AonwSpacing.lg),
        child: AonwPanel(
          semanticLabel: l10n.hotseatHandoffTitle,
          liveRegion: true,
          maxWidth: 520,
          padding: const EdgeInsets.all(AonwSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.visibility_off_outlined, size: 48),
              const SizedBox(height: AonwSpacing.lg),
              Text(
                l10n.hotseatHandoffTitle,
                style: Theme.of(context).textTheme.headlineSmall,
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
        ),
      ),
    );
  }

  Widget _action(AonwLocalizations l10n, String playerName, bool failed) {
    final switching = state.phase == LocalHandoffPhase.switching;
    return FilledButton.icon(
      key: ValueKey(failed ? 'retry-local-handoff' : 'confirm-local-handoff'),
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
      ),
    );
  }
}
