import 'map_view.dart';
import 'pending_action_view.dart';

final class PlayerStrategicResourceBalanceView {
  const PlayerStrategicResourceBalanceView({
    required this.resource,
    required this.stockpiled,
    required this.controlledDeposits,
    required this.available,
    required this.allocated,
    required this.storedTotal,
    required this.domesticProduction,
    required this.imports,
    required this.exports,
    required this.netPerTurn,
    required this.sourceCount,
    required this.shortage,
    required this.noFreeStock,
  });
  const PlayerStrategicResourceBalanceView.empty(
    this.resource, {
    this.stockpiled = false,
  }) : controlledDeposits = 0,
       available = 0,
       allocated = 0,
       storedTotal = 0,
       domesticProduction = 0,
       imports = 0,
       exports = 0,
       netPerTurn = 0,
       sourceCount = 0,
       shortage = false,
       noFreeStock = false;

  final MapResource resource;
  final bool stockpiled;
  final int controlledDeposits;
  final int available;
  final int allocated;
  final int storedTotal;
  final int domesticProduction;
  final int imports;
  final int exports;
  final int netPerTurn;
  final int sourceCount;
  final bool shortage;
  final bool noFreeStock;
}

final class PlayerStrategicResourceAllocationView {
  const PlayerStrategicResourceAllocationView({
    required this.cityId,
    required this.resource,
    required this.amount,
  });

  final String cityId;
  final MapResource resource;
  final int amount;
}

final class PlayerStrategicResourceDepositView {
  const PlayerStrategicResourceDepositView({
    required this.cityId,
    required this.coordinate,
    required this.resource,
    required this.improvement,
    required this.amountPerTurn,
  });

  final String cityId;
  final MapHexCoordinate coordinate;
  final MapResource resource;
  final FieldImprovementKind? improvement;
  final int? amountPerTurn;
}

final class PlayerStrategicResourceInventoryView {
  PlayerStrategicResourceInventoryView({
    required this.availableTypeCount,
    required this.shortageTypeCount,
    required this.attentionCount,
    required List<PlayerStrategicResourceBalanceView> balances,
    required List<PlayerStrategicResourceAllocationView> allocations,
    required List<PlayerStrategicResourceDepositView> deposits,
    required List<String> expiringTradeIds,
  }) : balances = List.unmodifiable(balances),
       allocations = List.unmodifiable(allocations),
       deposits = List.unmodifiable(deposits),
       expiringTradeIds = List.unmodifiable(expiringTradeIds);

  factory PlayerStrategicResourceInventoryView.empty() =>
      PlayerStrategicResourceInventoryView(
        availableTypeCount: 0,
        shortageTypeCount: 0,
        attentionCount: 0,
        balances: const [
          PlayerStrategicResourceBalanceView.empty(MapResource.iron),
          PlayerStrategicResourceBalanceView.empty(MapResource.coal),
          PlayerStrategicResourceBalanceView.empty(
            MapResource.oil,
            stockpiled: true,
          ),
          PlayerStrategicResourceBalanceView.empty(
            MapResource.aluminium,
            stockpiled: true,
          ),
          PlayerStrategicResourceBalanceView.empty(MapResource.uranium),
          PlayerStrategicResourceBalanceView.empty(MapResource.horses),
          PlayerStrategicResourceBalanceView.empty(MapResource.marble),
        ],
        allocations: const [],
        deposits: const [],
        expiringTradeIds: const [],
      );

  final int availableTypeCount;
  final int shortageTypeCount;
  final int attentionCount;
  final List<PlayerStrategicResourceBalanceView> balances;
  final List<PlayerStrategicResourceAllocationView> allocations;
  final List<PlayerStrategicResourceDepositView> deposits;
  final List<String> expiringTradeIds;
}
