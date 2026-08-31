import '../application/map_interaction_state.dart';
import '../read_model/map_reference_bundle.dart';
import '../read_model/map_view.dart';
import '../read_model/player_map_view.dart';

final class MapRenderSnapshot {
  const MapRenderSnapshot({
    required this.map,
    required this.interaction,
    required this.reference,
    required this.player,
  });

  final MapView map;
  final MapInteractionState interaction;
  final MapReferenceBundle reference;
  final PlayerMapView player;
}
