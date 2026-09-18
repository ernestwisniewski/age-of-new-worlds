import '../../map/read_model/player_map_view.dart';

final class ProductionBuildingRankView {
  const ProductionBuildingRankView({
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

  final String building;
  final int turnsForScore;
  final int recommended;
  final int bestReturn;
  final int growth;
  final int industry;
  final int science;
  final int defenseMilitary;
  final int economy;
}

final class ProductionBuildingRanksView {
  ProductionBuildingRanksView({
    required this.stamp,
    required this.cityId,
    required List<ProductionBuildingRankView> buildings,
  }) : buildings = List.unmodifiable(buildings);

  final SessionStampView stamp;
  final String cityId;
  final List<ProductionBuildingRankView> buildings;
}
