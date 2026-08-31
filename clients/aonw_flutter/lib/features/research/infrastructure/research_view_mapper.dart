import 'package:aonw_rust_client/aonw_rust_client.dart';

import '../../map/read_model/map_view.dart';
import '../../map/read_model/player_map_view.dart';
import '../read_model/research_view.dart';

final class ResearchViewMapper {
  const ResearchViewMapper();

  ResearchOptionsView options(
    AonwResearchOptionsResult wire, {
    required MapView map,
    required PlayerMapView player,
    required int expectedRevision,
  }) {
    _validateStamp(wire.stamp, map: map, revision: expectedRevision);
    if (wire.playerId != player.actorPlayerId ||
        wire.scienceOverflow < 0 ||
        wire.scienceYield.total < 0 ||
        wire.options.length != AonwTechnologyId.values.length) {
      throw const FormatException('Research projection identity is invalid.');
    }
    for (var index = 0; index < wire.options.length; index++) {
      if (wire.options[index].technology != AonwTechnologyId.values[index]) {
        throw const FormatException('Research catalog order is invalid.');
      }
    }
    _validateScience(wire.scienceYield, player);
    final options = [for (final option in wire.options) _option(option)];
    final active = wire.activeTechnology;
    if (active != null &&
        !wire.options.any(
          (option) =>
              option.technology == active &&
              option.availability == AonwTechnologyAvailability.active,
        )) {
      throw const FormatException('Active research target is inconsistent.');
    }
    return ResearchOptionsView(
      stamp: _stamp(wire.stamp),
      playerId: wire.playerId,
      activeTechnology: active == null
          ? null
          : TechnologyIdView.values.byName(active.name),
      scienceOverflow: wire.scienceOverflow,
      scienceYield: ScienceYieldBreakdownView(
        total: wire.scienceYield.total,
        byCityId: wire.scienceYield.byCityId,
        sources: [
          for (final source in wire.scienceYield.sources)
            ScienceYieldSourceView(
              cityId: source.cityId,
              amount: source.amount,
              kind: ScienceYieldSourceKindView.values.byName(source.kind.name),
            ),
        ],
      ),
      options: options,
    );
  }

  ResearchRejectionCodeView? command(
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
        throw const FormatException('Accepted research result is malformed.');
      }
      return null;
    }
    if (wire.rejection == null ||
        wire.events.isNotEmpty ||
        wire.evidence != null) {
      throw const FormatException('Rejected research result has residue.');
    }
    final rejection = _rejections[wire.rejection];
    if (rejection == null) {
      throw const FormatException('Unrelated research rejection code.');
    }
    return rejection;
  }
}

ResearchOptionView _option(AonwResearchOption value) {
  if (value.effectiveCost < 1 ||
      value.progress < 0 ||
      value.progress > value.effectiveCost ||
      value.boostDiscountBasisPoints > 10000 ||
      value.prerequisites.toSet().length != value.prerequisites.length ||
      value.blockedBy.toSet().length != value.blockedBy.length ||
      value.prerequisites.contains(value.technology) ||
      value.blockedBy.contains(value.technology)) {
    throw const FormatException('Research option is malformed.');
  }
  return ResearchOptionView(
    technology: TechnologyIdView.values.byName(value.technology.name),
    availability: TechnologyAvailabilityView.values.byName(
      value.availability.name,
    ),
    effectiveCost: value.effectiveCost,
    progress: value.progress,
    boostDiscountBasisPoints: value.boostDiscountBasisPoints,
    prerequisites: [
      for (final item in value.prerequisites)
        TechnologyIdView.values.byName(item.name),
    ],
    blockedBy: [
      for (final item in value.blockedBy)
        TechnologyIdView.values.byName(item.name),
    ],
    unlocks: [for (final item in value.unlocks) _unlock(item)],
  );
}

TechnologyUnlockView _unlock(AonwTechnologyUnlock value) => switch (value) {
  AonwTechnologyBuildingUnlock(:final building) => TechnologyUnlockView(
    kind: TechnologyUnlockKindView.building,
    target: building.name,
  ),
  AonwTechnologyImprovementUnlock(:final improvement) => TechnologyUnlockView(
    kind: TechnologyUnlockKindView.improvement,
    target: improvement.name,
  ),
  AonwTechnologyResourceVisibilityUnlock(:final resource) =>
    TechnologyUnlockView(
      kind: TechnologyUnlockKindView.resourceVisibility,
      target: resource.name,
    ),
  AonwTechnologyUnitUnlock(:final unit) => TechnologyUnlockView(
    kind: TechnologyUnlockKindView.unit,
    target: unit.name,
  ),
  AonwTechnologyWonderUnlock(:final wonder) => TechnologyUnlockView(
    kind: TechnologyUnlockKindView.wonder,
    target: wonder.name,
  ),
};

void _validateScience(AonwScienceYieldBreakdown value, PlayerMapView player) {
  var sourceTotal = 0;
  final byCity = <String, int>{};
  for (final source in value.sources) {
    if (source.cityId.isEmpty ||
        source.amount < 0 ||
        player.controlledCityById(source.cityId) == null) {
      throw const FormatException('Science source is invalid.');
    }
    sourceTotal += source.amount;
    byCity.update(
      source.cityId,
      (amount) => amount + source.amount,
      ifAbsent: () => source.amount,
    );
  }
  if (sourceTotal != value.total ||
      value.byCityId.length != byCity.length ||
      value.byCityId.entries.any(
        (entry) =>
            entry.key.isEmpty ||
            entry.value < 0 ||
            byCity[entry.key] != entry.value,
      )) {
    throw const FormatException('Science breakdown is inconsistent.');
  }
}

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
    throw const FormatException('Research session identity is stale.');
  }
}

SessionStampView _stamp(AonwSessionStamp value) => SessionStampView(
  revision: value.revision,
  stateDigest: value.stateDigest,
  mapHash: value.mapHash,
  rulesetHash: value.rulesetHash,
);

const _rejections = <AonwCommandRejectionCode, ResearchRejectionCodeView>{
  AonwCommandRejectionCode.staleRevision:
      ResearchRejectionCodeView.staleRevision,
  AonwCommandRejectionCode.technologyPlayerNotControlled:
      ResearchRejectionCodeView.technologyPlayerNotControlled,
  AonwCommandRejectionCode.technologyNotAvailable:
      ResearchRejectionCodeView.technologyNotAvailable,
  AonwCommandRejectionCode.stateRevisionOverflow:
      ResearchRejectionCodeView.stateRevisionOverflow,
};
