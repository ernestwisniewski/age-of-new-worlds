import 'package:aonw_flutter/features/cities/read_model/city_view.dart';
import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/geometry/odd_q_flat_top_geometry.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_reference_bundle.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/map_view_mode.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/workers/read_model/worker_view.dart';

MapRenderSnapshot largeGameplaySnapshot() {
  const cols = 40;
  const rows = 30;
  const contentHash =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  final terrains = MapTerrain.values;
  final tiles = <MapTileView>[
    for (var row = 0; row < rows; row++)
      for (var col = 0; col < cols; col++)
        MapTileView(
          coordinate: (col: col, row: row),
          displayTerrain: terrains[(row * cols + col) % terrains.length],
          yieldTerrain: terrains[(row * cols + col) % terrains.length],
          movementTerrains: [terrains[(row * cols + col) % terrains.length]],
          terrainTags: [terrains[(row * cols + col) % terrains.length]],
          resources: const [],
          height: 0,
        ),
  ];
  final units = <VisibleUnitView>[
    for (var index = 0; index < 120; index++)
      VisibleUnitView(
        id: 'performance-unit-$index',
        ownerPlayerId: index.isEven ? 'performance-player' : 'foreign-player',
        kind: VisibleUnitKind.commander,
        name: 'Performance unit $index',
        coordinate: (col: index % cols, row: index ~/ cols),
        movementUnits: 12,
        posture: VisibleUnitPosture.active,
      ),
  ];
  final cities = <CityView>[
    for (var index = 0; index < 40; index++)
      CityView(
        id: 'performance-city-$index',
        ownerPlayerId: index.isEven ? 'performance-player' : 'foreign-player',
        name: 'Performance city $index',
        center: (col: index % cols, row: 5 + index ~/ cols),
        visibleControlledHexes: [(col: index % cols, row: 5 + index ~/ cols)],
        hitPoints: 10,
        ownedDetails: null,
      ),
  ];
  final fieldImprovements = <FieldImprovementView>[
    for (var index = 0; index < 120; index++)
      FieldImprovementView(
        coordinate: (col: index % cols, row: 10 + index ~/ cols),
        improvement: FieldImprovementKind
            .values[index % FieldImprovementKind.values.length],
      ),
  ];
  final roads = <RoadView>[
    for (var index = 0; index < 120; index++)
      RoadView(
        coordinate: (col: index % cols, row: 16 + index ~/ cols),
        condition: index.isEven
            ? TransportConditionView.operational
            : TransportConditionView.pillaged,
      ),
  ];
  const geometry = AonwOddQFlatTopGeometry(
    cols: cols,
    rows: rows,
    radius: aonwMapHexRadius,
  );
  final bounds = geometry.bounds;
  final map = MapView(
    mapId: 'flame-performance-40x30',
    contentHash: contentHash,
    gridLayout: MapGridLayout.oddQFlatTop,
    cols: cols,
    rows: rows,
    defaultZoom: 1,
    tiles: tiles,
    objectives: const [],
  );
  return MapRenderSnapshot(
    map: map,
    interaction: const MapInteractionState(viewMode: MapViewMode.tile),
    reference: MapReferenceBundle(
      mapId: map.mapId,
      mapContentHash: contentHash,
      worldWidth: bounds.width,
      worldHeight: bounds.height,
      pages: const [],
    ),
    player: PlayerMapView.preview(
      actorPlayerId: 'performance-player',
      stamp: const SessionStampView(
        revision: 0,
        stateDigest:
            'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        mapHash: contentHash,
        rulesetHash:
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
      ),
      turn: 1,
      pendingAction: null,
      units: units,
      cities: cities,
      fieldImprovements: fieldImprovements,
      roads: roads,
    ),
  );
}
