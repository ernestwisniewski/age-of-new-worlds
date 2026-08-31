import 'package:aonw_rust_client/aonw_rust_client.dart';

import '../read_model/map_view.dart';
import '../read_model/player_map_view.dart';
import 'recipient_projection_cache.dart';

typedef RustGameSessionContext = ({
  AonwRustSession session,
  MapView map,
  PlayerMapView player,
  RecipientProjectionCache cache,
  String actorPlayerId,
});

VisibleUnitView requireControlledUnit(
  RustGameSessionContext context,
  String unitId,
) {
  // Ownership is visible in the recipient projection. Rust still decides whether
  // the requested action is legal and returns its stable rejection code.
  for (final unit in context.player.units) {
    if (unit.id == unitId && unit.ownerPlayerId == context.actorPlayerId) {
      return unit;
    }
  }
  throw const FormatException(
    'Session request references an uncontrolled or absent unit.',
  );
}
