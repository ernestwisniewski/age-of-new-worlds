import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../read_model/map_feedback_view.dart';
import '../read_model/map_view.dart';
import '../read_model/player_map_view.dart';

const maximumRecentMapFeedback = 64;

List<MapFeedbackCueView> mapCommandFeedback({
  required AonwCommandResult command,
  required AonwPlayerViewSnapshot snapshot,
  required PlayerMapView previous,
  required MapView map,
}) {
  if (!command.accepted || command.stamp.revision == previous.stamp.revision) {
    return previous.recentFeedback;
  }
  _validateFeedbackIdentity(command, snapshot, previous, map);
  final next = [...previous.recentFeedback];
  for (var index = 0; index < command.events.length; index++) {
    final cue = _particleCue(
      command.events[index],
      (revision: command.stamp.revision, eventIndex: index),
      snapshot,
      previous.actorPlayerId,
    );
    if (cue == null || !_visible(cue.coordinate, snapshot, map)) continue;
    next.add(cue);
  }
  return next.length <= maximumRecentMapFeedback
      ? next
      : next.sublist(next.length - maximumRecentMapFeedback);
}

MapParticleCueView? _particleCue(
  AonwClientEvent event,
  MapEventIdentityView identity,
  AonwPlayerViewSnapshot snapshot,
  String actor,
) {
  final (String owner, AonwCoordinate anchor, MapParticleKindView kind)? cue =
      switch (event) {
        AonwCityFoundedEvent(:final cityId, :final ownerPlayerId) => _cityCue(
          snapshot,
          cityId,
          MapParticleKindView.cityFounded,
          owner: ownerPlayerId,
        ),
        AonwCityProducedUnitEvent(:final cityId) => _cityCue(
          snapshot,
          cityId,
          MapParticleKindView.unitProduced,
        ),
        AonwCityClaimedHexEvent(:final cityId, :final coordinate) => _cityCue(
          snapshot,
          cityId,
          MapParticleKindView.hexClaimed,
          anchor: coordinate,
        ),
        AonwTechnologyResearchedEvent(:final playerId) when playerId == actor =>
          _researchCue(snapshot, playerId),
        _ => null,
      };
  if (cue == null) return null;
  final color = snapshot.participants
      .where((player) => player.id == cue.$1)
      .firstOrNull
      ?.colorValue;
  if (color == null) return null;
  return MapParticleCueView(
    identity: identity,
    coordinate: (col: cue.$2.col, row: cue.$2.row),
    kind: cue.$3,
    colorValue: color,
  );
}

(String, AonwCoordinate, MapParticleKindView)? _cityCue(
  AonwPlayerViewSnapshot snapshot,
  String id,
  MapParticleKindView kind, {
  String? owner,
  AonwCoordinate? anchor,
}) {
  final city = snapshot.cities.where((city) => city.id == id).firstOrNull;
  if (city == null || owner != null && owner != city.ownerPlayerId) return null;
  return (city.ownerPlayerId, anchor ?? city.center, kind);
}

(String, AonwCoordinate, MapParticleKindView)? _researchCue(
  AonwPlayerViewSnapshot snapshot,
  String owner,
) {
  final city = snapshot.cities
      .where((city) => city.ownerPlayerId == owner)
      .firstOrNull;
  final anchor =
      city?.center ??
      snapshot.units
          .where((unit) => unit.ownerPlayerId == owner)
          .firstOrNull
          ?.coordinate;
  return anchor == null
      ? null
      : (owner, anchor, MapParticleKindView.technologyResearched);
}

bool _visible(
  MapHexCoordinate coordinate,
  AonwPlayerViewSnapshot snapshot,
  MapView map,
) =>
    coordinate.col >= 0 &&
    coordinate.row >= 0 &&
    coordinate.col < map.cols &&
    coordinate.row < map.rows &&
    (!snapshot.fog.enabled ||
        snapshot.fog.visibleHexes.any(
          (hex) => hex.col == coordinate.col && hex.row == coordinate.row,
        ));

void _validateFeedbackIdentity(
  AonwCommandResult command,
  AonwPlayerViewSnapshot snapshot,
  PlayerMapView previous,
  MapView map,
) {
  if (command.stamp.revision != previous.stamp.revision + 1 ||
      command.stamp.revision != snapshot.stamp.revision ||
      command.stamp.stateDigest != snapshot.stamp.stateDigest ||
      command.stamp.mapHash != map.contentHash ||
      command.stamp.rulesetHash != previous.stamp.rulesetHash) {
    throw const FormatException(
      'Map feedback does not continue the recipient state.',
    );
  }
}
