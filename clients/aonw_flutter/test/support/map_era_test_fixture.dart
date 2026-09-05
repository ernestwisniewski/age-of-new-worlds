import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';

import 'map_test_fixture.dart';

MapRenderSnapshot eraSnapshot(
  PlayerTechnologyEraView era, {
  String actor = 'preview-player',
  String? contentHash,
  int revision = 0,
}) {
  final scene = testMapScene(cols: 3, rows: 3, contentHash: contentHash);
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
      fog: source.fog,
      economy: source.economy,
      research: PlayerResearchSummaryView(
        dominantEra: era,
        activeTechnologyId: 'strategy',
        activeProgress: revision,
        activeEffectiveCost: 100,
        scienceOverflow: 0,
        sciencePerTurn: 0,
        scienceByCityId: const {},
        scienceSources: const [],
      ),
      victory: source.victory,
      turnView: source.turnView,
      diplomacy: source.diplomacy,
      units: source.units,
    ),
  );
}
