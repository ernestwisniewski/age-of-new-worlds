import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('requires unique and complete in-bounds tile coverage', () {
    final tiles = _tiles(2, 2);

    expect(() => _map(tiles: tiles.take(3).toList()), throwsFormatException);
    expect(
      () => _map(tiles: [...tiles.take(3), tiles.first]),
      throwsFormatException,
    );
    expect(
      () => _map(tiles: [...tiles.take(3), _tile((col: 2, row: 1))]),
      throwsFormatException,
    );
  });

  test('validates hashes, heights and objective bounds', () {
    expect(
      () => _map(contentHash: 'not-a-hash', tiles: _tiles(2, 2)),
      throwsFormatException,
    );
    expect(
      () => _map(
        tiles: [_tile((col: 0, row: 0), height: 6), ..._tiles(2, 2).skip(1)],
      ),
      throwsFormatException,
    );
    expect(
      () => _map(
        tiles: _tiles(2, 2),
        objectives: [
          const MapObjectiveView(
            id: 'outside',
            type: MapObjectiveType.ruins,
            coordinate: (col: 2, row: 0),
            requiredHoldTurns: 1,
            victoryPoints: 1,
            goldPerTurn: 0,
          ),
        ],
      ),
      throwsFormatException,
    );
  });

  test('contains checks actual validated tile presence', () {
    final map = _map(tiles: _tiles(2, 2));

    expect(map.contains((col: 1, row: 1)), isTrue);
    expect(map.contains((col: 2, row: 1)), isFalse);
    expect(map.isWithinBounds((col: -1, row: 0)), isFalse);
  });
}

MapView _map({
  String contentHash =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  required List<MapTileView> tiles,
  List<MapObjectiveView> objectives = const [],
}) => MapView(
  mapId: 'map',
  contentHash: contentHash,
  gridLayout: MapGridLayout.oddQFlatTop,
  cols: 2,
  rows: 2,
  defaultZoom: 1,
  tiles: tiles,
  objectives: objectives,
);

List<MapTileView> _tiles(int cols, int rows) => [
  for (var row = 0; row < rows; row++)
    for (var col = 0; col < cols; col++) _tile((col: col, row: row)),
];

MapTileView _tile(MapHexCoordinate coordinate, {int height = 0}) => MapTileView(
  coordinate: coordinate,
  displayTerrain: MapTerrain.plains,
  yieldTerrain: MapTerrain.plains,
  movementTerrains: const [MapTerrain.plains],
  terrainTags: const [MapTerrain.plains],
  resources: const [],
  height: height,
);
