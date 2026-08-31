import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../../map/read_model/map_view.dart';
import '../../map/read_model/player_map_view.dart';
import '../read_model/production_view.dart';

final class ProductionViewMapper {
  const ProductionViewMapper();

  ProductionOptionsView options(
    AonwProductionOptionsResult wire, {
    required MapView map,
    required PlayerMapView player,
    required String cityId,
    required int expectedRevision,
  }) {
    _validateStamp(wire.stamp, map: map, revision: expectedRevision);
    if (wire.cityId != cityId || player.controlledCityById(cityId) == null) {
      throw const FormatException('Production options mismatch request.');
    }
    return ProductionOptionsView(
      stamp: _stamp(wire.stamp),
      cityId: cityId,
      currentTarget: wire.currentTarget == null
          ? null
          : _target(wire.currentTarget!),
      investedProduction: wire.investedProduction,
      productionOverflow: wire.productionOverflow,
      buildings: [
        for (final value in wire.buildings)
          _option(value, AonwCityProductionTargetKind.building),
      ],
      units: [for (final value in wire.units) _unitOption(value)],
      projects: [
        for (final value in wire.projects)
          _option(value, AonwCityProductionTargetKind.project),
      ],
      wonders: [
        for (final value in wire.wonders)
          _option(value, AonwCityProductionTargetKind.wonder),
      ],
      specializations: [
        for (final value in wire.specializations)
          CitySpecializationOptionView(
            specialization: value.specialization.name,
            requiredBuilding: value.requiredBuilding.name,
            blocker: _optionalBlocker(value.rejection),
          ),
      ],
    );
  }

  StrategicResourceProjectionView resources(
    AonwStrategicResourceProjectionResult wire, {
    required MapView map,
    required PlayerMapView player,
    required int expectedRevision,
  }) {
    _validateStamp(wire.stamp, map: map, revision: expectedRevision);
    if (wire.playerId != player.actorPlayerId) {
      throw const FormatException('Resource projection mismatches recipient.');
    }
    final output = <StrategicResourceAmountView>[];
    final seenOutput = <MapResource>{};
    for (final value in wire.output) {
      final resource = MapResource.values.byName(value.resource.name);
      if (!seenOutput.add(resource) || value.amount <= 0) {
        throw const FormatException('Resource output is invalid.');
      }
      output.add(
        StrategicResourceAmountView(resource: resource, amount: value.amount),
      );
    }
    final sources = <StrategicResourceSourceView>[];
    final seenSources = <(String, MapHexCoordinate, MapResource)>{};
    for (final value in wire.sources) {
      final coordinate = _coordinate(value.coordinate, map);
      final resource = MapResource.values.byName(value.resource.name);
      if (player.controlledCityById(value.cityId) == null ||
          value.amountPerTurn <= 0 ||
          !seenSources.add((value.cityId, coordinate, resource))) {
        throw const FormatException('Resource source is invalid.');
      }
      sources.add(
        StrategicResourceSourceView(
          cityId: value.cityId,
          coordinate: coordinate,
          resource: resource,
          improvement: value.improvement.name,
          amountPerTurn: value.amountPerTurn,
        ),
      );
    }
    return StrategicResourceProjectionView(
      stamp: _stamp(wire.stamp),
      playerId: wire.playerId,
      output: output,
      sources: sources,
    );
  }

  ({ProductionRejectionCodeView? rejection}) command(
    AonwCommandResult wire, {
    required MapView map,
    required int expectedRevision,
    required int currentRevision,
  }) {
    _validateStamp(
      wire.stamp,
      map: map,
      revision: wire.accepted ? expectedRevision + 1 : currentRevision,
    );
    if (wire.accepted) {
      if (wire.rejection != null ||
          wire.events.isNotEmpty ||
          wire.evidence != null) {
        throw const FormatException('Accepted production result has residue.');
      }
      return (rejection: null);
    }
    if (wire.rejection == null ||
        wire.events.isNotEmpty ||
        wire.evidence != null) {
      throw const FormatException('Rejected production result has residue.');
    }
    return (rejection: _requiredBlocker(wire.rejection!));
  }
}

ProductionOptionView _option(
  AonwProductionOption wire,
  AonwCityProductionTargetKind requiredKind,
) {
  if (wire.target.kind != requiredKind || wire.cost < 0) {
    throw const FormatException('Production option is invalid.');
  }
  return ProductionOptionView(
    target: _target(wire.target),
    cost: wire.cost,
    blocker: _optionalBlocker(wire.rejection),
  );
}

UnitProductionOptionView _unitOption(AonwUnitProductionOption wire) {
  final option = _option(wire.option, AonwCityProductionTargetKind.unit);
  final indices = <int>{};
  for (final index in wire.affordableResourceOptionIndices) {
    if (index >= wire.resourceOptions.length || !indices.add(index)) {
      throw const FormatException('Affordable resource option is invalid.');
    }
  }
  return UnitProductionOptionView(
    option: option,
    resourceOptions: [
      for (final stockpile in wire.resourceOptions)
        {
          for (final entry in stockpile.entries)
            MapResource.values.byName(entry.key.name): entry.value,
        },
    ],
    affordableResourceOptionIndices: indices,
  );
}

ProductionTargetView _target(AonwCityProductionTarget value) =>
    switch (value.kind) {
      AonwCityProductionTargetKind.building => BuildingProductionTargetView(
        value.buildingType!.name,
      ),
      AonwCityProductionTargetKind.unit => UnitProductionTargetView(
        VisibleUnitKind.values.byName(value.unitType!.name),
      ),
      AonwCityProductionTargetKind.project => ProjectProductionTargetView(
        value.projectType!.name,
      ),
      AonwCityProductionTargetKind.wonder => WonderProductionTargetView(
        value.wonderType!.name,
      ),
    };

MapHexCoordinate _coordinate(AonwCoordinate value, MapView map) {
  final coordinate = (col: value.col, row: value.row);
  if (!map.contains(coordinate)) {
    throw const FormatException('Resource source is outside the map.');
  }
  return coordinate;
}

SessionStampView _stamp(AonwSessionStamp value) => SessionStampView(
  revision: value.revision,
  stateDigest: value.stateDigest,
  mapHash: value.mapHash,
  rulesetHash: value.rulesetHash,
);

void _validateStamp(
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
    throw const FormatException('Production session identity is stale.');
  }
}

ProductionRejectionCodeView? _optionalBlocker(
  AonwCommandRejectionCode? value,
) => value == null ? null : _requiredBlocker(value);

ProductionRejectionCodeView _requiredBlocker(AonwCommandRejectionCode value) {
  final rejection = _rejections[value];
  if (rejection == null) {
    throw const FormatException('Unrelated production rejection code.');
  }
  return rejection;
}

const _rejections = <AonwCommandRejectionCode, ProductionRejectionCodeView>{
  AonwCommandRejectionCode.staleRevision:
      ProductionRejectionCodeView.staleRevision,
  AonwCommandRejectionCode.matchFinished:
      ProductionRejectionCodeView.matchFinished,
  AonwCommandRejectionCode.cityNotFound:
      ProductionRejectionCodeView.cityNotFound,
  AonwCommandRejectionCode.cityNotControlled:
      ProductionRejectionCodeView.cityNotControlled,
  AonwCommandRejectionCode.buildingNotAvailable:
      ProductionRejectionCodeView.buildingNotAvailable,
  AonwCommandRejectionCode.unitProductionInvalidResourceOption:
      ProductionRejectionCodeView.unitProductionInvalidResourceOption,
  AonwCommandRejectionCode.unitProductionNotAvailable:
      ProductionRejectionCodeView.unitProductionNotAvailable,
  AonwCommandRejectionCode.unitProductionRequiresResource:
      ProductionRejectionCodeView.unitProductionRequiresResource,
  AonwCommandRejectionCode.unitProductionMissingStrategicResource:
      ProductionRejectionCodeView.unitProductionMissingStrategicResource,
  AonwCommandRejectionCode.unitProductionRequiresCoast:
      ProductionRejectionCodeView.unitProductionRequiresCoast,
  AonwCommandRejectionCode.unitSupplyLimitReached:
      ProductionRejectionCodeView.unitSupplyLimitReached,
  AonwCommandRejectionCode.wonderNotAvailable:
      ProductionRejectionCodeView.wonderNotAvailable,
  AonwCommandRejectionCode.citySpecializationLocked:
      ProductionRejectionCodeView.citySpecializationLocked,
  AonwCommandRejectionCode.citySpecializationUnchanged:
      ProductionRejectionCodeView.citySpecializationUnchanged,
  AonwCommandRejectionCode.citySpecializationMissingBuilding:
      ProductionRejectionCodeView.citySpecializationMissingBuilding,
  AonwCommandRejectionCode.productionQueueEmpty:
      ProductionRejectionCodeView.productionQueueEmpty,
  AonwCommandRejectionCode.projectCannotBeRushed:
      ProductionRejectionCodeView.projectCannotBeRushed,
  AonwCommandRejectionCode.rushProductionUnavailable:
      ProductionRejectionCodeView.rushProductionUnavailable,
  AonwCommandRejectionCode.stateRevisionOverflow:
      ProductionRejectionCodeView.stateRevisionOverflow,
};
