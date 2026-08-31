import '../../map/read_model/map_view.dart';
import '../../map/read_model/player_map_view.dart';

enum LogisticsTroopKindView { settler, warrior, archer }

final class AutoExploreOptionView {
  const AutoExploreOptionView({
    required this.target,
    required this.totalCostUnits,
  });

  final MapHexCoordinate target;
  final int totalCostUnits;
}

final class MerchantDestinationOptionView {
  const MerchantDestinationOptionView({
    required this.cityId,
    required this.totalCostUnits,
  });

  final String cityId;
  final int totalCostUnits;
}

final class DetachmentOptionView {
  const DetachmentOptionView({
    required this.troopKind,
    required this.destination,
  });

  final LogisticsTroopKindView troopKind;
  final MapHexCoordinate destination;
}

final class UnitLogisticsOptionsView {
  UnitLogisticsOptionsView({
    required this.stamp,
    required this.unitId,
    required this.autoExplore,
    required List<MerchantDestinationOptionView> merchantRouteDestinations,
    required List<MerchantDestinationOptionView> merchantTravelDestinations,
    required List<DetachmentOptionView> detachments,
  }) : merchantRouteDestinations = List.unmodifiable(merchantRouteDestinations),
       merchantTravelDestinations = List.unmodifiable(
         merchantTravelDestinations,
       ),
       detachments = List.unmodifiable(detachments);

  final SessionStampView stamp;
  final String unitId;
  final AutoExploreOptionView? autoExplore;
  final List<MerchantDestinationOptionView> merchantRouteDestinations;
  final List<MerchantDestinationOptionView> merchantTravelDestinations;
  final List<DetachmentOptionView> detachments;

  bool get isEmpty =>
      autoExplore == null &&
      merchantRouteDestinations.isEmpty &&
      merchantTravelDestinations.isEmpty &&
      detachments.isEmpty;
}

sealed class UnitLogisticsActionView {
  const UnitLogisticsActionView({required this.unitId});

  final String unitId;
  String get labelKey;
}

final class AutoExploreActionView extends UnitLogisticsActionView {
  const AutoExploreActionView({required super.unitId});

  @override
  String get labelKey => 'autoExplore';
}

final class AssignMerchantRouteActionView extends UnitLogisticsActionView {
  const AssignMerchantRouteActionView({
    required super.unitId,
    required this.destinationCityId,
  });

  final String destinationCityId;

  @override
  String get labelKey => 'merchantRoute';
}

final class MoveMerchantToCityActionView extends UnitLogisticsActionView {
  const MoveMerchantToCityActionView({
    required super.unitId,
    required this.destinationCityId,
  });

  final String destinationCityId;

  @override
  String get labelKey => 'merchantTravel';
}

final class DetachTroopActionView extends UnitLogisticsActionView {
  const DetachTroopActionView({required super.unitId, required this.troopKind});

  final LogisticsTroopKindView troopKind;

  @override
  String get labelKey => 'detachTroop';
}

enum UnitLogisticsRejectionCodeView {
  staleRevision,
  matchFinished,
  unitNotFound,
  unitNotControlled,
  unitUnavailable,
  unitUsesTradeRoutes,
  unitOutOfBounds,
  unitNotScout,
  unitExhausted,
  unitHasPath,
  autoExploreNoTarget,
  unitNotMerchant,
  merchantNotInCity,
  destinationCityNotFound,
  destinationCityNotControlled,
  destinationCityIsOrigin,
  destinationCityIsCurrent,
  merchantRouteNotFound,
  merchantCityPathNotFound,
  troopNotAvailable,
  detachmentSourceOutOfBounds,
  detachmentDestinationUnavailable,
  detachedUnitIdUnavailable,
  unitBusy,
  stateRevisionOverflow,
  invalidQueuedMovementPath,
  invalidUnit,
  movementUnitUpdateFailed,
}

sealed class LogisticsExecutionView {
  const LogisticsExecutionView();
}

final class AutoExploreExecutionView extends LogisticsExecutionView {
  const AutoExploreExecutionView({required this.target});

  final MapHexCoordinate target;
}

final class MerchantRouteExecutionView extends LogisticsExecutionView {
  const MerchantRouteExecutionView({required this.destinationCityId});

  final String destinationCityId;
}

final class MerchantTravelExecutionView extends LogisticsExecutionView {
  const MerchantTravelExecutionView({required this.destinationCityId});

  final String destinationCityId;
}

final class TroopDetachmentExecutionView extends LogisticsExecutionView {
  const TroopDetachmentExecutionView({
    required this.detachedUnitId,
    required this.destination,
  });

  final String detachedUnitId;
  final MapHexCoordinate destination;
}

final class UnitLogisticsCommandResultView {
  const UnitLogisticsCommandResultView.accepted({
    required this.player,
    required this.execution,
  }) : accepted = true,
       rejectionCode = null;

  const UnitLogisticsCommandResultView.rejected({required this.rejectionCode})
    : accepted = false,
      player = null,
      execution = null;

  final bool accepted;
  final UnitLogisticsRejectionCodeView? rejectionCode;
  final PlayerMapView? player;
  final LogisticsExecutionView? execution;
}
