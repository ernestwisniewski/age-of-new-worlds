import '../../map/read_model/map_view.dart';
import '../../map/read_model/player_map_view.dart';

sealed class ProductionTargetView {
  const ProductionTargetView();
}

final class BuildingProductionTargetView extends ProductionTargetView {
  const BuildingProductionTargetView(this.building);

  final String building;
}

final class UnitProductionTargetView extends ProductionTargetView {
  const UnitProductionTargetView(this.unit);

  final VisibleUnitKind unit;
}

final class ProjectProductionTargetView extends ProductionTargetView {
  const ProjectProductionTargetView(this.project);

  final String project;
}

final class WonderProductionTargetView extends ProductionTargetView {
  const WonderProductionTargetView(this.wonder);

  final String wonder;
}

final class ProductionOptionView {
  const ProductionOptionView({
    required this.target,
    required this.cost,
    required this.blocker,
  });

  final ProductionTargetView target;
  final int cost;
  final ProductionRejectionCodeView? blocker;
}

final class UnitProductionOptionView {
  UnitProductionOptionView({
    required this.option,
    required List<Map<MapResource, int>> resourceOptions,
    required Set<int> affordableResourceOptionIndices,
  }) : resourceOptions = List.unmodifiable([
         for (final option in resourceOptions)
           Map<MapResource, int>.unmodifiable(option),
       ]),
       affordableResourceOptionIndices = Set.unmodifiable(
         affordableResourceOptionIndices,
       );

  final ProductionOptionView option;
  final List<Map<MapResource, int>> resourceOptions;
  final Set<int> affordableResourceOptionIndices;
}

final class CitySpecializationOptionView {
  const CitySpecializationOptionView({
    required this.specialization,
    required this.requiredBuilding,
    required this.blocker,
  });

  final String specialization;
  final String requiredBuilding;
  final ProductionRejectionCodeView? blocker;
}

final class ProductionOptionsView {
  ProductionOptionsView({
    required this.stamp,
    required this.cityId,
    required this.currentTarget,
    required this.investedProduction,
    required this.productionOverflow,
    required List<ProductionOptionView> buildings,
    required List<UnitProductionOptionView> units,
    required List<ProductionOptionView> projects,
    required List<ProductionOptionView> wonders,
    required List<CitySpecializationOptionView> specializations,
  }) : buildings = List.unmodifiable(buildings),
       units = List.unmodifiable(units),
       projects = List.unmodifiable(projects),
       wonders = List.unmodifiable(wonders),
       specializations = List.unmodifiable(specializations);

  final SessionStampView stamp;
  final String cityId;
  final ProductionTargetView? currentTarget;
  final int investedProduction;
  final int productionOverflow;
  final List<ProductionOptionView> buildings;
  final List<UnitProductionOptionView> units;
  final List<ProductionOptionView> projects;
  final List<ProductionOptionView> wonders;
  final List<CitySpecializationOptionView> specializations;
}

final class StrategicResourceAmountView {
  const StrategicResourceAmountView({
    required this.resource,
    required this.amount,
  });

  final MapResource resource;
  final int amount;
}

final class StrategicResourceSourceView {
  const StrategicResourceSourceView({
    required this.cityId,
    required this.coordinate,
    required this.resource,
    required this.improvement,
    required this.amountPerTurn,
  });

  final String cityId;
  final MapHexCoordinate coordinate;
  final MapResource resource;
  final String improvement;
  final int amountPerTurn;
}

final class StrategicResourceProjectionView {
  StrategicResourceProjectionView({
    required this.stamp,
    required this.playerId,
    required List<StrategicResourceAmountView> output,
    required List<StrategicResourceSourceView> sources,
  }) : output = List.unmodifiable(output),
       sources = List.unmodifiable(sources);

  final SessionStampView stamp;
  final String playerId;
  final List<StrategicResourceAmountView> output;
  final List<StrategicResourceSourceView> sources;
}

sealed class ProductionActionView {
  const ProductionActionView({required this.cityId});

  final String cityId;
}

final class StartBuildingActionView extends ProductionActionView {
  const StartBuildingActionView({
    required super.cityId,
    required this.building,
  });

  final String building;
}

final class StartUnitProductionActionView extends ProductionActionView {
  const StartUnitProductionActionView({
    required super.cityId,
    required this.unit,
    required this.resourceOptionIndex,
  });

  final VisibleUnitKind unit;
  final int? resourceOptionIndex;
}

final class StartCityProjectActionView extends ProductionActionView {
  const StartCityProjectActionView({
    required super.cityId,
    required this.project,
  });

  final String project;
}

final class StartWonderActionView extends ProductionActionView {
  const StartWonderActionView({required super.cityId, required this.wonder});

  final String wonder;
}

final class SetCitySpecializationActionView extends ProductionActionView {
  const SetCitySpecializationActionView({
    required super.cityId,
    required this.specialization,
  });

  final String specialization;
}

final class RushProductionActionView extends ProductionActionView {
  const RushProductionActionView({required super.cityId});
}

enum ProductionRejectionCodeView {
  staleRevision,
  matchFinished,
  cityNotFound,
  cityNotControlled,
  buildingNotAvailable,
  unitProductionInvalidResourceOption,
  unitProductionNotAvailable,
  unitProductionRequiresResource,
  unitProductionMissingStrategicResource,
  unitProductionRequiresCoast,
  unitSupplyLimitReached,
  wonderNotAvailable,
  citySpecializationLocked,
  citySpecializationUnchanged,
  citySpecializationMissingBuilding,
  productionQueueEmpty,
  projectCannotBeRushed,
  rushProductionUnavailable,
  stateRevisionOverflow,
}
