part of 'protocol_query.dart';

final class AonwCityPlanningResult extends AonwQueryResult {
  AonwCityPlanningResult({
    required this.stamp,
    required List<AonwCoordinate> citySites,
    required List<AonwCoordinate> growthTiles,
  }) : citySites = List.unmodifiable(citySites),
       growthTiles = List.unmodifiable(growthTiles);

  factory AonwCityPlanningResult.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'stamp',
      'citySites',
      'growthTiles',
    }, 'city planning');
    return AonwCityPlanningResult(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      citySites: readList(
        value['citySites'],
        'city sites',
        (item, _) => AonwCoordinate.fromJson(item),
      ),
      growthTiles: readList(
        value['growthTiles'],
        'growth tiles',
        (item, _) => AonwCoordinate.fromJson(item),
      ),
    );
  }
  final AonwSessionStamp stamp;
  final List<AonwCoordinate> citySites;
  final List<AonwCoordinate> growthTiles;
}
