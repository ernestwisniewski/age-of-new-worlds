import '../../cities/read_model/city_view.dart';
import '../../combat/read_model/combat_view.dart';
import '../../map/read_model/map_view.dart';
import '../../map/read_model/player_map_view.dart';
import 'production_view.dart';

part 'production_effects_view.dart';
part 'production_unit_details_view.dart';

sealed class ProductionTargetEffectsView {
  const ProductionTargetEffectsView();
}

final class ProjectProductionDetailsView extends ProductionTargetEffectsView {
  const ProjectProductionDetailsView();
}

final class ProductionCityOutputView {
  const ProductionCityOutputView({
    required this.grossYield,
    required this.foodDeposit,
    required this.production,
    required this.gold,
    required this.science,
    required this.maxControlledHexes,
  });

  final YieldValueView grossYield;
  final int foodDeposit;
  final int production;
  final int gold;
  final int science;
  final int maxControlledHexes;
}

final class ProductionRequirementStatusView {
  const ProductionRequirementStatusView({
    required this.requirement,
    required this.met,
  });

  final ProductionRequirementView requirement;
  final bool met;
}

enum ProductionRequirementKindView {
  coastalAccess,
  resourceAny,
  adjacentRiver,
  adjacentMountain,
  hostTerrainAny,
}

final class ProductionRequirementView {
  ProductionRequirementView({
    required this.kind,
    List<MapResource> resources = const [],
    List<MapTerrain> terrains = const [],
  }) : resources = List.unmodifiable(resources),
       terrains = List.unmodifiable(terrains);

  final ProductionRequirementKindView kind;
  final List<MapResource> resources;
  final List<MapTerrain> terrains;
}

final class ProductionDetailsView {
  const ProductionDetailsView({
    required this.stamp,
    required this.cityId,
    required this.option,
    required this.effects,
  });

  final SessionStampView stamp;
  final String cityId;
  final ProductionOptionView option;
  final ProductionTargetEffectsView effects;
}
