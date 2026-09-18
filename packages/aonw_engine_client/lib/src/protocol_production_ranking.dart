part of 'protocol_query.dart';

final class AonwProductionBuildingRank {
  const AonwProductionBuildingRank({
    required this.building,
    required this.turnsForScore,
    required this.recommended,
    required this.bestReturn,
    required this.growth,
    required this.industry,
    required this.science,
    required this.defenseMilitary,
    required this.economy,
  });

  factory AonwProductionBuildingRank.fromJson(Object? source) {
    final value = readObject(source, 'AonwProductionBuildingRank');
    requireKeys(value, const {
      'building',
      'turnsForScore',
      'recommended',
      'bestReturn',
      'growth',
      'industry',
      'science',
      'defenseMilitary',
      'economy',
    }, 'AonwProductionBuildingRank');
    return AonwProductionBuildingRank(
      building: AonwCityBuildingType.fromJson(value['building']),
      turnsForScore: readInt(value['turnsForScore'], 'turnsForScore'),
      recommended: readInt(value['recommended'], 'recommended'),
      bestReturn: readInt(value['bestReturn'], 'bestReturn'),
      growth: readInt(value['growth'], 'growth'),
      industry: readInt(value['industry'], 'industry'),
      science: readInt(value['science'], 'science'),
      defenseMilitary: readInt(value['defenseMilitary'], 'defenseMilitary'),
      economy: readInt(value['economy'], 'economy'),
    );
  }

  final AonwCityBuildingType building;
  final int turnsForScore;
  final int recommended;
  final int bestReturn;
  final int growth;
  final int industry;
  final int science;
  final int defenseMilitary;
  final int economy;
}

final class AonwProductionBuildingRanksResult extends AonwQueryResult {
  AonwProductionBuildingRanksResult({
    required this.stamp,
    required this.cityId,
    required List<AonwProductionBuildingRank> buildings,
  }) : buildings = List.unmodifiable(buildings);

  factory AonwProductionBuildingRanksResult.fromJson(
    Map<String, Object?> value,
  ) {
    requireKeys(value, const {
      'type',
      'stamp',
      'cityId',
      'buildings',
    }, 'production building ranks');
    return AonwProductionBuildingRanksResult(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      cityId: readString(value['cityId'], 'production ranks city'),
      buildings: readList(
        value['buildings'],
        'building ranks',
        (item, _) => AonwProductionBuildingRank.fromJson(item),
      ),
    );
  }

  final AonwSessionStamp stamp;
  final String cityId;
  final List<AonwProductionBuildingRank> buildings;
}
