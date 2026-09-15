part of 'player_map_view_mapper_test.dart';

void registerResourceInventoryMapperCases(PlayerMapViewMapper mapper) {
  PlayerMapView mapInventory(AonwStrategicResourceInventory inventory) =>
      mapper.fromWire(
        _snapshot(
          const [],
          cities: [_city()],
          economy: _economy(withOutput: true, inventory: inventory),
        ),
        map: testMapScene().map,
        actorPlayerId: 'player-1',
      );
  AonwStrategicResourceInventory valid() =>
      _inventory(shortages: const [], withOutput: true);

  test(
    'maps complete authoritative inventory and preserves immutable details',
    () {
      final inventory = mapInventory(
        valid(),
      ).economy.strategicResourceInventory;
      expect(inventory.balances.length, 7);
      expect(inventory.availableTypeCount, 1);
      expect(inventory.balances[2].available, 2);
      expect(inventory.balances[2].netPerTurn, 1);
      expect(inventory.deposits.single.cityId, 'city-a');
      expect(inventory.deposits.single.coordinate, (col: 1, row: 1));
      expect(
        inventory.deposits.single.improvement,
        FieldImprovementKind.oilWell,
      );
      expect(inventory.deposits.single.amountPerTurn, 1);
      expect(() => inventory.balances.clear(), throwsUnsupportedError);
      expect(() => inventory.deposits.clear(), throwsUnsupportedError);
    },
  );

  test(
    'rejects partial, reordered, inconsistent and foreign inventory evidence',
    () {
      final source = valid();
      final foreign = AonwStrategicResourceDeposit(
        cityId: 'foreign-city',
        coordinate: source.deposits.single.coordinate,
        resource: AonwResourceType.oil,
        improvement: AonwFieldImprovementKind.oilWell,
        amountPerTurn: 1,
      );
      final invalid = [
        _changedInventory(source, balances: source.balances.take(6).toList()),
        _changedInventory(source, balances: source.balances.reversed.toList()),
        _changedInventory(source, availableTypeCount: 2),
        _changedInventory(source, attentionCount: 1),
        _changedInventory(source, deposits: const []),
        _changedInventory(
          source,
          deposits: [source.deposits.single, source.deposits.single],
        ),
        _changedInventory(source, deposits: [foreign]),
        _changedInventory(
          source,
          allocations: const [
            AonwStrategicResourceAllocation(
              cityId: 'foreign-city',
              resource: AonwResourceType.oil,
              amount: 1,
            ),
          ],
        ),
        _changedInventory(source, expiringTradeIds: const ['unknown-trade']),
      ];
      for (var index = 0; index < invalid.length; index++) {
        expect(
          () => mapInventory(invalid[index]),
          throwsFormatException,
          reason: 'invalid inventory $index',
        );
      }
    },
  );
}

AonwStrategicResourceInventory _changedInventory(
  AonwStrategicResourceInventory source, {
  List<AonwStrategicResourceBalance>? balances,
  int? availableTypeCount,
  int? attentionCount,
  List<AonwStrategicResourceAllocation>? allocations,
  List<AonwStrategicResourceDeposit>? deposits,
  List<String>? expiringTradeIds,
}) => AonwStrategicResourceInventory(
  balances: balances ?? source.balances,
  availableTypeCount: availableTypeCount ?? source.availableTypeCount,
  shortageTypeCount: source.shortageTypeCount,
  attentionCount: attentionCount ?? source.attentionCount,
  allocations: allocations ?? source.allocations,
  deposits: deposits ?? source.deposits,
  expiringTradeIds: expiringTradeIds ?? source.expiringTradeIds,
);
