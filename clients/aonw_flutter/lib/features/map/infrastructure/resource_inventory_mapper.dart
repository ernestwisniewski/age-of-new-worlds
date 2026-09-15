import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../read_model/map_view.dart';
import '../read_model/pending_action_view.dart';
import '../read_model/player_resource_inventory_view.dart';

PlayerStrategicResourceInventoryView mapResourceInventory(
  AonwStrategicResourceInventory value,
) => PlayerStrategicResourceInventoryView(
  availableTypeCount: value.availableTypeCount,
  shortageTypeCount: value.shortageTypeCount,
  attentionCount: value.attentionCount,
  expiringTradeIds: value.expiringTradeIds,
  balances: [
    for (final item in value.balances)
      PlayerStrategicResourceBalanceView(
        resource: MapResource.values.byName(item.resource.name),
        stockpiled: item.stockpiled,
        controlledDeposits: item.controlledDeposits,
        available: item.available,
        allocated: item.allocated,
        storedTotal: item.storedTotal,
        domesticProduction: item.domesticProduction,
        imports: item.imports,
        exports: item.exports,
        netPerTurn: item.netPerTurn,
        sourceCount: item.sourceCount,
        shortage: item.shortage,
        noFreeStock: item.noFreeStock,
      ),
  ],
  allocations: [
    for (final item in value.allocations)
      PlayerStrategicResourceAllocationView(
        cityId: item.cityId,
        resource: MapResource.values.byName(item.resource.name),
        amount: item.amount,
      ),
  ],
  deposits: [
    for (final item in value.deposits)
      PlayerStrategicResourceDepositView(
        cityId: item.cityId,
        coordinate: (col: item.coordinate.col, row: item.coordinate.row),
        resource: MapResource.values.byName(item.resource.name),
        improvement: item.improvement == null
            ? null
            : FieldImprovementKind.values.byName(item.improvement!.name),
        amountPerTurn: item.amountPerTurn,
      ),
  ],
);
