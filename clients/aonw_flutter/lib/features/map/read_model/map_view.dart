typedef MapHexCoordinate = ({int col, int row});

enum MapGridLayout { oddQFlatTop }

enum MapTerrain {
  ocean,
  coast,
  lake,
  plains,
  grassland,
  desert,
  tundra,
  snow,
  mountain,
  hills,
  wetlands,
  jungle,
  forest,
  river,
}

enum MapResource {
  wheat,
  fish,
  deer,
  sheep,
  rice,
  cow,
  apple,
  banana,
  citrus,
  gold,
  silver,
  gems,
  silk,
  spices,
  cotton,
  grapes,
  ivory,
  pearls,
  coffee,
  cocoa,
  tobacco,
  sugar,
  iron,
  coal,
  oil,
  aluminium,
  uranium,
  horses,
  marble,
}

enum MapObjectiveType { ruins, strategicPass, holySite, legendaryResource }

final class MapTileView {
  MapTileView({
    required this.coordinate,
    required this.displayTerrain,
    required this.yieldTerrain,
    required List<MapTerrain> movementTerrains,
    required List<MapTerrain> terrainTags,
    required List<MapResource> resources,
    required this.height,
  }) : movementTerrains = List.unmodifiable(movementTerrains),
       terrainTags = List.unmodifiable(terrainTags),
       resources = List.unmodifiable(resources);

  final MapHexCoordinate coordinate;
  final MapTerrain displayTerrain;
  final MapTerrain yieldTerrain;
  final List<MapTerrain> movementTerrains;
  final List<MapTerrain> terrainTags;
  final List<MapResource> resources;
  final int height;
}

final class MapObjectiveView {
  const MapObjectiveView({
    required this.id,
    required this.type,
    required this.coordinate,
    required this.requiredHoldTurns,
    required this.victoryPoints,
    required this.goldPerTurn,
  });

  final String id;
  final MapObjectiveType type;
  final MapHexCoordinate coordinate;
  final int requiredHoldTurns;
  final int victoryPoints;
  final int goldPerTurn;
}

final class MapView {
  MapView({
    required this.mapId,
    required this.contentHash,
    required this.gridLayout,
    required this.cols,
    required this.rows,
    required this.defaultZoom,
    required List<MapTileView> tiles,
    required List<MapObjectiveView> objectives,
  }) : tiles = List.unmodifiable(tiles),
       objectives = List.unmodifiable(objectives) {
    _validateHeader();
    _tilesByCoordinate = Map.unmodifiable(_indexTiles());
    _validateObjectives();
  }

  final String mapId;
  final String contentHash;
  final MapGridLayout gridLayout;
  final int cols;
  final int rows;
  final double defaultZoom;
  final List<MapTileView> tiles;
  final List<MapObjectiveView> objectives;
  late final Map<MapHexCoordinate, MapTileView> _tilesByCoordinate;

  MapTileView? tileAt(MapHexCoordinate coordinate) =>
      _tilesByCoordinate[coordinate];

  bool contains(MapHexCoordinate coordinate) =>
      _tilesByCoordinate.containsKey(coordinate);

  bool isWithinBounds(MapHexCoordinate coordinate) =>
      coordinate.col >= 0 &&
      coordinate.col < cols &&
      coordinate.row >= 0 &&
      coordinate.row < rows;

  Map<MapHexCoordinate, MapTileView> _indexTiles() {
    final indexedTiles = <MapHexCoordinate, MapTileView>{};
    for (final tile in tiles) {
      if (!isWithinBounds(tile.coordinate)) {
        throw FormatException(
          'Map tile is outside bounds: ${tile.coordinate}.',
        );
      }
      if (tile.height < 0 || tile.height > 5) {
        throw FormatException(
          'Map tile height is outside the supported range: ${tile.height}.',
        );
      }
      if (indexedTiles.containsKey(tile.coordinate)) {
        throw FormatException('Duplicate map tile: ${tile.coordinate}.');
      }
      indexedTiles[tile.coordinate] = tile;
    }
    if (indexedTiles.length != cols * rows) {
      throw FormatException(
        'Map tile coverage is incomplete: ${indexedTiles.length} of ${cols * rows}.',
      );
    }
    return indexedTiles;
  }

  void _validateObjectives() {
    final objectiveIds = <String>{};
    for (final objective in objectives) {
      if (objective.id.isEmpty || !objectiveIds.add(objective.id)) {
        throw FormatException('Map objective id is empty or duplicated.');
      }
      if (!isWithinBounds(objective.coordinate)) {
        throw FormatException(
          'Map objective is outside bounds: ${objective.coordinate}.',
        );
      }
      if (objective.requiredHoldTurns < 0 ||
          objective.victoryPoints < 0 ||
          objective.goldPerTurn < 0) {
        throw FormatException('Map objective values cannot be negative.');
      }
    }
  }

  void _validateHeader() {
    if (mapId.isEmpty) throw const FormatException('Map id is empty.');
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(contentHash)) {
      throw const FormatException('Map content hash is not a SHA-256 digest.');
    }
    if (cols <= 0 || rows <= 0) {
      throw const FormatException('Map dimensions must be positive.');
    }
    if (!defaultZoom.isFinite || defaultZoom <= 0) {
      throw const FormatException(
        'Map default zoom must be finite and positive.',
      );
    }
  }
}
