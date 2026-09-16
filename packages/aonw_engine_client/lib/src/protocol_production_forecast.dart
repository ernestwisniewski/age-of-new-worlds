part of 'protocol_query.dart';

final class AonwProductionForecast {
  const AonwProductionForecast({
    required this.investedProduction,
    required this.productionPerTurn,
    required this.estimatedTurns,
    required this.projectOutput,
    required this.spawnBlocked,
  });

  factory AonwProductionForecast.fromJson(Object? source) {
    final value = readObject(source, 'production forecast');
    requireKeys(value, const {
      'investedProduction',
      'productionPerTurn',
      'estimatedTurns',
      'projectOutput',
      'spawnBlocked',
    }, 'production forecast');
    return AonwProductionForecast(
      investedProduction: readUnsigned(
        value['investedProduction'],
        'forecast investment',
      ),
      productionPerTurn: readUnsigned(
        value['productionPerTurn'],
        'forecast production',
      ),
      estimatedTurns: value['estimatedTurns'] == null
          ? null
          : readUnsigned(value['estimatedTurns'], 'production turns'),
      projectOutput: value['projectOutput'] == null
          ? null
          : readUnsigned(value['projectOutput'], 'project output'),
      spawnBlocked: readBool(value['spawnBlocked'], 'production spawn blocked'),
    );
  }

  final int investedProduction;
  final int productionPerTurn;
  final int? estimatedTurns;
  final int? projectOutput;
  final bool spawnBlocked;
}

final class AonwProductionRushQuote {
  const AonwProductionRushQuote({
    required this.production,
    required this.goldCost,
    required this.rejection,
  });

  factory AonwProductionRushQuote.fromJson(Object? source) {
    final value = readObject(source, 'production rush quote');
    requireKeys(value, const {
      'production',
      'goldCost',
      'rejection',
    }, 'production rush quote');
    return AonwProductionRushQuote(
      production: readUnsigned(value['production'], 'rush production'),
      goldCost: readUnsigned(value['goldCost'], 'rush gold cost'),
      rejection: value['rejection'] == null
          ? null
          : AonwCommandRejectionCode.fromWire(
              readString(value['rejection'], 'rush blocker'),
            ),
    );
  }

  final int production;
  final int goldCost;
  final AonwCommandRejectionCode? rejection;
}
