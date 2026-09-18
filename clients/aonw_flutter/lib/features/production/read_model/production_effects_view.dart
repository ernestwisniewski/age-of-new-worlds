part of 'production_details_view.dart';

final class BuildingProductionDetailsView extends ProductionTargetEffectsView {
  BuildingProductionDetailsView({
    required List<ProductionRequirementStatusView> requirements,
    required this.flatYield,
    required this.riverYieldPerHex,
    required this.maxRiverApplications,
    required this.riverApplications,
    required this.sciencePerTurn,
    required this.maxControlledHexesDelta,
    required this.foodDepositBasisPoints,
    required this.current,
    required this.completed,
  }) : requirements = List.unmodifiable(requirements);

  final List<ProductionRequirementStatusView> requirements;
  final YieldValueView flatYield;
  final YieldValueView riverYieldPerHex;
  final int maxRiverApplications;
  final int riverApplications;
  final int sciencePerTurn;
  final int maxControlledHexesDelta;
  final int foodDepositBasisPoints;
  final ProductionCityOutputView current;
  final ProductionCityOutputView completed;
}

final class WonderProductionDetailsView extends ProductionTargetEffectsView {
  WonderProductionDetailsView({
    required List<ProductionRequirementStatusView> requirements,
    required this.hostYield,
    required this.empireYieldPerCity,
    required this.empireSciencePerCity,
    required this.empireGoldBasisPoints,
    required this.empireProductionBasisPoints,
    required this.stabilityDelta,
    required this.grantsFreeActiveTechnology,
    required this.productionBurst,
    required this.grantGold,
  }) : requirements = List.unmodifiable(requirements);

  final List<ProductionRequirementStatusView> requirements;
  final YieldValueView hostYield;
  final YieldValueView empireYieldPerCity;
  final int empireSciencePerCity;
  final int empireGoldBasisPoints;
  final int empireProductionBasisPoints;
  final int stabilityDelta;
  final bool grantsFreeActiveTechnology;
  final int productionBurst;
  final int grantGold;
}
