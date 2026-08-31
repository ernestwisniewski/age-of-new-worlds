import 'package:aonw_rust_client/src/protocol_coordinate.dart';
import 'package:aonw_rust_client/src/protocol_json.dart';

enum AonwMapGridLayout {
  oddQFlatTop;

  factory AonwMapGridLayout.fromJson(Object? value) =>
      _enumValue(values, value, 'map grid layout');
}

enum AonwMapTerrain {
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
  river;

  factory AonwMapTerrain.fromJson(Object? value) =>
      _enumValue(values, value, 'map terrain');
}

enum AonwMapResource {
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
  marble;

  factory AonwMapResource.fromJson(Object? value) =>
      _enumValue(values, value, 'map resource');
}

enum AonwMapObjectiveType {
  ruins,
  strategicPass,
  holySite,
  legendaryResource;

  factory AonwMapObjectiveType.fromJson(Object? value) =>
      _enumValue(values, value, 'map objective type');
}

final class AonwMapView {
  const AonwMapView({
    required this.mapId,
    required this.contentHash,
    required this.gridLayout,
    required this.cols,
    required this.rows,
    required this.defaultZoom,
    required this.tiles,
    required this.objectives,
  });

  factory AonwMapView.fromJson(Object? source) {
    final value = readObject(source, 'map view');
    requireKeys(value, const {
      'mapId',
      'contentHash',
      'gridLayout',
      'cols',
      'rows',
      'defaultZoom',
      'tiles',
      'objectives',
    }, 'map view');
    return AonwMapView(
      mapId: readString(value['mapId'], 'map id'),
      contentHash: readString(value['contentHash'], 'map content hash'),
      gridLayout: AonwMapGridLayout.fromJson(value['gridLayout']),
      cols: readUnsigned(value['cols'], 'map columns'),
      rows: readUnsigned(value['rows'], 'map rows'),
      defaultZoom: readFinitePositiveDouble(
        value['defaultZoom'],
        'map default zoom',
      ),
      tiles: readList(
        value['tiles'],
        'map tiles',
        (item, _) => AonwMapTileView.fromJson(item),
      ),
      objectives: readList(
        value['objectives'],
        'map objectives',
        (item, _) => AonwMapObjectiveView.fromJson(item),
      ),
    );
  }

  final String mapId;
  final String contentHash;
  final AonwMapGridLayout gridLayout;
  final int cols;
  final int rows;
  final double defaultZoom;
  final List<AonwMapTileView> tiles;
  final List<AonwMapObjectiveView> objectives;
}

final class AonwMapTileView {
  const AonwMapTileView({
    required this.coordinate,
    required this.displayTerrain,
    required this.yieldTerrain,
    required this.movementTerrains,
    required this.terrainTags,
    required this.resources,
    required this.height,
  });

  factory AonwMapTileView.fromJson(Object? source) {
    final value = readObject(source, 'map tile view');
    requireKeys(value, const {
      'coordinate',
      'displayTerrain',
      'yieldTerrain',
      'movementTerrains',
      'terrainTags',
      'resources',
      'height',
    }, 'map tile view');
    return AonwMapTileView(
      coordinate: AonwCoordinate.fromJson(value['coordinate']),
      displayTerrain: AonwMapTerrain.fromJson(value['displayTerrain']),
      yieldTerrain: AonwMapTerrain.fromJson(value['yieldTerrain']),
      movementTerrains: readList(
        value['movementTerrains'],
        'movement terrains',
        (item, _) => AonwMapTerrain.fromJson(item),
      ),
      terrainTags: readList(
        value['terrainTags'],
        'terrain tags',
        (item, _) => AonwMapTerrain.fromJson(item),
      ),
      resources: readList(
        value['resources'],
        'map resources',
        (item, _) => AonwMapResource.fromJson(item),
      ),
      height: readUnsigned(value['height'], 'map tile height'),
    );
  }

  final AonwCoordinate coordinate;
  final AonwMapTerrain displayTerrain;
  final AonwMapTerrain yieldTerrain;
  final List<AonwMapTerrain> movementTerrains;
  final List<AonwMapTerrain> terrainTags;
  final List<AonwMapResource> resources;
  final int height;
}

final class AonwMapObjectiveView {
  const AonwMapObjectiveView({
    required this.id,
    required this.type,
    required this.coordinate,
    required this.requiredHoldTurns,
    required this.victoryPoints,
    required this.goldPerTurn,
  });

  factory AonwMapObjectiveView.fromJson(Object? source) {
    final value = readObject(source, 'map objective view');
    requireKeys(value, const {
      'id',
      'type',
      'coordinate',
      'requiredHoldTurns',
      'victoryPoints',
      'goldPerTurn',
    }, 'map objective view');
    return AonwMapObjectiveView(
      id: readString(value['id'], 'map objective id'),
      type: AonwMapObjectiveType.fromJson(value['type']),
      coordinate: AonwCoordinate.fromJson(value['coordinate']),
      requiredHoldTurns: readUnsigned(
        value['requiredHoldTurns'],
        'objective hold turns',
      ),
      victoryPoints: readUnsigned(
        value['victoryPoints'],
        'objective victory points',
      ),
      goldPerTurn: readUnsigned(
        value['goldPerTurn'],
        'objective gold per turn',
      ),
    );
  }

  final String id;
  final AonwMapObjectiveType type;
  final AonwCoordinate coordinate;
  final int requiredHoldTurns;
  final int victoryPoints;
  final int goldPerTurn;
}

T _enumValue<T extends Enum>(List<T> values, Object? value, String label) {
  final wire = readString(value, label);
  return values.firstWhere(
    (candidate) => candidate.name == wire,
    orElse: () => throw FormatException('Unknown AoNW $label $wire.'),
  );
}
