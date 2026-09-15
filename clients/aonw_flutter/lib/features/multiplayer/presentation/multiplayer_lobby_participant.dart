part of 'multiplayer_screen.dart';

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
    final details = Text(
      [
        l10n.countryName(participant.country),
        human ? l10n.multiplayerHumanSeat : l10n.multiplayerAiSeat,
        if (participant.isHost) l10n.multiplayerHost,
        if (participant.isCurrentUser) l10n.multiplayerCurrentPlayer,
      ].join(' · '),
    );
    final status = Chip(
      avatar: Icon(ready ? Icons.check : Icons.hourglass_empty, size: 18),
      label: Text(ready ? l10n.multiplayerReady : l10n.multiplayerNotReady),
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
