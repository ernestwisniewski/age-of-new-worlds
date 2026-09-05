import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_command_animation_view.dart';
import 'package:aonw_flutter/features/map/read_model/map_command_frame_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';

MapRenderSnapshot movementCameraPerformanceSnapshot(MapRenderSnapshot source) {
  final actor = source.player;
  final moving = actor.units.first;
  final player = PlayerMapView.preview(
    actorPlayerId: actor.actorPlayerId,
    stamp: SessionStampView(
      revision: actor.stamp.revision + 1,
      stateDigest: 'f' * 64,
      mapHash: actor.stamp.mapHash,
      rulesetHash: actor.stamp.rulesetHash,
    ),
    turn: 1,
    pendingAction: null,
    units: [
      VisibleUnitView(
        id: moving.id,
        ownerPlayerId: moving.ownerPlayerId,
        kind: moving.kind,
        name: moving.name,
        coordinate: (col: 39, row: 0),
        movementUnits: moving.movementUnits,
        posture: moving.posture,
      ),
      ...actor.units.skip(1),
    ],
    cities: actor.cities,
    fieldImprovements: actor.fieldImprovements,
    roads: actor.roads,
  );
  return MapRenderSnapshot(
    map: source.map,
    reference: source.reference,
    interaction: source.interaction,
    player: player,
    commandFrame: MapCommandFrameView(
      player: player,
      animations: [
        MapCommandMovementView(
          eventIndex: 0,
          unitId: moving.id,
          path: [for (var col = 0; col < 40; col++) (col: col, row: 0)],
        ),
      ],
    ),
  );
}
