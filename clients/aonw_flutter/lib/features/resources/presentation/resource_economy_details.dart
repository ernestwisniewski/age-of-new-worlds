part of 'resource_details.dart';

List<ResourceDetail> _goldDetails(
  PlayerMapView player,
  AonwLocalizations l10n,
) {
  final forecast = player.economy.forecast;
  final upkeep = forecast.upkeep;
  return [
    if (forecast.treasuryWarning != TreasuryWarningView.none)
      _detail(
        l10n,
        'warning',
        l10n.resourceText(forecast.treasuryWarning.name),
      ),
    _detail(l10n, 'treasury', forecast.treasury),
    _detail(l10n, 'income', forecast.grossIncome),
    _detail(l10n, 'cityIncome', forecast.cityIncome),
    for (final source in forecast.citySources)
      (
        label: _cityName(player, source.cityId, l10n),
        warning: false,
        value: signedResourceAmount(source.amount),
      ),
    _detail(l10n, 'projectIncome', forecast.projectIncome),
    for (final source in forecast.projectSources)
      (
        label: _cityName(player, source.cityId, l10n),
        warning: false,
        value: signedResourceAmount(source.amount),
      ),
    _detail(l10n, 'upkeep', signedResourceAmount(-upkeep.total)),
    for (final source in upkeep.sources)
      (
        label:
            '${l10n.presentationName(source.kind.name)} ×${source.paidUnitCount}',
        warning: false,
        value: signedResourceAmount(-source.amount),
      ),
    _detail(l10n, 'freeUnits', upkeep.freeUnitCount),
    _detail(l10n, 'paidUnits', upkeep.paidUnitCount),
    _detail(l10n, 'nextWorker', upkeep.nextWorkerUpkeep),
    _detail(l10n, 'netPerTurn', signedResourceAmount(forecast.netPerTurn)),
  ];
}

List<ResourceDetail> _stabilityDetails(
  PlayerMapView player,
  AonwLocalizations l10n,
) {
  final value = player.economy.forecast.stability;
  return [
    _detail(l10n, 'stability', signedResourceAmount(value.effectiveNet)),
    _detail(l10n, 'stability', l10n.resourceText(value.band.name)),
    _detail(l10n, 'baseOrder', value.baseOrder),
    _detail(l10n, 'buildings', value.buildingSources),
    _detail(l10n, 'luxuries', value.luxurySources),
    _detail(l10n, 'technologies', value.technologySources),
    _detail(l10n, 'artifacts', value.artifactSources),
    _detail(l10n, 'wonders', value.wonderSources),
    _detail(l10n, 'totalSources', value.sourceTotal),
    _detail(l10n, 'cities', -value.cityCost),
    _detail(l10n, 'population', -value.populationCost),
    _detail(l10n, 'cohesion', -value.cohesionCost),
    _detail(l10n, 'conqueredCities', -value.conqueredCityCost),
    _detail(l10n, 'warWeariness', -value.warWearinessCost),
    _detail(l10n, 'hegemony', -value.hegemonyTax),
    _detail(l10n, 'totalCosts', -value.costTotal),
    _detail(
      l10n,
      'relativeStanding',
      signedResourceAmount(value.relativeStandingAdjustment),
    ),
  ];
}

List<ResourceDetail> _strategicDetails(
  PlayerMapView player,
  AonwLocalizations l10n,
) => [
  for (final resource in player.economy.strategicResourceShortages)
    _detail(l10n, 'shortage', l10n.presentationName(resource.name)),
  for (final stock in player.economy.strategicResourceStockpile)
    (
      label:
          '${l10n.presentationName(stock.resource.name)} · ${l10n.resourceText('stockpile')}',
      warning: false,
      value: '${stock.amount}',
    ),
  for (final output in player.economy.strategicResourceOutput)
    (
      label:
          '${l10n.presentationName(output.resource.name)} · ${l10n.resourceText('output')}',
      warning: false,
      value: signedResourceAmount(output.amount),
    ),
  for (final source in player.economy.strategicResourceSources)
    (
      label:
          '${_cityName(player, source.cityId, l10n)} · ${l10n.presentationName(source.improvement.name)} · ${l10n.presentationName(source.resource.name)}',
      warning: false,
      value: signedResourceAmount(source.amountPerTurn),
    ),
];
