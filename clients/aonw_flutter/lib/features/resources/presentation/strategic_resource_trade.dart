part of 'strategic_resource_panel.dart';

final class _InventoryAgreements extends StatelessWidget {
  const _InventoryAgreements({required this.player});
  final PlayerMapView player;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final agreements = player.diplomacy.resourceTradeAgreements.toList()
      ..sort((left, right) {
        final remaining = left.remainingTurns.compareTo(right.remainingTurns);
        return remaining != 0 ? remaining : left.id.compareTo(right.id);
      });
    return _InventorySection(
      name: 'agreements',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (agreements.isEmpty)
            Text(l10n.resourceInventoryText('noAgreements')),
          for (final trade in agreements)
            Padding(
              key: ValueKey('resource-agreement-${trade.id}'),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.swap_horiz,
                    color: trade.importerPlayerId == player.actorPlayerId
                        ? AonwColorTokens.success
                        : AonwColorTokens.warning,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _partnerLabel(trade, l10n),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(_flowLabel(trade, l10n)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _partnerLabel(
    ResourceTradeAgreementView trade,
    AonwLocalizations l10n,
  ) {
    final id = trade.importerPlayerId == player.actorPlayerId
        ? trade.exporterPlayerId
        : trade.importerPlayerId;
    final partner = player.participants
        .where((participant) => participant.id == id)
        .firstOrNull;
    return partner == null
        ? l10n.diplomacyText('target')
        : '${partner.name} · ${l10n.countryName(partner.country.name)}';
  }

  String _flowLabel(ResourceTradeAgreementView trade, AonwLocalizations l10n) {
    final direction = l10n.resourceInventoryText(
      trade.importerPlayerId == player.actorPlayerId
          ? 'importDirection'
          : 'exportDirection',
    );
    final price = trade.exchangeGroupId == null
        ? l10n.resourceInventoryTradeGold(trade.goldPerTurn)
        : l10n.resourceInventoryText('barter');
    return l10n.resourceInventoryTradeFlow(
      direction,
      trade.amountPerTurn,
      l10n.presentationName(trade.resource.name),
      price,
      trade.remainingTurns,
    );
  }
}

final class _InventoryPartners extends StatelessWidget {
  const _InventoryPartners({required this.player, this.onTradePartner});
  final PlayerMapView player;
  final ValueChanged<String>? onTradePartner;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final contacts = {
      for (final relation in player.diplomacy.relations)
        relation.counterpartPlayerId,
    };
    final partners = player.participants.where(
      (participant) =>
          participant.id != player.actorPlayerId &&
          contacts.contains(participant.id),
    );
    return _InventorySection(
      name: 'partners',
      child: Column(
        children: [
          if (partners.isEmpty) Text(l10n.resourceInventoryText('noPartners')),
          for (final partner in partners)
            _InventoryNavigationRow(
              key: ValueKey('resource-partner-${partner.id}'),
              title: partner.name,
              detail: l10n.countryName(partner.country.name),
              accent: Color(partner.colorValue),
              action: l10n.resourceInventoryText('openTrade'),
              onPressed: onTradePartner == null
                  ? null
                  : () => onTradePartner!(partner.id),
            ),
        ],
      ),
    );
  }
}
