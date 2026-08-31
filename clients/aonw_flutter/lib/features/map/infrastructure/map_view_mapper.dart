import 'package:aonw_rust_client/aonw_rust_client.dart';

import '../read_model/map_view.dart';

final class MapViewMapper {
  const MapViewMapper();

  MapView fromWire(AonwMapView wire) => MapView(
    mapId: wire.mapId,
    contentHash: wire.contentHash,
    gridLayout: MapGridLayout.values.byName(wire.gridLayout.name),
    cols: wire.cols,
    rows: wire.rows,
    defaultZoom: wire.defaultZoom,
    tiles: [for (final tile in wire.tiles) _tile(tile)],
    objectives: [
      for (final objective in wire.objectives) _objective(objective),
    ],
  );

  MapTileView _tile(AonwMapTileView wire) => MapTileView(
    coordinate: (col: wire.coordinate.col, row: wire.coordinate.row),
    displayTerrain: MapTerrain.values.byName(wire.displayTerrain.name),
    yieldTerrain: MapTerrain.values.byName(wire.yieldTerrain.name),
    movementTerrains: [
      for (final terrain in wire.movementTerrains)
        MapTerrain.values.byName(terrain.name),
    ],
    terrainTags: [
      for (final terrain in wire.terrainTags)
        MapTerrain.values.byName(terrain.name),
    ],
    resources: [
      for (final resource in wire.resources)
        MapResource.values.byName(resource.name),
    ],
    height: wire.height,
  );

  MapObjectiveView _objective(AonwMapObjectiveView wire) => MapObjectiveView(
    id: wire.id,
    type: MapObjectiveType.values.byName(wire.type.name),
    coordinate: (col: wire.coordinate.col, row: wire.coordinate.row),
    requiredHoldTurns: wire.requiredHoldTurns,
    victoryPoints: wire.victoryPoints,
    goldPerTurn: wire.goldPerTurn,
  );
}
