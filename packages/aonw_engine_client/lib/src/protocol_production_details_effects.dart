part of 'protocol_query.dart';

final class AonwBuildingProductionDetails extends AonwProductionTargetEffects {
  AonwBuildingProductionDetails({
    required List<AonwProductionRequirementStatus> requirements,
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

  factory AonwBuildingProductionDetails.fromJson(Object? source) {
    final value = readObject(source, 'AonwBuildingProductionDetails');
    requireKeys(value, const {
      'requirements',
      'flatYield',
      'riverYieldPerHex',
      'maxRiverApplications',
      'riverApplications',
      'sciencePerTurn',
      'maxControlledHexesDelta',
      'foodDepositBasisPoints',
      'current',
      'completed',
    }, 'AonwBuildingProductionDetails');
    return AonwBuildingProductionDetails(
      requirements: readList(
        value['requirements'],
        'requirements',
        (item, _) => AonwProductionRequirementStatus.fromJson(item),
      ),
      flatYield: AonwYieldValue.fromJson(value['flatYield']),
      riverYieldPerHex: AonwYieldValue.fromJson(value['riverYieldPerHex']),
      maxRiverApplications: readUnsigned(
        value['maxRiverApplications'],
        'maxRiverApplications',
      ),
      riverApplications: readUnsigned(
        value['riverApplications'],
        'riverApplications',
      ),
      sciencePerTurn: readInt(value['sciencePerTurn'], 'sciencePerTurn'),
      maxControlledHexesDelta: readInt(
        value['maxControlledHexesDelta'],
        'maxControlledHexesDelta',
      ),
      foodDepositBasisPoints: readUnsigned(
        value['foodDepositBasisPoints'],
        'foodDepositBasisPoints',
      ),
      current: AonwProductionCityOutput.fromJson(value['current']),
      completed: AonwProductionCityOutput.fromJson(value['completed']),
    );
  }

  final List<AonwProductionRequirementStatus> requirements;
  final AonwYieldValue flatYield;
  final AonwYieldValue riverYieldPerHex;
  final int maxRiverApplications;
  final int riverApplications;
  final int sciencePerTurn;
  final int maxControlledHexesDelta;
  final int foodDepositBasisPoints;
  final AonwProductionCityOutput current;
  final AonwProductionCityOutput completed;
}

final class AonwWonderProductionDetails extends AonwProductionTargetEffects {
  AonwWonderProductionDetails({
    required List<AonwProductionRequirementStatus> requirements,
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

  factory AonwWonderProductionDetails.fromJson(Object? source) {
    final value = readObject(source, 'AonwWonderProductionDetails');
    requireKeys(value, const {
      'requirements',
      'hostYield',
      'empireYieldPerCity',
      'empireSciencePerCity',
      'empireGoldBasisPoints',
      'empireProductionBasisPoints',
      'stabilityDelta',
      'grantsFreeActiveTechnology',
      'productionBurst',
      'grantGold',
    }, 'AonwWonderProductionDetails');
    return AonwWonderProductionDetails(
      requirements: readList(
        value['requirements'],
        'requirements',
        (item, _) => AonwProductionRequirementStatus.fromJson(item),
      ),
      hostYield: AonwYieldValue.fromJson(value['hostYield']),
      empireYieldPerCity: AonwYieldValue.fromJson(value['empireYieldPerCity']),
      empireSciencePerCity: readInt(
        value['empireSciencePerCity'],
        'empireSciencePerCity',
      ),
      empireGoldBasisPoints: readUnsigned(
        value['empireGoldBasisPoints'],
        'empireGoldBasisPoints',
      ),
      empireProductionBasisPoints: readUnsigned(
        value['empireProductionBasisPoints'],
        'empireProductionBasisPoints',
      ),
      stabilityDelta: readInt(value['stabilityDelta'], 'stabilityDelta'),
      grantsFreeActiveTechnology: readBool(
        value['grantsFreeActiveTechnology'],
        'grantsFreeActiveTechnology',
      ),
      productionBurst: readInt(value['productionBurst'], 'productionBurst'),
      grantGold: readInt(value['grantGold'], 'grantGold'),
    );
  }

  final List<AonwProductionRequirementStatus> requirements;
  final AonwYieldValue hostYield;
  final AonwYieldValue empireYieldPerCity;
  final int empireSciencePerCity;
  final int empireGoldBasisPoints;
  final int empireProductionBasisPoints;
  final int stabilityDelta;
  final bool grantsFreeActiveTechnology;
  final int productionBurst;
  final int grantGold;
}
