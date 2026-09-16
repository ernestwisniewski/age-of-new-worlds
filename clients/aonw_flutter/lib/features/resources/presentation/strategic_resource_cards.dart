part of 'strategic_resource_panel.dart';

final class _InventoryCards extends StatelessWidget {
  const _InventoryCards({required this.inventory});
  final PlayerStrategicResourceInventoryView inventory;

  @override
  Widget build(BuildContext context) => _InventorySection(
    name: 'resources',
    child: LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns =
            constraints.maxWidth >= 650 &&
            MediaQuery.textScalerOf(context).scale(12) <= 18;
        final width = twoColumns
            ? (constraints.maxWidth - 10) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final row in inventory.balances)
              SizedBox(
                width: width,
                child: _InventoryCard(row: row),
              ),
          ],
        );
      },
    ),
  );
}

final class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.row});
  final PlayerStrategicResourceBalanceView row;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final accent = row.shortage
        ? AonwColorTokens.danger
        : row.available == 0
        ? AonwColorTokens.warning
        : AonwColorTokens.resourcesAccent;
    return AonwHudSurface(
      key: ValueKey('strategic-resource-${row.resource.name}'),
      semanticLabel: l10n.presentationName(row.resource.name),
      elevation: AonwHudElevation.flat,
      accent: accent,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ResourceIcon(
                kind: ResourcePopup.resources,
                color: accent,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.presentationName(row.resource.name),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (row.shortage)
                Icon(Icons.warning_amber_rounded, color: accent),
            ],
          ),
          const SizedBox(height: 10),
          _InventoryMetrics(row: row),
        ],
      ),
    );
  }
}

final class _InventoryMetrics extends StatelessWidget {
  const _InventoryMetrics({required this.row});
  final PlayerStrategicResourceBalanceView row;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = math.min(
        constraints.maxWidth,
        MediaQuery.textScalerOf(context).scale(104),
      );
      final metrics = <(String, String, Color?)>[
        if (row.stockpiled) ...[
          ('stored', '${row.storedTotal}', null),
          ('allocated', '${row.allocated}', null),
        ] else
          ('controlled', '${row.controlledDeposits}', null),
        (
          'available',
          '${row.available}',
          row.available == 0
              ? AonwColorTokens.warning
              : AonwColorTokens.success,
        ),
        if (row.stockpiled)
          ('production', signedResourceAmount(row.domesticProduction), null),
        ('imports', signedResourceAmount(row.imports), null),
        ('exports', row.exports == 0 ? '0' : '-${row.exports}', null),
        (
          'net',
          signedResourceAmount(row.netPerTurn),
          _flowColor(row.netPerTurn),
        ),
      ];
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (name, amount, color) in metrics)
            SizedBox(
              width: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.aonwL10n.resourceInventoryText(name),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    amount,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontFeatures: AonwTypography.tabularFigures,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    },
  );
}

Color? _flowColor(int amount) => amount < 0
    ? AonwColorTokens.danger
    : amount > 0
    ? AonwColorTokens.success
    : null;
