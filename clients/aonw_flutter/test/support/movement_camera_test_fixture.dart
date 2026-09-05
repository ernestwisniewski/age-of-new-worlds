import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_command_animation_view.dart';
import 'package:aonw_flutter/features/map/read_model/map_command_frame_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';

import 'map_test_fixture.dart';

MapRenderSnapshot movementCameraSnapshot({
  int revision = 0,
  int epoch = 0,
  bool foreign = false,
  String? selected,
  MapFogView? fog,
}) {
  final scene = testMapScene(
    cols: 12,
    rows: 8,
    units: [
      testVisibleUnit(id: 'anchor', coordinate: (col: 0, row: 0)),
      testVisibleUnit(
        id: 'moving',
        ownerPlayerId: foreign ? 'opponent' : 'preview-player',
        coordinate: revision == 0 ? (col: 6, row: 3) : (col: 8, row: 3),
      ),
    ],
    cities: [testCityView(center: (col: 8, row: 3))],
  );
  final source = scene.player;
  final player = PlayerMapView(
    actorPlayerId: source.actorPlayerId,
    stamp: testSessionStamp(
      revision: revision,
      stateDigest: (revision == 0 ? 'b' : 'c') * 64,
    ),
    turnMode: source.turnMode,
    participants: source.participants,
    fog: fog ?? source.fog,
    economy: source.economy,
    research: source.research,
    victory: source.victory,
    turnView: source.turnView,
    diplomacy: source.diplomacy,
    units: source.units,
    cities: source.cities,
  );
  return MapRenderSnapshot(
    map: scene.map,
    reference: scene.reference,
    player: player,
    effectEpoch: epoch,
    interaction: MapInteractionState(selectedUnitId: selected),
    commandFrame: revision == 0
        ? null
        : MapCommandFrameView(
            player: player,
            animations: [
              MapCommandMovementView(
                eventIndex: 0,
                unitId: 'moving',
                path: [(col: 6, row: 3), (col: 7, row: 3), (col: 8, row: 3)],
              ),
            ],
          ),
  );
}
