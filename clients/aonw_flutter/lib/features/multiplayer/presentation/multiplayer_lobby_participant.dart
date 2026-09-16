part of 'multiplayer_screen.dart';

final class _LobbyParticipantTile extends StatelessWidget {
  const _LobbyParticipantTile({
    required this.participant,
    required this.connection,
  });

  final MultiplayerLobbyParticipantView participant;
  final LobbyConnectionPhase connection;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final human = participant.kind == 'human';
    final ready = participant.isReady;
    final statusName = _statusName(human, ready);
    final title = participant.isClaimed || !human
        ? participant.name
        : l10n.multiplayerSeatOpen;
    final details = Text(
      [
        l10n.countryName(participant.country),
        human ? l10n.multiplayerHumanSeat : l10n.multiplayerAiSeat,
        if (participant.isHost) l10n.multiplayerHost,
        if (participant.isCurrentUser) l10n.multiplayerCurrentPlayer,
      ].join(' · '),
    );
    final status = Chip(
      avatar: Icon(switch (statusName) {
        'ready' => Icons.check,
        'connected' => Icons.wifi,
        'offline' => Icons.wifi_off,
        _ => Icons.hourglass_empty,
      }, size: 18),
      label: Text(l10n.multiplayerPresence(statusName)),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: AonwSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AonwColorTokens.background.withAlpha(112),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AonwColorTokens.brandLight.withAlpha(66)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 520 ||
              MediaQuery.textScalerOf(context).scale(14) > 18;
          if (!compact) {
            return ListTile(
              key: ValueKey(('multiplayer-participant', participant.playerId)),
              contentPadding: EdgeInsets.zero,
              leading: _avatar(human),
              title: Text(title),
              subtitle: details,
              trailing: status,
            );
          }
          return Padding(
            key: ValueKey(('multiplayer-participant', participant.playerId)),
            padding: const EdgeInsets.symmetric(vertical: AonwSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _avatar(human),
                const SizedBox(width: AonwSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.bodyLarge),
                      details,
                      const SizedBox(height: AonwSpacing.xs),
                      status,
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _statusName(bool human, bool ready) {
    if (!human) return 'ready';
    if (!participant.isClaimed) return 'open';
    if (participant.isCurrentUser &&
        connection != LobbyConnectionPhase.connected) {
      return connection.name;
    }
    if (!participant.isConnected) return 'offline';
    return ready ? 'ready' : 'connected';
  }

  Widget _avatar(bool human) => CircleAvatar(
    radius: 15,
    backgroundColor: Color(participant.colorValue),
    foregroundColor:
        ThemeData.estimateBrightnessForColor(Color(participant.colorValue)) ==
            Brightness.dark
        ? Colors.white
        : Colors.black,
    child: Icon(
      human ? Icons.person_outline : Icons.smart_toy_outlined,
      size: 18,
    ),
  );
}
