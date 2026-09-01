part of 'multiplayer_screen.dart';

final class _WaitingRoomPanel extends StatelessWidget {
  const _WaitingRoomPanel({required this.controller, required this.state});

  final MultiplayerController controller;
  final MultiplayerWaitingRoom state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Center(
      child: ListView(
        padding: const EdgeInsets.all(AonwSpacing.lg),
        shrinkWrap: true,
        children: [
          AonwPanel(
            semanticLabel: l10n.multiplayerWaitingRoomTitle,
            maxWidth: 680,
            padding: const EdgeInsets.all(AonwSpacing.xl),
            child: _WaitingRoomContent(controller: controller, state: state),
          ),
        ],
      ),
    );
  }
}

final class _WaitingRoomContent extends StatelessWidget {
  const _WaitingRoomContent({required this.controller, required this.state});

  final MultiplayerController controller;
  final MultiplayerWaitingRoom state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.multiplayerWaitingRoomTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AonwSpacing.xs),
        SelectableText(l10n.matchIdentifier(state.lobby.match.matchId)),
        const SizedBox(height: AonwSpacing.lg),
        for (final participant in state.lobby.participants)
          _LobbyParticipantTile(participant: participant),
        _WaitingRoomStatus(state: state),
        const SizedBox(height: AonwSpacing.lg),
        _WaitingRoomActions(controller: controller, state: state),
      ],
    );
  }
}

final class _WaitingRoomStatus extends StatelessWidget {
  const _WaitingRoomStatus({required this.state});

  final MultiplayerWaitingRoom state;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (state.failureCode case final code?) ...[
        const SizedBox(height: AonwSpacing.sm),
        _FailureText(code: code),
      ],
      if (state.busy) ...[
        const SizedBox(height: AonwSpacing.md),
        AonwProgressIndicator(
          semanticLabel: context.aonwL10n.loadingMultiplayer,
        ),
      ],
    ],
  );
}

final class _WaitingRoomActions extends StatelessWidget {
  const _WaitingRoomActions({required this.controller, required this.state});

  final MultiplayerController controller;
  final MultiplayerWaitingRoom state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final current = state.lobby.currentParticipant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          key: const ValueKey('multiplayer-ready'),
          onPressed: state.busy
              ? null
              : () => controller.setReady(!current.isReady),
          icon: Icon(
            current.isReady ? Icons.close : Icons.check_circle_outline,
          ),
          label: Text(current.isReady ? l10n.markNotReady : l10n.markReady),
        ),
        _HostStartAction(controller: controller, state: state),
        const SizedBox(height: AonwSpacing.sm),
        OutlinedButton.icon(
          key: const ValueKey('multiplayer-leave-lobby'),
          onPressed: state.busy ? null : controller.leaveWaitingRoom,
          icon: const Icon(Icons.exit_to_app),
          label: Text(l10n.leaveMultiplayerMatch),
        ),
        const SizedBox(height: AonwSpacing.sm),
        _WaitingRoomNavigation(controller: controller, busy: state.busy),
      ],
    );
  }
}

final class _HostStartAction extends StatelessWidget {
  const _HostStartAction({required this.controller, required this.state});

  final MultiplayerController controller;
  final MultiplayerWaitingRoom state;

  @override
  Widget build(BuildContext context) {
    if (!state.lobby.currentParticipant.isHost) {
      return const SizedBox.shrink();
    }
    final l10n = context.aonwL10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AonwSpacing.sm),
        FilledButton.icon(
          key: const ValueKey('multiplayer-start-match'),
          onPressed: state.busy || !state.lobby.canStart
              ? null
              : controller.startMatch,
          icon: const Icon(Icons.play_arrow),
          label: Text(l10n.startGame),
        ),
        if (!state.lobby.canStart) ...[
          const SizedBox(height: AonwSpacing.xs),
          Text(
            l10n.waitingForPlayers,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

final class _WaitingRoomNavigation extends StatelessWidget {
  const _WaitingRoomNavigation({required this.controller, required this.busy});

  final MultiplayerController controller;
  final bool busy;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      TextButton.icon(
        key: const ValueKey('multiplayer-refresh-lobby'),
        onPressed: busy ? null : controller.refreshMatchLobby,
        icon: const Icon(Icons.refresh),
        label: Text(context.aonwL10n.refreshMatch),
      ),
      const Spacer(),
      TextButton(
        key: const ValueKey('multiplayer-close-waiting-room'),
        onPressed: busy ? null : controller.closeWaitingRoom,
        child: Text(context.aonwL10n.backToLobby),
      ),
    ],
  );
}

final class _LobbyMatchCard extends StatelessWidget {
  const _LobbyMatchCard({
    required this.controller,
    required this.match,
    required this.busy,
  });

  final MultiplayerController controller;
  final MultiplayerMatchView match;
  final bool busy;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      key: ValueKey(('multiplayer-match', match.matchId)),
      title: Text(match.mapId),
      subtitle: Text(
        '${context.aonwL10n.multiplayerMatchPhase(match.phase.name)}\n'
        '${context.aonwL10n.matchRevision(match.revision, match.eventOffset)}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: busy ? null : () => controller.openMatch(match),
    ),
  );
}

final class _LobbyParticipantTile extends StatelessWidget {
  const _LobbyParticipantTile({required this.participant});

  final MultiplayerLobbyParticipantView participant;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final human = participant.kind == 'human';
    final ready = participant.isReady;
    final title = participant.isClaimed || !human
        ? participant.name
        : l10n.multiplayerSeatOpen;
    return ListTile(
      key: ValueKey(('multiplayer-participant', participant.playerId)),
      contentPadding: EdgeInsets.zero,
      leading: Icon(human ? Icons.person_outline : Icons.smart_toy_outlined),
      title: Text(title),
      subtitle: Text(
        [
          human ? l10n.multiplayerHumanSeat : l10n.multiplayerAiSeat,
          if (participant.isHost) l10n.multiplayerHost,
          if (participant.isCurrentUser) l10n.multiplayerCurrentPlayer,
        ].join(' · '),
      ),
      trailing: Chip(
        avatar: Icon(ready ? Icons.check : Icons.hourglass_empty, size: 18),
        label: Text(ready ? l10n.multiplayerReady : l10n.multiplayerNotReady),
      ),
    );
  }
}
