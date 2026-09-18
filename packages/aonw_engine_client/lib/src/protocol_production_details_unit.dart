part of 'protocol_query.dart';

final class AonwUnitProductionDetails extends AonwProductionTargetEffects {
  AonwUnitProductionDetails({
    required this.baseCombat,
    required this.effectiveCombat,
    required this.maximumMovementUnits,
    required this.baseUpkeep,
    required this.supplyCost,
    required this.supplyCapacity,
    required this.supplyUsedWithoutCityQueue,
    required List<AonwMapResource> presenceResources,
    required this.presenceResourcesMet,
    required this.coastMet,
    required List<Map<AonwResourceType, int>> resourceOptions,
    required List<int> affordableResourceOptionIndices,
  }) : presenceResources = List.unmodifiable(presenceResources),
       resourceOptions = List.unmodifiable([
         for (final option in resourceOptions)
           Map<AonwResourceType, int>.unmodifiable(option),
       ]),
       affordableResourceOptionIndices = List.unmodifiable(
         affordableResourceOptionIndices,
       );

  factory AonwUnitProductionDetails.fromJson(Object? source) {
    final value = readObject(source, 'AonwUnitProductionDetails');
    requireKeys(value, const {
      'baseCombat',
      'effectiveCombat',
      'maximumMovementUnits',
      'baseUpkeep',
      'supplyCost',
      'supplyCapacity',
      'supplyUsedWithoutCityQueue',
      'presenceResources',
      'presenceResourcesMet',
      'coastMet',
      'resourceOptions',
      'affordableResourceOptionIndices',
    }, 'AonwUnitProductionDetails');
    return AonwUnitProductionDetails(
      baseCombat: AonwCombatStats.fromJson(value['baseCombat']),
      effectiveCombat: AonwCombatStats.fromJson(value['effectiveCombat']),
      maximumMovementUnits: readUnsigned(
        value['maximumMovementUnits'],
        'maximumMovementUnits',
      ),
      baseUpkeep: readUnsigned(value['baseUpkeep'], 'baseUpkeep'),
      supplyCost: readUnsigned(value['supplyCost'], 'supplyCost'),
      supplyCapacity: readUnsigned(value['supplyCapacity'], 'supplyCapacity'),
      supplyUsedWithoutCityQueue: readUnsigned(
        value['supplyUsedWithoutCityQueue'],
        'supplyUsedWithoutCityQueue',
      ),
      presenceResources: readList(
        value['presenceResources'],
        'presenceResources',
        (item, _) => AonwMapResource.fromJson(item),
      ),
      presenceResourcesMet: readBool(
        value['presenceResourcesMet'],
        'presenceResourcesMet',
      ),
      coastMet: readBool(value['coastMet'], 'coastMet'),
      resourceOptions: readList(
        value['resourceOptions'],
        'resourceOptions',
        (item, _) => _resourceStockpile(item),
      ),
      affordableResourceOptionIndices: readList(
        value['affordableResourceOptionIndices'],
        'affordableResourceOptionIndices',
        (item, _) => readUnsigned(item, 'resource option index'),
      ),
    );
  }

  final AonwCombatStats baseCombat;
  final AonwCombatStats effectiveCombat;
  final int maximumMovementUnits;
  final int baseUpkeep;
  final int supplyCost;
  final int supplyCapacity;
  final int supplyUsedWithoutCityQueue;
  final List<AonwMapResource> presenceResources;
  final bool presenceResourcesMet;
  final bool coastMet;
  final List<Map<AonwResourceType, int>> resourceOptions;
  final List<int> affordableResourceOptionIndices;
}
