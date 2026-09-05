import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_feedback_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';

import 'map_test_fixture.dart';

MapRenderSnapshot feedbackSnapshot({
  int revision = 0,
  String actor = 'preview-player',
  String? contentHash,
  MapFogView? fog,
  List<MapFeedbackCueView> cues = const [],
}) {
  final scene = testMapScene(contentHash: contentHash);
  final source = scene.player;
  return MapRenderSnapshot(
    map: scene.map,
    reference: scene.reference,
    interaction: const MapInteractionState(),
    player: PlayerMapView(
      actorPlayerId: actor,
      stamp: testSessionStamp(revision: revision),
      turnMode: source.turnMode,
      participants: source.participants,
      fog: fog ?? source.fog,
      economy: source.economy,
      research: source.research,
      victory: source.victory,
      turnView: source.turnView,
      diplomacy: source.diplomacy,
      units: source.units,
      recentFeedback: cues,
    ),
  );
}

MapParticleCueView particleCue({
  int revision = 1,
  int eventIndex = 0,
  MapParticleKindView kind = MapParticleKindView.cityFounded,
}) => MapParticleCueView(
  identity: (revision: revision, eventIndex: eventIndex),
  coordinate: (col: 1, row: 0),
  kind: kind,
  colorValue: 0xff68a7e8,
);
