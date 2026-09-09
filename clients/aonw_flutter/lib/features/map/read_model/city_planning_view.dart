import 'map_view.dart';
import 'player_map_view.dart';

/// Optional planning markings derived from the recipient's disclosed state.
final class CityPlanningView {
  CityPlanningView({
    required this.stamp,
    required this.actorPlayerId,
    required Iterable<MapHexCoordinate> citySites,
    required Iterable<MapHexCoordinate> growthTiles,
  }) : citySites = Set.unmodifiable(citySites),
       growthTiles = Set.unmodifiable(growthTiles);

  final SessionStampView stamp;
  final String actorPlayerId;
  final Set<MapHexCoordinate> citySites;
  final Set<MapHexCoordinate> growthTiles;
}
