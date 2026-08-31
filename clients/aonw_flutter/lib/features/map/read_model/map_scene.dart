import 'map_reference_bundle.dart';
import 'map_view.dart';
import 'player_map_view.dart';

final class MapScene {
  const MapScene({
    required this.map,
    required this.reference,
    required this.player,
  });

  final MapView map;
  final MapReferenceBundle reference;
  final PlayerMapView player;

  MapScene withPlayer(PlayerMapView value) =>
      MapScene(map: map, reference: reference, player: value);
}
