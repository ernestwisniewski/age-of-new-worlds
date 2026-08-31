import 'package:aonw_rust_client/aonw_rust_client.dart';

import '../../map/read_model/map_view.dart';
import '../../map/read_model/player_map_view.dart';
import '../read_model/unit_logistics_view.dart';

final class UnitLogisticsViewMapper {
  const UnitLogisticsViewMapper();

  UnitLogisticsOptionsView options(
    AonwUnitLogisticsOptionsResult wire, {
    required MapView map,
    required String unitId,
    required int expectedRevision,
  }) {
    _validateStamp(wire.stamp, map: map, revision: expectedRevision);
    if (wire.unitId != unitId) {
      throw const FormatException('Logistics options belong to another unit.');
    }
    final result = UnitLogisticsOptionsView(
      stamp: _stamp(wire.stamp),
      unitId: unitId,
      autoExplore: wire.autoExplore == null
          ? null
          : AutoExploreOptionView(
              target: _coordinate(wire.autoExplore!.target, map),
              totalCostUnits: wire.autoExplore!.totalCostUnits,
            ),
      merchantRouteDestinations: _merchantOptions(
        wire.merchantRouteDestinations,
      ),
      merchantTravelDestinations: _merchantOptions(
        wire.merchantTravelDestinations,
      ),
      detachments: [
        for (final option in wire.detachments)
          DetachmentOptionView(
            troopKind: LogisticsTroopKindView.values.byName(
              option.troopKind.name,
            ),
            destination: _coordinate(option.destination, map),
          ),
      ],
    );
    _validateOptions(result);
    return result;
  }

  ({
    LogisticsExecutionView? execution,
    UnitLogisticsRejectionCodeView? rejection,
  })
  command(
    AonwCommandResult wire, {
    required MapView map,
    required UnitLogisticsActionView action,
    required int expectedRevision,
    required int currentRevision,
  }) {
    _validateStamp(
      wire.stamp,
      map: map,
      revision: wire.accepted ? expectedRevision + 1 : currentRevision,
    );
    if (!wire.accepted) return _rejected(wire);
    final evidence = wire.evidence;
    if (wire.rejection != null || evidence is! AonwLogisticsEvidence) {
      throw const FormatException('Accepted logistics result is incomplete.');
    }
    return (
      execution: _execution(evidence.execution, action, map),
      rejection: null,
    );
  }

  static ({
    LogisticsExecutionView? execution,
    UnitLogisticsRejectionCodeView? rejection,
  })
  _rejected(AonwCommandResult wire) {
    if (wire.rejection == null ||
        wire.events.isNotEmpty ||
        wire.evidence != null) {
      throw const FormatException('Rejected logistics result has residue.');
    }
    final rejection = _rejections[wire.rejection!];
    if (rejection == null) {
      throw const FormatException('Unrelated logistics rejection code.');
    }
    return (execution: null, rejection: rejection);
  }

  static LogisticsExecutionView _execution(
    AonwLogisticsExecution wire,
    UnitLogisticsActionView action,
    MapView map,
  ) => switch (wire) {
    AonwAutoExploreExecution() => _autoExploreExecution(wire, action, map),
    AonwMerchantRouteExecution() => _merchantRouteExecution(wire, action),
    AonwMerchantTravelExecution() => _merchantTravelExecution(wire, action),
    AonwTroopDetachmentExecution() => _detachmentExecution(wire, action, map),
  };

  static AutoExploreExecutionView _autoExploreExecution(
    AonwAutoExploreExecution wire,
    UnitLogisticsActionView action,
    MapView map,
  ) {
    if (action is! AutoExploreActionView || wire.unitId != action.unitId) {
      throw const FormatException('Auto-explore evidence mismatches command.');
    }
    return AutoExploreExecutionView(target: _coordinate(wire.target, map));
  }

  static MerchantRouteExecutionView _merchantRouteExecution(
    AonwMerchantRouteExecution wire,
    UnitLogisticsActionView action,
  ) {
    if (action is! AssignMerchantRouteActionView ||
        wire.unitId != action.unitId ||
        wire.destinationCityId != action.destinationCityId) {
      throw const FormatException(
        'Merchant-route evidence mismatches command.',
      );
    }
    return MerchantRouteExecutionView(
      destinationCityId: wire.destinationCityId,
    );
  }

  static MerchantTravelExecutionView _merchantTravelExecution(
    AonwMerchantTravelExecution wire,
    UnitLogisticsActionView action,
  ) {
    if (action is! MoveMerchantToCityActionView ||
        wire.unitId != action.unitId ||
        wire.destinationCityId != action.destinationCityId) {
      throw const FormatException(
        'Merchant-travel evidence mismatches command.',
      );
    }
    return MerchantTravelExecutionView(
      destinationCityId: wire.destinationCityId,
    );
  }

  static TroopDetachmentExecutionView _detachmentExecution(
    AonwTroopDetachmentExecution wire,
    UnitLogisticsActionView action,
    MapView map,
  ) {
    if (action is! DetachTroopActionView ||
        wire.sourceUnitId != action.unitId ||
        wire.troopKind.name != action.troopKind.name) {
      throw const FormatException('Detachment evidence mismatches command.');
    }
    return TroopDetachmentExecutionView(
      detachedUnitId: wire.detachedUnitId,
      destination: _coordinate(wire.destination, map),
    );
  }

  static List<MerchantDestinationOptionView> _merchantOptions(
    List<AonwMerchantDestinationOption> source,
  ) => [
    for (final option in source)
      MerchantDestinationOptionView(
        cityId: option.cityId,
        totalCostUnits: option.totalCostUnits,
      ),
  ];

  static void _validateOptions(UnitLogisticsOptionsView value) {
    for (final options in [
      value.merchantRouteDestinations,
      value.merchantTravelDestinations,
    ]) {
      final ids = <String>{};
      for (final option in options) {
        if (option.cityId.isEmpty || !ids.add(option.cityId)) {
          throw const FormatException('Invalid merchant destination options.');
        }
      }
    }
  }

  static MapHexCoordinate _coordinate(AonwCoordinate value, MapView map) {
    final coordinate = (col: value.col, row: value.row);
    if (!map.contains(coordinate)) {
      throw const FormatException('Logistics coordinate is outside the map.');
    }
    return coordinate;
  }

  static SessionStampView _stamp(AonwSessionStamp value) => SessionStampView(
    revision: value.revision,
    stateDigest: value.stateDigest,
    mapHash: value.mapHash,
    rulesetHash: value.rulesetHash,
  );

  static void _validateStamp(
    AonwSessionStamp value, {
    required MapView map,
    required int revision,
  }) {
    final digest = RegExp(r'^[0-9a-f]{64}$');
    if (value.revision != revision ||
        value.mapHash != map.contentHash ||
        !digest.hasMatch(value.stateDigest) ||
        !digest.hasMatch(value.mapHash) ||
        !digest.hasMatch(value.rulesetHash)) {
      throw const FormatException('Logistics session identity is stale.');
    }
  }
}

const _rejections = <AonwCommandRejectionCode, UnitLogisticsRejectionCodeView>{
  AonwCommandRejectionCode.staleRevision:
      UnitLogisticsRejectionCodeView.staleRevision,
  AonwCommandRejectionCode.matchFinished:
      UnitLogisticsRejectionCodeView.matchFinished,
  AonwCommandRejectionCode.unitNotFound:
      UnitLogisticsRejectionCodeView.unitNotFound,
  AonwCommandRejectionCode.unitNotControlled:
      UnitLogisticsRejectionCodeView.unitNotControlled,
  AonwCommandRejectionCode.unitUnavailable:
      UnitLogisticsRejectionCodeView.unitUnavailable,
  AonwCommandRejectionCode.unitUsesTradeRoutes:
      UnitLogisticsRejectionCodeView.unitUsesTradeRoutes,
  AonwCommandRejectionCode.unitOutOfBounds:
      UnitLogisticsRejectionCodeView.unitOutOfBounds,
  AonwCommandRejectionCode.unitNotScout:
      UnitLogisticsRejectionCodeView.unitNotScout,
  AonwCommandRejectionCode.unitExhausted:
      UnitLogisticsRejectionCodeView.unitExhausted,
  AonwCommandRejectionCode.unitHasPath:
      UnitLogisticsRejectionCodeView.unitHasPath,
  AonwCommandRejectionCode.autoExploreNoTarget:
      UnitLogisticsRejectionCodeView.autoExploreNoTarget,
  AonwCommandRejectionCode.unitNotMerchant:
      UnitLogisticsRejectionCodeView.unitNotMerchant,
  AonwCommandRejectionCode.merchantNotInCity:
      UnitLogisticsRejectionCodeView.merchantNotInCity,
  AonwCommandRejectionCode.destinationCityNotFound:
      UnitLogisticsRejectionCodeView.destinationCityNotFound,
  AonwCommandRejectionCode.destinationCityNotControlled:
      UnitLogisticsRejectionCodeView.destinationCityNotControlled,
  AonwCommandRejectionCode.destinationCityIsOrigin:
      UnitLogisticsRejectionCodeView.destinationCityIsOrigin,
  AonwCommandRejectionCode.destinationCityIsCurrent:
      UnitLogisticsRejectionCodeView.destinationCityIsCurrent,
  AonwCommandRejectionCode.merchantRouteNotFound:
      UnitLogisticsRejectionCodeView.merchantRouteNotFound,
  AonwCommandRejectionCode.merchantCityPathNotFound:
      UnitLogisticsRejectionCodeView.merchantCityPathNotFound,
  AonwCommandRejectionCode.troopNotAvailable:
      UnitLogisticsRejectionCodeView.troopNotAvailable,
  AonwCommandRejectionCode.detachmentSourceOutOfBounds:
      UnitLogisticsRejectionCodeView.detachmentSourceOutOfBounds,
  AonwCommandRejectionCode.detachmentDestinationUnavailable:
      UnitLogisticsRejectionCodeView.detachmentDestinationUnavailable,
  AonwCommandRejectionCode.detachedUnitIdUnavailable:
      UnitLogisticsRejectionCodeView.detachedUnitIdUnavailable,
  AonwCommandRejectionCode.unitBusy: UnitLogisticsRejectionCodeView.unitBusy,
  AonwCommandRejectionCode.stateRevisionOverflow:
      UnitLogisticsRejectionCodeView.stateRevisionOverflow,
  AonwCommandRejectionCode.invalidQueuedMovementPath:
      UnitLogisticsRejectionCodeView.invalidQueuedMovementPath,
  AonwCommandRejectionCode.invalidUnit:
      UnitLogisticsRejectionCodeView.invalidUnit,
  AonwCommandRejectionCode.movementUnitUpdateFailed:
      UnitLogisticsRejectionCodeView.movementUnitUpdateFailed,
};
