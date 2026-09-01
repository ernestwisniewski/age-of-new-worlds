import '../../map/read_model/map_view.dart';
import '../../map/read_model/player_map_view.dart';

final class CityView {
  CityView({
    required this.id,
    required this.ownerPlayerId,
    required this.name,
    required this.center,
    required List<MapHexCoordinate> visibleControlledHexes,
    required this.hitPoints,
    required this.ownedDetails,
  }) : visibleControlledHexes = List.unmodifiable(visibleControlledHexes);

  final String id;
  final String ownerPlayerId;
  final String name;
  final MapHexCoordinate center;
  final List<MapHexCoordinate> visibleControlledHexes;
  final int? hitPoints;
  final OwnedCityDetailsView? ownedDetails;
}

final class OwnedCityDetailsView {
  OwnedCityDetailsView({
    required this.population,
    required this.storedFood,
    required this.maxHexes,
    required this.territoryRadius,
    required List<MapHexCoordinate> workedHexes,
    required this.preferredExpansionHex,
    List<String> buildings = const [],
    List<String> wonders = const [],
    this.productionQueue,
    this.productionOverflow = 0,
    this.specialization,
  }) : workedHexes = List.unmodifiable(workedHexes),
       buildings = List.unmodifiable(buildings),
       wonders = List.unmodifiable(wonders);

  final int population;
  final int storedFood;
  final int maxHexes;
  final int territoryRadius;
  final List<MapHexCoordinate> workedHexes;
  final MapHexCoordinate? preferredExpansionHex;
  final List<String> buildings;
  final List<String> wonders;
  final CityProductionQueueView? productionQueue;
  final int productionOverflow;
  final String? specialization;
}

final class CityProductionQueueView {
  CityProductionQueueView({
    required this.targetKind,
    required this.target,
    required this.investedProduction,
    required Map<MapResource, int> resourceAllocation,
  }) : resourceAllocation = Map.unmodifiable(resourceAllocation);

  final String targetKind;
  final String target;
  final int investedProduction;
  final Map<MapResource, int> resourceAllocation;
}

final class CityFoundingDraftView {
  CityFoundingDraftView({
    required this.founderUnitId,
    required this.center,
    required List<MapHexCoordinate> controlledHexes,
  }) : controlledHexes = List.unmodifiable(controlledHexes);

  final String founderUnitId;
  final MapHexCoordinate center;
  final List<MapHexCoordinate> controlledHexes;
}

final class CityFoundingOptionsView {
  CityFoundingOptionsView({
    required this.stamp,
    required this.founderUnitId,
    required this.center,
    required List<MapHexCoordinate> selectedControlledHexes,
    required List<MapHexCoordinate> availableControlledHexes,
    required List<MapHexCoordinate> rankedAvailableControlledHexes,
    required this.requiredControlledHexes,
    required this.maximumRadius,
  }) : selectedControlledHexes = List.unmodifiable(selectedControlledHexes),
       availableControlledHexes = List.unmodifiable(availableControlledHexes),
       rankedAvailableControlledHexes = List.unmodifiable(
         rankedAvailableControlledHexes,
       );

  final SessionStampView stamp;
  final String founderUnitId;
  final MapHexCoordinate center;
  final List<MapHexCoordinate> selectedControlledHexes;
  final List<MapHexCoordinate> availableControlledHexes;
  final List<MapHexCoordinate> rankedAvailableControlledHexes;
  final int requiredControlledHexes;
  final int maximumRadius;
}

final class CityWorkedHexOptionsView {
  CityWorkedHexOptionsView({
    required this.stamp,
    required this.cityId,
    required this.center,
    required List<MapHexCoordinate> controlledHexes,
    required List<MapHexCoordinate> availableHexes,
    required List<MapHexCoordinate> selectedHexes,
    required List<MapHexCoordinate> effectiveHexes,
    required this.limit,
  }) : controlledHexes = List.unmodifiable(controlledHexes),
       availableHexes = List.unmodifiable(availableHexes),
       selectedHexes = List.unmodifiable(selectedHexes),
       effectiveHexes = List.unmodifiable(effectiveHexes);

  final SessionStampView stamp;
  final String cityId;
  final MapHexCoordinate center;
  final List<MapHexCoordinate> controlledHexes;
  final List<MapHexCoordinate> availableHexes;
  final List<MapHexCoordinate> selectedHexes;
  final List<MapHexCoordinate> effectiveHexes;
  final int limit;
}

final class CityExpansionCandidateView {
  const CityExpansionCandidateView({
    required this.coordinate,
    required this.score,
    required this.distance,
  });

  final MapHexCoordinate coordinate;
  final int score;
  final int distance;
}

final class CityExpansionOptionsView {
  CityExpansionOptionsView({
    required this.stamp,
    required this.cityId,
    required List<MapHexCoordinate> controlledHexes,
    required this.preferredHex,
    required List<CityExpansionCandidateView> candidates,
  }) : controlledHexes = List.unmodifiable(controlledHexes),
       candidates = List.unmodifiable(candidates);

  final SessionStampView stamp;
  final String cityId;
  final List<MapHexCoordinate> controlledHexes;
  final MapHexCoordinate? preferredHex;
  final List<CityExpansionCandidateView> candidates;
}

enum CityYieldContributionKindView {
  center,
  population,
  worker,
  passiveImprovement,
  artifact,
}

final class YieldValueView {
  const YieldValueView({
    required this.food,
    required this.production,
    required this.gold,
    required this.defense,
  });

  final int food;
  final int production;
  final int gold;
  final int defense;
}

final class CityYieldContributionView {
  const CityYieldContributionView({
    required this.kind,
    required this.coordinate,
    required this.value,
  });

  final CityYieldContributionKindView kind;
  final MapHexCoordinate coordinate;
  final YieldValueView value;
}

final class CityYieldView {
  CityYieldView({
    required this.stamp,
    required this.cityId,
    required List<CityYieldContributionView> contributions,
    required this.total,
  }) : contributions = List.unmodifiable(contributions);

  final SessionStampView stamp;
  final String cityId;
  final List<CityYieldContributionView> contributions;
  final YieldValueView total;
}

final class CityInspectionView {
  const CityInspectionView({
    required this.workedHexes,
    required this.expansion,
    required this.cityYield,
  });

  final CityWorkedHexOptionsView workedHexes;
  final CityExpansionOptionsView expansion;
  final CityYieldView cityYield;
}

sealed class CityActionView {
  const CityActionView();
}

final class FoundCityActionView extends CityActionView {
  FoundCityActionView({
    required this.founderUnitId,
    required List<MapHexCoordinate> controlledHexes,
  }) : controlledHexes = List.unmodifiable(controlledHexes);

  final String founderUnitId;
  final List<MapHexCoordinate> controlledHexes;
}

final class ToggleWorkedHexActionView extends CityActionView {
  const ToggleWorkedHexActionView({required this.cityId, required this.target});

  final String cityId;
  final MapHexCoordinate target;
}

final class SelectCityExpansionActionView extends CityActionView {
  const SelectCityExpansionActionView({
    required this.cityId,
    required this.target,
  });

  final String cityId;
  final MapHexCoordinate target;
}

enum CityRejectionCodeView {
  staleRevision,
  matchFinished,
  cityFounderNotFound,
  cityFounderNotControlled,
  cityFounderBusy,
  cityFounderInvalid,
  cityFounderNoSettlers,
  citySiteInvalid,
  cityCenterOccupied,
  cityCenterClaimed,
  cityCenterTooClose,
  cityControlledHexesInvalid,
  cityNotFound,
  cityNotControlled,
  workedHexUnavailable,
  workedHexLimitReached,
  cityExpansionHexUnavailable,
  stateRevisionOverflow,
}

final class CityCommandResultView {
  const CityCommandResultView.accepted({required this.player})
    : accepted = true,
      rejectionCode = null;

  const CityCommandResultView.rejected({required this.rejectionCode})
    : accepted = false,
      player = null;

  final bool accepted;
  final CityRejectionCodeView? rejectionCode;
  final PlayerMapView? player;
}
