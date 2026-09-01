import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../../map/read_model/map_view.dart';
import '../../map/read_model/player_map_view.dart';
import '../read_model/city_view.dart';

final class CityViewMapper {
  const CityViewMapper();

  CityFoundingOptionsView founding(
    AonwCityFoundingOptionsResult wire, {
    required MapView map,
    required VisibleUnitView founder,
    required int expectedRevision,
  }) {
    _validateStamp(wire.stamp, map: map, revision: expectedRevision);
    final center = _coordinate(wire.center, map);
    if (wire.founderUnitId != founder.id || center != founder.coordinate) {
      throw const FormatException('City founding options mismatch request.');
    }
    final selected = _coordinates(
      wire.selectedControlledHexes,
      map,
      'selected city founding hex',
    );
    final available = _coordinates(
      wire.availableControlledHexes,
      map,
      'available city founding hex',
    );
    final ranked = _coordinates(
      wire.rankedAvailableControlledHexes,
      map,
      'ranked available city founding hex',
    );
    if (wire.requiredControlledHexes == 0 ||
        selected.length > wire.requiredControlledHexes ||
        wire.maximumRadius == 0 ||
        selected.any(available.contains) ||
        ranked.length != available.length ||
        ranked.any((coordinate) => !available.contains(coordinate))) {
      throw const FormatException('City founding options are inconsistent.');
    }
    return CityFoundingOptionsView(
      stamp: _stamp(wire.stamp),
      founderUnitId: wire.founderUnitId,
      center: center,
      selectedControlledHexes: selected,
      availableControlledHexes: available,
      rankedAvailableControlledHexes: ranked,
      requiredControlledHexes: wire.requiredControlledHexes,
      maximumRadius: wire.maximumRadius,
    );
  }

  CityInspectionView inspection({
    required AonwCityWorkedHexOptionsResult worked,
    required AonwCityExpansionOptionsResult expansion,
    required AonwCityYieldResult cityYield,
    required MapView map,
    required CityView city,
    required int expectedRevision,
  }) {
    for (final stamp in [worked.stamp, expansion.stamp, cityYield.stamp]) {
      _validateStamp(stamp, map: map, revision: expectedRevision);
    }
    if (worked.cityId != city.id ||
        expansion.cityId != city.id ||
        cityYield.cityId != city.id ||
        _coordinate(worked.center, map) != city.center) {
      throw const FormatException('City inspection mismatches request.');
    }
    return CityInspectionView(
      workedHexes: _worked(worked, map),
      expansion: _expansion(expansion, map),
      cityYield: _yield(cityYield, map),
    );
  }

  ({CityRejectionCodeView? rejection}) command(
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
        throw const FormatException('Accepted city result has residue.');
      }
      return (rejection: null);
    }
    if (wire.rejection == null ||
        wire.events.isNotEmpty ||
        wire.evidence != null) {
      throw const FormatException('Rejected city result has residue.');
    }
    final rejection = _rejections[wire.rejection!];
    if (rejection == null) {
      throw const FormatException('Unrelated city rejection code.');
    }
    return (rejection: rejection);
  }
}

CityWorkedHexOptionsView _worked(
  AonwCityWorkedHexOptionsResult wire,
  MapView map,
) {
  final controlled = _coordinates(
    wire.controlledHexes,
    map,
    'controlled city hex',
  );
  final available = _coordinates(
    wire.availableHexes,
    map,
    'available worked hex',
  );
  final selected = _coordinates(wire.selectedHexes, map, 'selected worked hex');
  final effective = _coordinates(
    wire.effectiveHexes,
    map,
    'effective worked hex',
  );
  if (available.any((value) => !controlled.contains(value)) ||
      selected.any((value) => !controlled.contains(value)) ||
      effective.any((value) => !controlled.contains(value)) ||
      selected.length > wire.limit) {
    throw const FormatException('Worked city options are inconsistent.');
  }
  return CityWorkedHexOptionsView(
    stamp: _stamp(wire.stamp),
    cityId: wire.cityId,
    center: _coordinate(wire.center, map),
    controlledHexes: controlled,
    availableHexes: available,
    selectedHexes: selected,
    effectiveHexes: effective,
    limit: wire.limit,
  );
}

CityExpansionOptionsView _expansion(
  AonwCityExpansionOptionsResult wire,
  MapView map,
) {
  final controlled = _coordinates(
    wire.controlledHexes,
    map,
    'controlled expansion hex',
  );
  final candidateCoordinates = <MapHexCoordinate>{};
  final candidates = <CityExpansionCandidateView>[];
  for (final candidate in wire.candidates) {
    final coordinate = _coordinate(candidate.coordinate, map);
    if (!candidateCoordinates.add(coordinate) ||
        controlled.contains(coordinate)) {
      throw const FormatException('City expansion candidates are invalid.');
    }
    candidates.add(
      CityExpansionCandidateView(
        coordinate: coordinate,
        score: candidate.score,
        distance: candidate.distance,
      ),
    );
  }
  final preferred = wire.preferredHex == null
      ? null
      : _coordinate(wire.preferredHex!, map);
  if (preferred != null && !candidateCoordinates.contains(preferred)) {
    throw const FormatException('Preferred city expansion is unavailable.');
  }
  return CityExpansionOptionsView(
    stamp: _stamp(wire.stamp),
    cityId: wire.cityId,
    controlledHexes: controlled,
    preferredHex: preferred,
    candidates: candidates,
  );
}

CityYieldView _yield(AonwCityYieldResult wire, MapView map) => CityYieldView(
  stamp: _stamp(wire.stamp),
  cityId: wire.cityId,
  contributions: [
    for (final contribution in wire.contributions)
      CityYieldContributionView(
        kind: CityYieldContributionKindView.values.byName(
          contribution.kind.name,
        ),
        coordinate: _coordinate(contribution.coordinate, map),
        value: _yieldValue(contribution.value),
      ),
  ],
  total: _yieldValue(wire.total),
);

YieldValueView _yieldValue(AonwYieldValue value) => YieldValueView(
  food: value.food,
  production: value.production,
  gold: value.gold,
  defense: value.defense,
);

List<MapHexCoordinate> _coordinates(
  List<AonwCoordinate> source,
  MapView map,
  String label,
) {
  final seen = <MapHexCoordinate>{};
  final values = <MapHexCoordinate>[];
  for (final value in source) {
    final coordinate = _coordinate(value, map);
    if (!seen.add(coordinate)) {
      throw FormatException('Duplicate $label.');
    }
    values.add(coordinate);
  }
  return values;
}

MapHexCoordinate _coordinate(AonwCoordinate value, MapView map) {
  final coordinate = (col: value.col, row: value.row);
  if (!map.contains(coordinate)) {
    throw const FormatException('City coordinate is outside the map.');
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
    throw const FormatException('City session identity is stale.');
  }
}

const _rejections = <AonwCommandRejectionCode, CityRejectionCodeView>{
  AonwCommandRejectionCode.staleRevision: CityRejectionCodeView.staleRevision,
  AonwCommandRejectionCode.matchFinished: CityRejectionCodeView.matchFinished,
  AonwCommandRejectionCode.cityFounderNotFound:
      CityRejectionCodeView.cityFounderNotFound,
  AonwCommandRejectionCode.cityFounderNotControlled:
      CityRejectionCodeView.cityFounderNotControlled,
  AonwCommandRejectionCode.cityFounderBusy:
      CityRejectionCodeView.cityFounderBusy,
  AonwCommandRejectionCode.cityFounderInvalid:
      CityRejectionCodeView.cityFounderInvalid,
  AonwCommandRejectionCode.cityFounderNoSettlers:
      CityRejectionCodeView.cityFounderNoSettlers,
  AonwCommandRejectionCode.citySiteInvalid:
      CityRejectionCodeView.citySiteInvalid,
  AonwCommandRejectionCode.cityCenterOccupied:
      CityRejectionCodeView.cityCenterOccupied,
  AonwCommandRejectionCode.cityCenterClaimed:
      CityRejectionCodeView.cityCenterClaimed,
  AonwCommandRejectionCode.cityCenterTooClose:
      CityRejectionCodeView.cityCenterTooClose,
  AonwCommandRejectionCode.cityControlledHexesInvalid:
      CityRejectionCodeView.cityControlledHexesInvalid,
  AonwCommandRejectionCode.cityNotFound: CityRejectionCodeView.cityNotFound,
  AonwCommandRejectionCode.cityNotControlled:
      CityRejectionCodeView.cityNotControlled,
  AonwCommandRejectionCode.workedHexUnavailable:
      CityRejectionCodeView.workedHexUnavailable,
  AonwCommandRejectionCode.workedHexLimitReached:
      CityRejectionCodeView.workedHexLimitReached,
  AonwCommandRejectionCode.cityExpansionHexUnavailable:
      CityRejectionCodeView.cityExpansionHexUnavailable,
  AonwCommandRejectionCode.stateRevisionOverflow:
      CityRejectionCodeView.stateRevisionOverflow,
};
