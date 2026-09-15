import 'package:aonw_engine_client/src/protocol_coordinate.dart';
import 'package:aonw_engine_client/src/protocol_json.dart';
import 'package:aonw_engine_client/src/protocol_pending_action.dart';
import 'package:aonw_engine_client/src/protocol_values.dart';

final class AonwStrategicResourceBalance {
  const AonwStrategicResourceBalance({
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
  const AonwStrategicResourceBalance.empty(
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

  factory AonwStrategicResourceBalance.fromJson(Object? source) {
    final value = readObject(source, 'strategic resource balance');
    requireKeys(value, const {
      'resource',
      'stockpiled',
      'controlledDeposits',
      'available',
      'allocated',
      'storedTotal',
      'domesticProduction',
      'imports',
      'exports',
      'netPerTurn',
      'sourceCount',
      'shortage',
      'noFreeStock',
    }, 'strategic resource balance');
    int amount(String key) => readInt(value[key], 'strategic balance $key');
    bool flag(String key) => readBool(value[key], 'strategic balance $key');
    return AonwStrategicResourceBalance(
      resource: AonwResourceType.fromJson(value['resource']),
      stockpiled: flag('stockpiled'),
      controlledDeposits: amount('controlledDeposits'),
      available: amount('available'),
      allocated: amount('allocated'),
      storedTotal: amount('storedTotal'),
      domesticProduction: amount('domesticProduction'),
      imports: amount('imports'),
      exports: amount('exports'),
      netPerTurn: amount('netPerTurn'),
      sourceCount: amount('sourceCount'),
      shortage: flag('shortage'),
      noFreeStock: flag('noFreeStock'),
    );
  }

  final AonwResourceType resource;
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

final class AonwStrategicResourceAllocation {
  const AonwStrategicResourceAllocation({
    required this.cityId,
    required this.resource,
    required this.amount,
  });

  factory AonwStrategicResourceAllocation.fromJson(Object? source) {
    final value = readObject(source, 'strategic resource allocation');
    requireKeys(value, const {
      'cityId',
      'resource',
      'amount',
    }, 'strategic resource allocation');
    return AonwStrategicResourceAllocation(
      cityId: readString(
        value['cityId'],
        'strategic resource allocation cityId',
      ),
      resource: AonwResourceType.fromJson(value['resource']),
      amount: readInt(value['amount'], 'strategic resource allocation amount'),
    );
  }

  final String cityId;
  final AonwResourceType resource;
  final int amount;
}

final class AonwStrategicResourceDeposit {
  const AonwStrategicResourceDeposit({
    required this.cityId,
    required this.coordinate,
    required this.resource,
    required this.improvement,
    required this.amountPerTurn,
  });

  factory AonwStrategicResourceDeposit.fromJson(Object? source) {
    final value = readObject(source, 'strategic resource deposit');
    requireKeys(value, const {
      'cityId',
      'coordinate',
      'resource',
      'improvement',
      'amountPerTurn',
    }, 'strategic resource deposit');
    return AonwStrategicResourceDeposit(
      cityId: readString(value['cityId'], 'strategic resource deposit cityId'),
      coordinate: AonwCoordinate.fromJson(value['coordinate']),
      resource: AonwResourceType.fromJson(value['resource']),
      improvement: value['improvement'] == null
          ? null
          : AonwFieldImprovementKind.fromJson(value['improvement']),
      amountPerTurn: value['amountPerTurn'] == null
          ? null
          : readInt(
              value['amountPerTurn'],
              'strategic resource deposit amountPerTurn',
            ),
    );
  }

  final String cityId;
  final AonwCoordinate coordinate;
  final AonwResourceType resource;
  final AonwFieldImprovementKind? improvement;
  final int? amountPerTurn;
}

final class AonwStrategicResourceInventory {
  AonwStrategicResourceInventory({
    required this.availableTypeCount,
    required this.shortageTypeCount,
    required this.attentionCount,
    required List<AonwStrategicResourceBalance> balances,
    required List<AonwStrategicResourceAllocation> allocations,
    required List<AonwStrategicResourceDeposit> deposits,
    required List<String> expiringTradeIds,
  }) : balances = List.unmodifiable(balances),
       allocations = List.unmodifiable(allocations),
       deposits = List.unmodifiable(deposits),
       expiringTradeIds = List.unmodifiable(expiringTradeIds);

  factory AonwStrategicResourceInventory.empty() =>
      AonwStrategicResourceInventory(
        availableTypeCount: 0,
        shortageTypeCount: 0,
        attentionCount: 0,
        balances: const [
          AonwStrategicResourceBalance.empty(AonwResourceType.iron),
          AonwStrategicResourceBalance.empty(AonwResourceType.coal),
          AonwStrategicResourceBalance.empty(
            AonwResourceType.oil,
            stockpiled: true,
          ),
          AonwStrategicResourceBalance.empty(
            AonwResourceType.aluminium,
            stockpiled: true,
          ),
          AonwStrategicResourceBalance.empty(AonwResourceType.uranium),
          AonwStrategicResourceBalance.empty(AonwResourceType.horses),
          AonwStrategicResourceBalance.empty(AonwResourceType.marble),
        ],
        allocations: const [],
        deposits: const [],
        expiringTradeIds: const [],
      );

  factory AonwStrategicResourceInventory.fromJson(Object? source) {
    final value = readObject(source, 'strategic inventory');
    requireKeys(value, const {
      'availableTypeCount',
      'shortageTypeCount',
      'attentionCount',
      'balances',
      'allocations',
      'deposits',
      'expiringTradeIds',
    }, 'strategic inventory');
    final balances = readList(
      value['balances'],
      'balances',
      (item, _) => AonwStrategicResourceBalance.fromJson(item),
    );
    if (balances.length != 7) {
      throw const FormatException(
        'Strategic inventory requires seven balances.',
      );
    }
    return AonwStrategicResourceInventory(
      availableTypeCount: readUnsigned(
        value['availableTypeCount'],
        'availableTypeCount',
      ),
      shortageTypeCount: readUnsigned(
        value['shortageTypeCount'],
        'shortageTypeCount',
      ),
      attentionCount: readUnsigned(value['attentionCount'], 'attentionCount'),
      balances: balances,
      allocations: readList(
        value['allocations'],
        'allocations',
        (item, label) => AonwStrategicResourceAllocation.fromJson(item),
      ),
      deposits: readList(
        value['deposits'],
        'deposits',
        (item, label) => AonwStrategicResourceDeposit.fromJson(item),
      ),
      expiringTradeIds: readList(
        value['expiringTradeIds'],
        'expiringTradeIds',
        (item, label) => readString(item, 'expiring trade id'),
      ),
    );
  }

  final int availableTypeCount;
  final int shortageTypeCount;
  final int attentionCount;
  final List<AonwStrategicResourceBalance> balances;
  final List<AonwStrategicResourceAllocation> allocations;
  final List<AonwStrategicResourceDeposit> deposits;
  final List<String> expiringTradeIds;
}
