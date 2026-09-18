import 'package:aonw_flutter/features/production/read_model/production_ranking_view.dart';
import 'package:aonw_flutter/features/production/read_model/production_view.dart';
import 'package:aonw_flutter/features/research/read_model/research_view.dart';

import '../../../support/map_test_fixture.dart';

ProductionOptionsView catalogOptions() => ProductionOptionsView(
  stamp: testSessionStamp(),
  cityId: 'preview-city',
  currentTarget: null,
  investedProduction: 0,
  productionOverflow: 0,
  rushQuote: const ProductionRushQuoteView(
    production: 0,
    goldCost: 0,
    blocker: ProductionRejectionCodeView.productionQueueEmpty,
  ),
  buildings: [
    _building(
      'granary',
      const ProductionAvailabilityView(
        requiredTechnology: null,
        technologyUnlocked: true,
        completedInCity: false,
      ),
    ),
    _building(
      'port',
      const ProductionAvailabilityView(
        requiredTechnology: TechnologyIdView.navigation,
        technologyUnlocked: true,
        completedInCity: false,
      ),
      blocked: true,
    ),
    _building(
      'workshop',
      const ProductionAvailabilityView(
        requiredTechnology: TechnologyIdView.craftsmanship,
        technologyUnlocked: false,
        completedInCity: false,
      ),
      blocked: true,
    ),
    _building(
      'university',
      const ProductionAvailabilityView(
        requiredTechnology: TechnologyIdView.education,
        technologyUnlocked: false,
        completedInCity: false,
      ),
      blocked: true,
    ),
    _building(
      'housing',
      const ProductionAvailabilityView(
        requiredTechnology: TechnologyIdView.construction,
        technologyUnlocked: true,
        completedInCity: true,
      ),
      blocked: true,
    ),
  ],
  buildingRanks: [
    for (final building in [
      'granary',
      'port',
      'workshop',
      'university',
      'housing',
    ])
      ProductionBuildingRankView(
        building: building,
        turnsForScore: 6,
        recommended: 100,
        bestReturn: 50,
        growth: 20,
        industry: 30,
        science: 40,
        defenseMilitary: 10,
        economy: 15,
      ),
  ],
  units: [],
  projects: [],
  wonders: [],
  specializations: [],
);

ProductionOptionView _building(
  String id,
  ProductionAvailabilityView availability, {
  bool blocked = false,
}) => ProductionOptionView(
  target: BuildingProductionTargetView(id),
  cost: 18,
  blocker: blocked ? ProductionRejectionCodeView.buildingNotAvailable : null,
  availability: availability,
  forecast: const ProductionForecastView(
    investedProduction: 0,
    productionPerTurn: 3,
    estimatedTurns: 6,
    projectOutput: null,
    spawnBlocked: false,
  ),
);
