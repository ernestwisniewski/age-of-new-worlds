part of 'player_map_view_mapper_test.dart';

void registerPlayerEconomyViewMapperCases(PlayerMapViewMapper mapper) {
  test('maps authoritative strategic resource output and source evidence', () {
    final player = mapper.fromWire(
      _snapshot(
        const [],
        cities: [_city()],
        economy: _economy(withOutput: true),
      ),
      map: testMapScene().map,
      actorPlayerId: 'player-1',
    );

    expect(player.economy.outputPerTurnFor(MapResource.oil), 1);
    final source = player.economy.strategicResourceSources.single;
    expect(source.cityId, 'city-a');
    expect(source.coordinate, (col: 1, row: 1));
    expect(source.resource, MapResource.oil);
    expect(source.improvement, FieldImprovementKind.oilWell);
    expect(source.amountPerTurn, 1);
  });

  test('maps authoritative gold, upkeep and stability forecast evidence', () {
    final forecast = AonwEconomyForecast(
      treasury: 10,
      cityIncome: 7,
      projectIncome: 2,
      grossIncome: 9,
      netPerTurn: 8,
      citySources: const [AonwGoldIncomeSource(cityId: 'city-a', amount: 7)],
      projectSources: const [AonwGoldIncomeSource(cityId: 'city-a', amount: 2)],
      upkeep: AonwUnitUpkeepBreakdown(
        upkeepBearingUnitCount: 5,
        freeUnitCount: 4,
        paidUnitCount: 1,
        total: 1,
        nextWorkerUpkeep: 2,
        sources: const [
          AonwUnitUpkeepSource(
            kind: AonwUnitKind.worker,
            paidUnitCount: 1,
            amount: 1,
          ),
        ],
      ),
      stability: const AonwStabilityBreakdown(
        baseOrder: 6,
        buildingSources: 1,
        luxurySources: 0,
        technologySources: 0,
        artifactSources: 0,
        wonderSources: 0,
        cityCost: 0,
        populationCost: 0,
        cohesionCost: 0,
        conqueredCityCost: 0,
        warWearinessCost: 0,
        hegemonyTax: 0,
        sourceTotal: 7,
        costTotal: 0,
        relativeStandingAdjustment: -1,
        effectiveNet: 6,
        band: AonwStabilityBand.content,
      ),
    );
    final player = mapper.fromWire(
      _snapshot(
        const [],
        cities: [_city()],
        economy: _economy(forecast: forecast),
      ),
      map: testMapScene().map,
      actorPlayerId: 'player-1',
    );

    expect(player.economy.forecast.cityIncome, 7);
    expect(player.economy.forecast.projectIncome, 2);
    expect(player.economy.forecast.netPerTurn, 8);
    expect(player.economy.forecast.citySources.single.cityId, 'city-a');
    expect(player.economy.forecast.upkeep.total, 1);
    expect(
      player.economy.forecast.upkeep.sources.single.kind,
      PlayerEconomyUnitKindView.worker,
    );
    expect(player.economy.forecast.stability.effectiveNet, 6);
    expect(
      player.economy.forecast.stability.band,
      PlayerStabilityBandView.content,
    );
  });

  test('rejects inconsistent recipient economy data', () {
    expect(
      () => mapper.fromWire(
        _snapshot(const [], economy: _economy(gold: -1)),
        map: testMapScene().map,
        actorPlayerId: 'player-1',
      ),
      throwsFormatException,
    );
    expect(
      () => mapper.fromWire(
        _snapshot(const [], economy: _economy(withOutput: true)),
        map: testMapScene().map,
        actorPlayerId: 'player-1',
      ),
      throwsFormatException,
    );
    expect(
      () => mapper.fromWire(
        _snapshot(
          const [],
          cities: [_city()],
          economy: _economy(forecast: _forecast(treasury: 10, cityIncome: 1)),
        ),
        map: testMapScene().map,
        actorPlayerId: 'player-1',
      ),
      throwsFormatException,
    );
  });
}
