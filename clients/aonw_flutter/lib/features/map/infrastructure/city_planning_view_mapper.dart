import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../read_model/city_planning_view.dart';
import '../read_model/map_view.dart';
import '../read_model/player_map_view.dart';

final class CityPlanningViewMapper {
  const CityPlanningViewMapper();

  CityPlanningView fromWire(
    AonwCityPlanningResult wire, {
    required MapView map,
    required PlayerMapView player,
    required int expectedRevision,
  }) {
    final stamp = wire.stamp;
    final current = player.stamp;
    if (expectedRevision != current.revision ||
        stamp.revision != expectedRevision ||
        (stamp.stateDigest, stamp.mapHash, stamp.rulesetHash) !=
            (current.stateDigest, current.mapHash, current.rulesetHash) ||
        stamp.mapHash != map.contentHash) {
      throw const FormatException('City planning state identity is stale.');
    }
    final sites = _coordinates(wire.citySites, map, player);
    final growth = _coordinates(wire.growthTiles, map, player);
    if (!growth.containsAll(sites)) {
      throw const FormatException(
        'City sites must belong to the disclosed growth terrain.',
      );
    }
    return CityPlanningView(
      stamp: current,
      actorPlayerId: player.actorPlayerId,
      citySites: sites,
      growthTiles: growth,
    );
  }
}

Set<MapHexCoordinate> _coordinates(
  List<AonwCoordinate> source,
  MapView map,
  PlayerMapView player,
) {
  if (source.length > map.tiles.length) {
    throw const FormatException('Too many planning coordinates.');
  }
  final result = <MapHexCoordinate>{};
  MapHexCoordinate? previous;
  for (final value in source) {
    final hex = (col: value.col, row: value.row);
    if (map.tileAt(hex) == null ||
        player.fog.visibilityAt(hex) == MapFogVisibilityView.hidden ||
        (previous != null &&
            (hex.col < previous.col ||
                (hex.col == previous.col && hex.row <= previous.row)))) {
      throw const FormatException(
        'Planning coordinates must be disclosed, ordered, and unique.',
      );
    }
    result.add(hex);
    previous = hex;
  }
  return result;
}
