import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../read_model/map_view.dart';

final class RecipientResourceInventoryValidator {
  const RecipientResourceInventoryValidator(this.map);

  final MapView map;

  void validate(AonwPlayerViewSnapshot snapshot) {
    final economy = snapshot.economy;
    final inventory = economy.strategicResourceInventory;
    _validateRows(inventory, economy);
    final ownCities = {
      for (final city in snapshot.cities)
        if (city.ownedDetails != null) city.id: city,
    };
    _validateAllocations(inventory, ownCities);
    _validateDeposits(inventory, economy, ownCities);
    _validateAlerts(inventory, snapshot.diplomacy.resourceTradeAgreements);
  }

  void _validateRows(
    AonwStrategicResourceInventory inventory,
    AonwPlayerEconomyView economy,
  ) {
    if (inventory.balances.length != _resources.length) {
      throw const FormatException(
        'Strategic inventory must contain seven kinds.',
      );
    }
    for (var index = 0; index < _resources.length; index++) {
      final row = inventory.balances[index];
      _validateBalance(row, _resources[index]);
      if (row.shortage !=
          economy.strategicResourceShortages.contains(row.resource)) {
        throw const FormatException(
          'Strategic inventory shortage is inconsistent.',
        );
      }
      if (row.stockpiled &&
          row.available !=
              _amount(economy.strategicResourceStockpile, row.resource)) {
        throw const FormatException(
          'Strategic inventory stockpile is inconsistent.',
        );
      }
      if (row.domesticProduction !=
          _amount(economy.strategicResourceOutput, row.resource)) {
        throw const FormatException(
          'Strategic inventory extraction is inconsistent.',
        );
      }
    }
    if (inventory.availableTypeCount !=
            inventory.balances.where((row) => row.available > 0).length ||
        inventory.shortageTypeCount !=
            inventory.balances.where((row) => row.shortage).length) {
      throw const FormatException(
        'Strategic inventory summary counts are inconsistent.',
      );
    }
  }

  void _validateBalance(
    AonwStrategicResourceBalance row,
    AonwResourceType expected,
  ) {
    final stockpiled = _stockpiled(expected);
    if (row.resource != expected ||
        row.stockpiled != stockpiled ||
        [
          row.controlledDeposits,
          row.available,
          row.allocated,
          row.storedTotal,
          row.domesticProduction,
          row.imports,
          row.exports,
          row.sourceCount,
        ].any((amount) => amount < 0)) {
      throw const FormatException(
        'Strategic inventory balance is invalid or unordered.',
      );
    }
    _validateBalanceTotals(row);
  }

  void _validateBalanceTotals(AonwStrategicResourceBalance row) {
    if (row.storedTotal != row.available + row.allocated ||
        row.netPerTurn != row.domesticProduction + row.imports - row.exports ||
        (!row.stockpiled &&
            (row.allocated != 0 || row.shortage || row.noFreeStock))) {
      throw const FormatException(
        'Strategic inventory balance totals are inconsistent.',
      );
    }
  }

  void _validateAllocations(
    AonwStrategicResourceInventory inventory,
    Map<String, AonwPlayerCityView> cities,
  ) {
    final amounts = <AonwResourceType, int>{};
    (String, int)? previous;
    for (final allocation in inventory.allocations) {
      final key = (allocation.cityId, allocation.resource.index);
      if (!cities.containsKey(allocation.cityId) ||
          allocation.amount <= 0 ||
          !_stockpiled(allocation.resource) ||
          (previous != null && _compareAllocation(previous, key) >= 0)) {
        throw const FormatException(
          'Strategic inventory allocation is invalid or unordered.',
        );
      }
      previous = key;
      amounts.update(
        allocation.resource,
        (value) => value + allocation.amount,
        ifAbsent: () => allocation.amount,
      );
    }
    for (final row in inventory.balances) {
      if (row.allocated != (amounts[row.resource] ?? 0)) {
        throw const FormatException(
          'Strategic inventory reservations do not match their cities.',
        );
      }
    }
  }

  void _validateDeposits(
    AonwStrategicResourceInventory inventory,
    AonwPlayerEconomyView economy,
    Map<String, AonwPlayerCityView> cities,
  ) {
    final counts = <AonwResourceType, int>{};
    final producing = <AonwResourceType, int>{};
    AonwStrategicResourceDeposit? previous;
    for (final deposit in inventory.deposits) {
      _validateDeposit(deposit, cities[deposit.cityId]);
      if (previous != null && _compareDeposit(previous, deposit) >= 0) {
        throw const FormatException(
          'Strategic inventory deposits are not ordered.',
        );
      }
      previous = deposit;
      counts.update(deposit.resource, (value) => value + 1, ifAbsent: () => 1);
      if (_hasExtraction(deposit, economy.strategicResourceSources)) {
        producing.update(
          deposit.resource,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }
    _validateSourceCounts(inventory.balances, counts, producing);
    if (producing.values.fold(0, (sum, count) => sum + count) !=
        economy.strategicResourceSources.length) {
      throw const FormatException(
        'Strategic inventory omits an extraction source.',
      );
    }
  }

  bool _hasExtraction(
    AonwStrategicResourceDeposit deposit,
    List<AonwPlayerStrategicResourceSource> sources,
  ) {
    final source = sources
        .where(
          (source) =>
              source.cityId == deposit.cityId &&
              source.resource == deposit.resource &&
              _sameCoordinate(source.coordinate, deposit.coordinate),
        )
        .firstOrNull;
    if (deposit.amountPerTurn != source?.amountPerTurn ||
        (source != null && source.improvement != deposit.improvement)) {
      throw const FormatException(
        'Strategic inventory deposit extraction is inconsistent.',
      );
    }
    return source != null;
  }

  void _validateSourceCounts(
    List<AonwStrategicResourceBalance> balances,
    Map<AonwResourceType, int> counts,
    Map<AonwResourceType, int> producing,
  ) {
    for (final row in balances) {
      final sourceCounts = row.stockpiled ? producing : counts;
      if (row.controlledDeposits != (counts[row.resource] ?? 0) ||
          row.sourceCount != (sourceCounts[row.resource] ?? 0)) {
        throw const FormatException(
          'Strategic inventory source counts are inconsistent.',
        );
      }
    }
  }

  void _validateDeposit(
    AonwStrategicResourceDeposit deposit,
    AonwPlayerCityView? city,
  ) {
    final coordinate = deposit.coordinate;
    if (!_resources.contains(deposit.resource) ||
        city == null ||
        !map.isWithinBounds((col: coordinate.col, row: coordinate.row)) ||
        !(_sameCoordinate(city.center, coordinate) ||
            city.visibleControlledHexes.any(
              (value) => _sameCoordinate(value, coordinate),
            ))) {
      throw const FormatException(
        'Strategic inventory deposit is outside owned territory.',
      );
    }
    if (deposit.amountPerTurn case final amount? when amount <= 0) {
      throw const FormatException(
        'Strategic inventory deposit output is invalid.',
      );
    }
  }

  void _validateAlerts(
    AonwStrategicResourceInventory inventory,
    List<AonwPlayerResourceTradeAgreementView> trades,
  ) {
    final ids = inventory.expiringTradeIds;
    final known = {for (final trade in trades) trade.id};
    String? previous;
    for (final id in ids) {
      if (!known.contains(id) ||
          (previous != null && previous.compareTo(id) >= 0)) {
        throw const FormatException(
          'Strategic inventory trade alert is invalid or unordered.',
        );
      }
      previous = id;
    }
    final balances = inventory.balances
        .where((row) => row.shortage || row.noFreeStock)
        .length;
    if (inventory.attentionCount != balances + ids.length) {
      throw const FormatException(
        'Strategic inventory attention count is inconsistent.',
      );
    }
  }
}

const _resources = [
  AonwResourceType.iron,
  AonwResourceType.coal,
  AonwResourceType.oil,
  AonwResourceType.aluminium,
  AonwResourceType.uranium,
  AonwResourceType.horses,
  AonwResourceType.marble,
];

bool _stockpiled(AonwResourceType value) =>
    value == AonwResourceType.oil || value == AonwResourceType.aluminium;

int _amount(
  List<AonwPlayerStrategicResourceAmount> amounts,
  AonwResourceType resource,
) =>
    amounts.where((value) => value.resource == resource).firstOrNull?.amount ??
    0;

bool _sameCoordinate(AonwCoordinate left, AonwCoordinate right) =>
    left.col == right.col && left.row == right.row;

int _compareAllocation((String, int) left, (String, int) right) {
  final city = left.$1.compareTo(right.$1);
  return city != 0 ? city : left.$2.compareTo(right.$2);
}

int _compareDeposit(
  AonwStrategicResourceDeposit left,
  AonwStrategicResourceDeposit right,
) {
  final resource = left.resource.index.compareTo(right.resource.index);
  if (resource != 0) return resource;
  final city = left.cityId.compareTo(right.cityId);
  if (city != 0) return city;
  final col = left.coordinate.col.compareTo(right.coordinate.col);
  return col != 0 ? col : left.coordinate.row.compareTo(right.coordinate.row);
}
