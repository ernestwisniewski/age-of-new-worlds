part of 'diplomacy_overlay.dart';

final class _RelationCard extends StatelessWidget {
  const _RelationCard({required this.relation});

  final DiplomaticRelationView relation;

  @override
  Widget build(BuildContext context) {
    final copy = DiplomacyCopy.of(context);
    return Card.outlined(
      key: ValueKey(('diplomatic-relation', relation.counterpartPlayerId)),
      child: ListTile(
        title: Text(relation.counterpartPlayerId),
        subtitle: Text(
          '${copy.name(relation.status)} · ${relation.relationScore}'
          '${relation.statusExpiresOnTurn == null ? '' : ' · ${relation.statusExpiresOnTurn}'}',
        ),
      ),
    );
  }
}

final class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    required this.actorPlayerId,
    required this.proposal,
    required this.enabled,
    required this.onAction,
  });

  final String actorPlayerId;
  final DiplomaticProposalView proposal;
  final bool enabled;
  final ValueChanged<DiplomacyActionView> onAction;

  @override
  Widget build(BuildContext context) {
    final copy = DiplomacyCopy.of(context);
    final incoming = proposal.toPlayerId == actorPlayerId;
    return Card.outlined(
      key: ValueKey(('diplomatic-proposal', proposal.id)),
      child: Padding(
        padding: const EdgeInsets.all(AonwSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${copy.name(proposal.kind)} · ${proposal.id}'),
            Text('${proposal.fromPlayerId} → ${proposal.toPlayerId}'),
            Text(
              '${proposal.createdTurn}–${proposal.expiresOnTurn} · ${proposal.goldPayment}',
            ),
            if (incoming)
              Wrap(
                spacing: AonwSpacing.sm,
                children: [
                  FilledButton(
                    key: ValueKey(('accept-proposal', proposal.id)),
                    onPressed: enabled
                        ? () => onAction(
                            RespondDiplomaticProposalActionView(
                              proposalId: proposal.id,
                              accepted: true,
                            ),
                          )
                        : null,
                    child: Text(copy.accept),
                  ),
                  OutlinedButton(
                    key: ValueKey(('reject-proposal', proposal.id)),
                    onPressed: enabled
                        ? () => onAction(
                            RespondDiplomaticProposalActionView(
                              proposalId: proposal.id,
                              accepted: false,
                            ),
                          )
                        : null,
                    child: Text(copy.reject),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

final class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.actorPlayerId,
    required this.message,
    required this.enabled,
    required this.onAction,
  });

  final String actorPlayerId;
  final DiplomaticMessageView message;
  final bool enabled;
  final ValueChanged<DiplomacyActionView> onAction;

  @override
  Widget build(BuildContext context) {
    final copy = DiplomacyCopy.of(context);
    final incoming =
        message.toPlayerId == actorPlayerId && message.response == null;
    return Card.outlined(
      key: ValueKey(('diplomatic-message', message.id)),
      child: Padding(
        padding: const EdgeInsets.all(AonwSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${copy.name(message.topic)} · ${copy.name(message.category)}',
            ),
            Text('${message.fromPlayerId} → ${message.toPlayerId}'),
            Text(
              '${message.createdTurn}–${message.expiresOnTurn} · '
              '${message.response == null ? '-' : copy.name(message.response!)} · '
              '${message.relationScoreDelta}',
            ),
            if (incoming)
              Wrap(
                spacing: AonwSpacing.xs,
                children: [
                  for (final response in DiplomaticMessageResponseView.values)
                    OutlinedButton(
                      key: ValueKey((
                        'respond-message',
                        message.id,
                        response.name,
                      )),
                      onPressed: enabled
                          ? () => onAction(
                              RespondDiplomaticMessageActionView(
                                messageId: message.id,
                                response: response,
                              ),
                            )
                          : null,
                      child: Text(copy.name(response)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

final class _AgreementCard extends StatelessWidget {
  const _AgreementCard({required this.agreement});

  final ResourceTradeAgreementView agreement;

  @override
  Widget build(BuildContext context) {
    final copy = DiplomacyCopy.of(context);
    return Card.outlined(
      key: ValueKey(('resource-trade-agreement', agreement.id)),
      child: ListTile(
        title: Text('${copy.name(agreement.resource)} · ${agreement.id}'),
        subtitle: Text(
          '${agreement.exporterPlayerId} → ${agreement.importerPlayerId} · '
          '${agreement.amountPerTurn} · ${agreement.goldPerTurn} · '
          '${agreement.remainingTurns}',
        ),
      ),
    );
  }
}
