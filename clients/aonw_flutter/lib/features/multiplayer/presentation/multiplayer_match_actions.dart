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
        _MatchParticipantActions(controller: controller, state: state),
        const SizedBox(height: AonwSpacing.lg),
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

final class _MatchParticipantActions extends StatelessWidget {
  const _MatchParticipantActions({
    required this.controller,
    required this.state,
  });

  final MultiplayerController controller;
  final MultiplayerInMatch state;

  @override
  Widget build(BuildContext context) {
    final participants = state.lobby.participants
        .where(
          (participant) => participant.kind == 'ai' || participant.isClaimed,
        )
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.aonwL10n.multiplayerParticipants,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AonwSpacing.xs),
        for (final participant in participants)
          _MatchParticipantTile(
            controller: controller,
            state: state,
            participant: participant,
          ),
      ],
    );
  }
}

final class _MatchParticipantTile extends StatelessWidget {
  const _MatchParticipantTile({
    required this.controller,
    required this.state,
    required this.participant,
  });

  final MultiplayerController controller;
  final MultiplayerInMatch state;
  final MultiplayerLobbyParticipantView participant;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final removable = _isRemovableParticipant(state, participant);
    return ListTile(
      key: ValueKey(('multiplayer-active-participant', participant.playerId)),
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        participant.kind == 'human'
            ? Icons.person_outline
            : Icons.smart_toy_outlined,
      ),
      title: Text(participant.name),
      subtitle: Text(
        [
          participant.kind == 'human'
              ? l10n.multiplayerHumanSeat
              : l10n.multiplayerAiSeat,
          if (participant.isHost) l10n.multiplayerHost,
          if (participant.isCurrentUser) l10n.multiplayerCurrentPlayer,
        ].join(' · '),
      ),
      trailing: removable
          ? IconButton(
              key: ValueKey(('multiplayer-kick', participant.playerId)),
              tooltip: l10n.multiplayerRemoveParticipant,
              onPressed: () => _confirmRemoval(context),
              icon: const Icon(Icons.person_remove_outlined),
            )
          : null,
    );
  }

  Future<void> _confirmRemoval(BuildContext context) async {
    final l10n = context.aonwL10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.multiplayerRemoveParticipantTitle),
        content: Text(l10n.multiplayerRemoveParticipantBody(participant.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelDialog),
          ),
          FilledButton(
            key: const ValueKey('multiplayer-confirm-kick'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.multiplayerRemoveParticipant),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await controller.kickParticipant(participant.playerId);
    }
  }
}

bool _isRemovableParticipant(
  MultiplayerInMatch state,
  MultiplayerLobbyParticipantView participant,
) => [
  state.phase == NetworkSessionPhase.ready,
  !state.commandPending,
  state.lobby.currentParticipant.isHost,
  participant.kind == 'human',
  participant.isClaimed,
  !participant.isHost,
  !participant.isCurrentUser,
].every((condition) => condition);

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
