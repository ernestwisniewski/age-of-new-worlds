import 'package:aonw_flutter/features/cities/read_model/city_view.dart';
import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';

import 'map_test_fixture.dart';

MapRenderSnapshot productionSnapshot({
  List<CityView>? cities,
  MapFogView? fog,
  int revision = 0,
  String actor = 'preview-player',
  String? contentHash,
  PendingActionView? pendingAction,
  MapInteractionState interaction = const MapInteractionState(),
}) {
  final scene = testMapScene(
    cols: 10,
    rows: 8,
    contentHash: contentHash,
    actorColorValue: 0xff68a7e8,
    pendingAction: pendingAction,
  );
  final source = scene.player;
  return MapRenderSnapshot(
    map: scene.map,
    reference: scene.reference,
    interaction: interaction,
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
      units: const [],
      cities: cities ?? [producingCity('city')],
    ),
  );
}

CityView producingCity(
  String id, {
  String owner = 'preview-player',
  MapHexCoordinate center = (col: 1, row: 1),
  bool producing = true,
}) => CityView(
  id: id,
  ownerPlayerId: owner,
  name: id,
  center: center,
  visibleControlledHexes: [center],
  hitPoints: 10,
  ownedDetails: OwnedCityDetailsView(
    population: 1,
    storedFood: 0,
    maxHexes: 7,
    territoryRadius: 1,
    workedHexes: const [],
    preferredExpansionHex: null,
    productionQueue: producing
        ? CityProductionQueueView(
            targetKind: 'unit',
            target: 'worker',
            investedProduction: 0,
            resourceAllocation: const {},
          )
        : null,
  ),
);
