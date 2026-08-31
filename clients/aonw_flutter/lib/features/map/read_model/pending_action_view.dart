import 'map_view.dart';

enum FieldImprovementKind {
  farm,
  riverFarm,
  mine,
  lumberMill,
  pasture,
  camp,
  quarry,
  fishingBoats,
  orchard,
  plantation,
  vineyard,
  tradingPost,
  prospectorCamp,
  horseRanch,
  pearlDivers,
  coalShaft,
  oilWell,
  bauxiteMine,
  uraniumMine,
}

sealed class PendingActionView {
  const PendingActionView();
}

final class PendingResearchSelectionView extends PendingActionView {
  const PendingResearchSelectionView();
}

final class PendingCityWorkedHexSelectionView extends PendingActionView {
  const PendingCityWorkedHexSelectionView({required this.cityId});

  final String cityId;
}

final class PendingCityExpansionSelectionView extends PendingActionView {
  const PendingCityExpansionSelectionView({required this.cityId});

  final String cityId;
}

final class PendingWorkerActionSelectionView extends PendingActionView {
  const PendingWorkerActionSelectionView({
    required this.unitId,
    required this.improvement,
  });

  final String unitId;
  final FieldImprovementKind? improvement;
}

final class PendingMerchantTradeRouteSelectionView extends PendingActionView {
  const PendingMerchantTradeRouteSelectionView({required this.unitId});

  final String unitId;
}

final class PendingMerchantMoveToCitySelectionView extends PendingActionView {
  const PendingMerchantMoveToCitySelectionView({required this.unitId});

  final String unitId;
}

final class PendingUnitTurnSkipView extends PendingActionView {
  const PendingUnitTurnSkipView({
    required this.unitId,
    required this.restoreMovementUnits,
  });

  final String unitId;
  final int restoreMovementUnits;
}

final class PendingAttackTargetingView extends PendingActionView {
  const PendingAttackTargetingView({
    required this.unitId,
    required this.defender,
  });

  final String unitId;
  final MapHexCoordinate? defender;
}

final class PendingCommanderMergeSelectionView extends PendingActionView {
  const PendingCommanderMergeSelectionView({required this.unitId});

  final String unitId;
}
