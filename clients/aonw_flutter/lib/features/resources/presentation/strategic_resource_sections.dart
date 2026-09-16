part of 'strategic_resource_panel.dart';

final class _InventoryAlerts extends StatelessWidget {
  const _InventoryAlerts({required this.player});
  final PlayerMapView player;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final inventory = player.economy.strategicResourceInventory;
    return _InventorySection(
      name: 'alerts',
      accent: AonwColorTokens.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final row in inventory.balances)
            if (row.shortage || row.noFreeStock)
              _InventoryAlert(
                title: row.available == 0
                    ? l10n.resourceInventoryNoFreeStock(
                        l10n.presentationName(row.resource.name),
                      )
                    : l10n.resourceInventoryInsufficientStock(
                        l10n.presentationName(row.resource.name),
                      ),
                detail: l10n.resourceInventoryText('stockWarningDetail'),
                danger: row.shortage,
              ),
          for (final trade in player.diplomacy.resourceTradeAgreements)
            if (inventory.expiringTradeIds.contains(trade.id))
              _InventoryAlert(
                title: l10n.resourceInventoryTradeExpiring(
                  l10n.presentationName(trade.resource.name),
                  trade.remainingTurns,
                ),
                detail: l10n.resourceInventoryText('tradeWarningDetail'),
                danger: false,
              ),
        ],
      ),
    );
  }
}

final class _InventoryAlert extends StatelessWidget {
  const _InventoryAlert({
    required this.title,
    required this.detail,
    required this.danger,
  });
  final String title;
  final String detail;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AonwColorTokens.danger : AonwColorTokens.warning;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                Text(detail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _InventoryAllocations extends StatelessWidget {
  const _InventoryAllocations({required this.player, this.onCity});
  final PlayerMapView player;
  final ValueChanged<String>? onCity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final byCity = <String, List<PlayerStrategicResourceAllocationView>>{};
    for (final allocation
        in player.economy.strategicResourceInventory.allocations) {
      byCity.putIfAbsent(allocation.cityId, () => []).add(allocation);
    }
    return _InventorySection(
      name: 'allocations',
      child: Column(
        children: [
          if (byCity.isEmpty) Text(l10n.resourceInventoryText('noAllocations')),
          for (final entry in byCity.entries)
            _InventoryNavigationRow(
              key: ValueKey('resource-allocation-${entry.key}'),
              title: _allocationTitle(entry.key, l10n),
              detail: entry.value
                  .map(
                    (value) =>
                        '${value.amount} ${l10n.presentationName(value.resource.name)}',
                  )
                  .join(' · '),
              action: l10n.resourceInventoryText('goToCity'),
              onPressed: onCity == null ? null : () => onCity!(entry.key),
            ),
        ],
      ),
    );
  }

  String _allocationTitle(String cityId, AonwLocalizations l10n) {
    final queue = player.cities
        .where((city) => city.id == cityId)
        .firstOrNull
        ?.ownedDetails
        ?.productionQueue;
    final city = _cityLabel(player, cityId, l10n);
    return queue?.targetKind == 'unit'
        ? '${l10n.presentationName(queue!.target)} · $city'
        : city;
  }
}

final class _InventorySources extends StatelessWidget {
  const _InventorySources({required this.player, this.onCity});
  final PlayerMapView player;
  final ValueChanged<String>? onCity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final sources = player.economy.strategicResourceInventory.deposits;
    return _InventorySection(
      name: 'sources',
      child: Column(
        children: [
          if (sources.isEmpty) Text(l10n.resourceInventoryText('noSources')),
          for (final source in sources)
            _InventoryNavigationRow(
              key: ValueKey(
                'resource-source-${source.cityId}-${source.resource.name}-${source.coordinate}',
              ),
              title: [
                l10n.presentationName(source.resource.name),
                if (source.improvement case final improvement?)
                  l10n.presentationName(improvement.name),
              ].join(' · '),
              detail: [
                _cityLabel(player, source.cityId, l10n),
                if (source.amountPerTurn case final amount?)
                  '${signedResourceAmount(amount)} / ${l10n.resourceText('turn')}',
              ].join(' · '),
              action: l10n.resourceInventoryText('goToCity'),
              onPressed: onCity == null ? null : () => onCity!(source.cityId),
            ),
        ],
      ),
    );
  }
}

final class _InventoryNavigationRow extends StatelessWidget {
  const _InventoryNavigationRow({
    required this.title,
    required this.detail,
    required this.action,
    this.onPressed,
    this.accent,
    super.key,
  });
  final String title;
  final String detail;
  final String action;
  final VoidCallback? onPressed;
  final Color? accent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (accent case final color?) ...[
          Container(
            width: 10,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              Text(detail),
              const SizedBox(height: 6),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: onPressed,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: Text(action),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
