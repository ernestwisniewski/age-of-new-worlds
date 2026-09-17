import 'package:aonw_flutter/features/production/read_model/production_view.dart';

import '../../../support/map_test_fixture.dart';

ProductionOptionsView detailsOptions(
  ProductionTargetView target, {
  int cost = 18,
  String cityId = 'preview-city',
}) {
  final option = ProductionOptionView(
    target: target,
    cost: cost,
    blocker: null,
    availability: const ProductionAvailabilityView(
      requiredTechnology: null,
      technologyUnlocked: true,
      completedInCity: false,
    ),
    forecast: const ProductionForecastView(
      investedProduction: 0,
      productionPerTurn: 3,
      estimatedTurns: 6,
      projectOutput: null,
      spawnBlocked: false,
    ),
  );
  return ProductionOptionsView(
    stamp: testSessionStamp(),
    cityId: cityId,
    currentTarget: null,
    investedProduction: 0,
    productionOverflow: 0,
    rushQuote: const ProductionRushQuoteView(
      production: 0,
      goldCost: 0,
      blocker: ProductionRejectionCodeView.productionQueueEmpty,
    ),
    buildings: [if (target is BuildingProductionTargetView) option],
    units: [
      if (target is UnitProductionTargetView)
        UnitProductionOptionView(
          option: option,
          resourceOptions: [],
          affordableResourceOptionIndices: {},
        ),
    ],
    projects: [],
    wonders: [if (target is WonderProductionTargetView) option],
    specializations: [],
  );
}
