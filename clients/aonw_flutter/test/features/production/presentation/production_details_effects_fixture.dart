import 'package:aonw_flutter/features/cities/read_model/city_view.dart';
import 'package:aonw_flutter/features/combat/read_model/combat_view.dart';
import 'package:aonw_flutter/features/production/read_model/production_details_view.dart';
import 'package:aonw_flutter/features/production/read_model/production_view.dart';

ProductionDetailsView detailFixture(
  ProductionOptionsView options,
  ProductionTargetView target,
) => ProductionDetailsView(
  stamp: options.stamp,
  cityId: options.cityId,
  option: options.optionFor(target)!,
  effects: switch (target) {
    BuildingProductionTargetView() => BuildingProductionDetailsView(
      requirements: [],
      flatYield: _yield(2),
      riverYieldPerHex: _yield(0),
      maxRiverApplications: 0,
      riverApplications: 0,
      sciencePerTurn: 0,
      maxControlledHexesDelta: 0,
      foodDepositBasisPoints: 10000,
      current: _output(3),
      completed: _output(5),
    ),
    UnitProductionTargetView() => UnitProductionDetailsView(
      baseCombat: _stats(2),
      effectiveCombat: _stats(3),
      maximumMovementUnits: 4,
      baseUpkeep: 1,
      supplyCost: 1,
      supplyCapacity: 12,
      supplyUsedWithoutCityQueue: 3,
      presenceResources: [],
      presenceResourcesMet: true,
      coastMet: true,
      resourceOptions: [],
      affordableResourceOptionIndices: [],
    ),
    WonderProductionTargetView() => WonderProductionDetailsView(
      requirements: [],
      hostYield: _yield(0),
      empireYieldPerCity: _yield(0),
      empireSciencePerCity: 1,
      empireGoldBasisPoints: 0,
      empireProductionBasisPoints: 0,
      stabilityDelta: 0,
      grantsFreeActiveTechnology: true,
      productionBurst: 0,
      grantGold: 0,
    ),
    ProjectProductionTargetView() => const ProjectProductionDetailsView(),
  },
);

YieldValueView _yield(int production) =>
    YieldValueView(food: 0, production: production, gold: 0, defense: 0);
ProductionCityOutputView _output(int production) => ProductionCityOutputView(
  grossYield: _yield(production),
  foodDeposit: 4,
  production: production,
  gold: 2,
  science: 1,
  maxControlledHexes: 4,
);
CombatStatsView _stats(int attack) => CombatStatsView(
  attack: attack,
  defense: 1,
  hitPoints: 10,
  range: 1,
  mobility: 2,
  modifiers: [],
);
