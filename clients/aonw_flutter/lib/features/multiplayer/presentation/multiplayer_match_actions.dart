part of 'multiplayer_screen.dart';

final class _MatchActions extends StatelessWidget {
  const _MatchActions({
    required this.controller,
    required this.state,
    required this.openingGame,
    required this.onOpenGame,
  });

  final MultiplayerController controller;
  final MultiplayerInMatch state;
  final bool openingGame;
  final VoidCallback? onOpenGame;

  @override
  Widget build(BuildContext context) {
    final ready = state.phase == NetworkSessionPhase.ready;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OpenGameButton(
          enabled: ready && !state.commandPending,
          opening: openingGame,
          onPressed: onOpenGame,
        ),
        const SizedBox(height: AonwSpacing.sm),
        _SubmitTurnButton(
          enabled: ready && state.projection.canSubmitTurn,
          pending: state.commandPending,
          onPressed: controller.submitTurn,
        ),
        if (state.phase == NetworkSessionPhase.failed) ...[
          const SizedBox(height: AonwSpacing.sm),
          OutlinedButton.icon(
            key: const ValueKey('multiplayer-reconnect'),
            onPressed: controller.reconnect,
            icon: const Icon(Icons.sync),
            label: Text(context.aonwL10n.reconnect),
          ),
        ],
        const SizedBox(height: AonwSpacing.sm),
        TextButton(
          key: const ValueKey('multiplayer-leave-match'),
          onPressed: state.commandPending ? null : controller.leaveMatch,
          child: Text(context.aonwL10n.backToLobby),
        ),
      ],
    );
  }
}

final class _OpenGameButton extends StatelessWidget {
  const _OpenGameButton({
    required this.enabled,
    required this.opening,
    required this.onPressed,
  });

  final bool enabled;
  final bool opening;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    key: const ValueKey('multiplayer-open-game'),
    onPressed: enabled && !opening ? onPressed : null,
    icon: opening
        ? const SizedBox.square(
            dimension: AonwSizes.compactProgress,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.play_arrow),
    label: Text(context.aonwL10n.continueGame),
  );
}

final class _SubmitTurnButton extends StatelessWidget {
  const _SubmitTurnButton({
    required this.enabled,
    required this.pending,
    required this.onPressed,
  });

  final bool enabled;
  final bool pending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    key: const ValueKey('multiplayer-submit-turn'),
    onPressed: enabled && !pending ? onPressed : null,
    icon: pending
        ? const SizedBox.square(
            dimension: AonwSizes.compactProgress,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.done_all),
    label: Text(context.aonwL10n.submitTurn),
  );
}
