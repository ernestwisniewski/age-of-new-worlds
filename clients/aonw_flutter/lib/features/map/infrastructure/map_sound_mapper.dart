import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../read_model/map_feedback_view.dart';
import '../read_model/map_view.dart';
import '../read_model/player_map_view.dart';
import 'map_feedback_positions.dart';

List<MapFeedbackCueView> deduplicateMapSounds(List<MapFeedbackCueView> cues) {
  final seen = <(int, MapSoundKindView)>{};
  final result = <MapFeedbackCueView>[];
  for (final cue in cues) {
    final sound = cue.sound;
    if (sound == null || seen.add((cue.identity.revision, sound))) {
      result.add(cue);
    } else if (cue is MapParticleCueView) {
      result.add(
        MapParticleCueView(
          identity: cue.identity,
          coordinate: cue.coordinate,
          kind: cue.kind,
          colorValue: cue.colorValue,
        ),
      );
    }
  }
  return result;
}

MapSoundCueView? mapEventSound(
  AonwClientEvent event,
  MapEventIdentityView identity,
  PlayerMapView previous,
  AonwPlayerViewSnapshot snapshot,
  MapFeedbackPositions positions,
) {
  final context = _SoundContext(previous, snapshot, positions);
  final (MapSoundKindView, MapHexCoordinate?) sound = switch (event) {
    AonwUnitMovedEvent(:final unitId, :final to)
        when context.ownsUnit(unitId) =>
      (MapSoundKindView.movement, (col: to.col, row: to.row)),
    AonwCombatResolvedEvent(:final attackerUnitId, :final target)
        when context.ownsCombat(attackerUnitId, target) =>
      (MapSoundKindView.combat, context.combatPosition(attackerUnitId, target)),
    _ => (MapSoundKindView.city, _citySound(event, context)),
  };
  if (sound.$2 == null) return null;
  return MapSoundCueView(
    identity: identity,
    coordinate: sound.$2!,
    sound: sound.$1,
  );
}

MapHexCoordinate? _citySound(AonwClientEvent event, _SoundContext context) =>
    switch (event) {
      AonwCityCapturedEvent(target: AonwCityCombatTarget(:final cityId))
          when context.participatesInCapture(cityId) =>
        context.cityPosition(cityId),
      AonwCityFoundedEvent(:final cityId, :final ownerPlayerId) ||
      AonwCityBuiltWonderEvent(:final cityId, :final ownerPlayerId)
          when ownerPlayerId == context.previous.actorPlayerId =>
        context.cityPosition(cityId),
      AonwCityBuiltBuildingEvent(:final cityId) ||
      AonwCityProducedUnitEvent(
        :final cityId,
      ) when context.ownsCity(cityId) => context.cityPosition(cityId),
      _ => null,
    };

final class _SoundContext {
  const _SoundContext(this.previous, this.snapshot, this.positions);
  final PlayerMapView previous;
  final AonwPlayerViewSnapshot snapshot;
  final MapFeedbackPositions positions;

  bool ownsUnit(String id) =>
      (snapshot.units
              .where((unit) => unit.id == id)
              .firstOrNull
              ?.ownerPlayerId ??
          previous.visibleUnitById(id)?.ownerPlayerId) ==
      previous.actorPlayerId;

  bool ownsCity(String id) => snapshot.cities.any(
    (city) => city.id == id && city.ownerPlayerId == previous.actorPlayerId,
  );

  bool participatesInCapture(String id) =>
      ownsCity(id) ||
      previous.cityById(id)?.ownerPlayerId == previous.actorPlayerId;

  bool ownsCombat(String attacker, AonwCombatTarget target) =>
      ownsUnit(attacker) ||
      switch (target) {
        AonwUnitCombatTarget(:final unitId) => ownsUnit(unitId),
        AonwCityCombatTarget(:final cityId) =>
          (snapshot.cities
                      .where((city) => city.id == cityId)
                      .firstOrNull
                      ?.ownerPlayerId ??
                  previous.cityById(cityId)?.ownerPlayerId) ==
              previous.actorPlayerId,
      };

  MapHexCoordinate? cityPosition(String id) {
    final previousCity = previous.cityById(id);
    if (previousCity != null) return previousCity.center;
    final city = snapshot.cities.where((city) => city.id == id).firstOrNull;
    return city == null ? null : (col: city.center.col, row: city.center.row);
  }

  MapHexCoordinate? targetPosition(AonwCombatTarget target) => switch (target) {
    AonwCityCombatTarget(:final cityId) => cityPosition(cityId),
    AonwUnitCombatTarget(:final unitId) => positions.coordinateOf(unitId),
  };

  MapHexCoordinate? combatPosition(String attacker, AonwCombatTarget target) =>
      targetPosition(target) ?? positions.coordinateOf(attacker);
}
