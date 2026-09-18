part of 'production_details_view.dart';

final class UnitProductionDetailsView extends ProductionTargetEffectsView {
  UnitProductionDetailsView({
    required this.baseCombat,
    required this.effectiveCombat,
    required this.maximumMovementUnits,
    required this.baseUpkeep,
    required this.supplyCost,
    required this.supplyCapacity,
    required this.supplyUsedWithoutCityQueue,
    required List<MapResource> presenceResources,
    required this.presenceResourcesMet,
    required this.coastMet,
    required List<Map<MapResource, int>> resourceOptions,
    required List<int> affordableResourceOptionIndices,
  }) : presenceResources = List.unmodifiable(presenceResources),
       resourceOptions = List.unmodifiable([
         for (final option in resourceOptions)
           Map<MapResource, int>.unmodifiable(option),
       ]),
       affordableResourceOptionIndices = List.unmodifiable(
         affordableResourceOptionIndices,
       );

  final CombatStatsView baseCombat;
  final CombatStatsView effectiveCombat;
  final int maximumMovementUnits;
  final int baseUpkeep;
  final int supplyCost;
  final int supplyCapacity;
  final int supplyUsedWithoutCityQueue;
  final List<MapResource> presenceResources;
  final bool presenceResourcesMet;
  final bool coastMet;
  final List<Map<MapResource, int>> resourceOptions;
  final List<int> affordableResourceOptionIndices;
}
