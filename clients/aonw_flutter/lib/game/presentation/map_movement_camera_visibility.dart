import '../../features/map/presentation/map_render_snapshot.dart';
import '../../features/map/read_model/player_map_view.dart';
import 'flame_command_transition.dart';

bool canFocusMapMovement(
  MapRenderSnapshot snapshot,
  FlameUnitMovementTransition movement,
) {
  final unit = snapshot.player.visibleUnitById(movement.unitId);
  if (unit == null) return false;
  if (unit.ownerPlayerId != snapshot.player.actorPlayerId &&
      snapshot.player.fog.visibilityAt(unit.coordinate) !=
          MapFogVisibilityView.visible) {
    return false;
  }
  final path = movement.path.isEmpty
      ? [movement.from, movement.to]
      : movement.path;
  // The accepted command already disclosed its executed path. Earlier points
  // can be remembered while the moving unit remains visible to the recipient.
  return path.every(snapshot.map.contains);
}
