import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/map/infrastructure/map_view_mapper.dart';
import 'package:aonw_flutter/features/map/presentation/geometry/odd_q_flat_top_geometry.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 3) {
    stderr.writeln(
      'usage: dart run test/tool/export_map_render_probe.dart '
      '<scenario.json> <probe.json> <diagnostics.json>',
    );
    exitCode = 64;
    return;
  }

  final scenario = _readObject(File(arguments[0]));
  final repositoryRoot = _repositoryRoot();
  final session = await createAonwEngineSession();
  if (session == null) {
    throw StateError('The engine map adapter is unavailable.');
  }

  final probes = <Map<String, Object?>>[];
  final diagnostics = <Map<String, Object?>>[];
  try {
    for (final mapScenario in _objects(scenario, 'maps')) {
      final beforeMemory = ProcessInfo.currentRss;
      final stopwatch = Stopwatch()..start();
      final map = await _loadMap(session, repositoryRoot, mapScenario);
      final probe = _buildMapProbe(map, scenario);
      stopwatch.stop();
      probes.add(probe);
      diagnostics.add({
        'mapId': map.mapId,
        'cols': map.cols,
        'rows': map.rows,
        'tiles': map.tiles.length,
        'elapsedMicros': stopwatch.elapsedMicroseconds,
        'residentMemoryDeltaBytes': _nonNegative(
          ProcessInfo.currentRss - beforeMemory,
        ),
        'serializedProbeBytes': utf8.encode(jsonEncode(probe)).length,
      });
    }
  } finally {
    await session.close();
  }

  _writeJson(File(arguments[1]), {'maps': probes});
  _writeJson(File(arguments[2]), {'maps': diagnostics});
  stdout.writeln('Flutter map render probe: OK');
}

Future<MapView> _loadMap(
  AonwEngineSession session,
  Directory repositoryRoot,
  Map<String, dynamic> scenario,
) async {
  final document = File(
    '${repositoryRoot.path}/${scenario['document']! as String}',
  ).readAsStringSync();
  final response = await session.send(
    AonwClientRequest.inspectMap(mapDocument: document),
  );
  if (!response.isSuccess) {
    final error = response.error!;
    throw StateError('${error.code}: ${error.message}');
  }
  final map = const MapViewMapper().fromWire(
    response.require<AonwMapInspectedResponse>().map,
  );
  final expectedMapId = scenario['mapId']! as String;
  if (map.mapId != expectedMapId) {
    throw StateError('Expected mapId $expectedMapId, received ${map.mapId}.');
  }
  return map;
}

Map<String, Object?> _buildMapProbe(
  MapView map,
  Map<String, dynamic> scenario,
) {
  final geometry = AonwOddQFlatTopGeometry(cols: map.cols, rows: map.rows);
  return {
    'mapId': map.mapId,
    'contentHash': map.contentHash,
    'gridLayout': map.gridLayout.name,
    'cols': map.cols,
    'rows': map.rows,
    'defaultZoom': map.defaultZoom,
    'bounds': _bounds(geometry.bounds),
    'tiles': [for (final tile in map.tiles) _tileProbe(tile, geometry)],
    'objectives': [
      for (final objective in map.objectives) _objective(objective),
    ],
    'cases': [
      for (final probeCase in _objects(scenario, 'cases'))
        _caseProbe(map, geometry, probeCase, _objects(scenario, 'viewports')),
    ],
  };
}

Map<String, Object?> _tileProbe(
  MapTileView tile,
  AonwOddQFlatTopGeometry geometry,
) {
  final coordinate = tile.coordinate;
  final center = geometry.center(coordinate);
  final picked = geometry.hexAt(center);
  return {
    'coordinate': _hex(coordinate),
    'displayTerrain': tile.displayTerrain.name,
    'yieldTerrain': tile.yieldTerrain.name,
    'movementTerrains': [
      for (final terrain in tile.movementTerrains) terrain.name,
    ],
    'terrainTags': [for (final terrain in tile.terrainTags) terrain.name],
    'resources': [for (final resource in tile.resources) resource.name],
    'height': tile.height,
    'center': _point(geometry.normalizedUv(center)),
    'corners': [
      for (var corner = 0; corner < 6; corner++)
        _point(geometry.normalizedUv(geometry.corner(coordinate, corner))),
    ],
    'neighbors': [
      for (final neighbor in geometry.neighbors(coordinate)) _hex(neighbor),
    ],
    'centerRoundTrip': _hex(picked),
  };
}

Map<String, Object?> _objective(MapObjectiveView objective) => {
  'id': objective.id,
  'type': objective.type.name,
  'coordinate': _hex(objective.coordinate),
  'requiredHoldTurns': objective.requiredHoldTurns,
  'victoryPoints': objective.victoryPoints,
  'goldPerTurn': objective.goldPerTurn,
};

Map<String, Object?> _caseProbe(
  MapView map,
  AonwOddQFlatTopGeometry geometry,
  Map<String, dynamic> probeCase,
  List<Map<String, dynamic>> viewports,
) {
  final point = _casePoint(geometry, probeCase);
  final normalized = geometry.normalizedUv(point);
  return {
    'name': probeCase['name']! as String,
    'kind': probeCase['kind']! as String,
    'normalizedPoint': _point(normalized),
    'selectedHex': _selectedHex(map, geometry, point),
    'viewports': [
      for (final viewport in viewports)
        _viewportProbe(map, geometry, normalized, viewport),
    ],
  };
}

Map<String, Object?> _viewportProbe(
  MapView map,
  AonwOddQFlatTopGeometry geometry,
  AonwPoint normalized,
  Map<String, dynamic> viewport,
) {
  final width = viewport['width']! as int;
  final height = viewport['height']! as int;
  final screen = (x: normalized.x * width, y: normalized.y * height);
  final roundTripNormalized = (x: screen.x / width, y: screen.y / height);
  final bounds = geometry.bounds;
  final roundTripWorld = (
    x: bounds.x + roundTripNormalized.x * bounds.width,
    y: bounds.y + roundTripNormalized.y * bounds.height,
  );
  return {
    'name': viewport['name']! as String,
    'width': width,
    'height': height,
    'screenPoint': _point(screen),
    'selectedHex': _selectedHex(map, geometry, roundTripWorld),
  };
}

AonwPoint _casePoint(
  AonwOddQFlatTopGeometry geometry,
  Map<String, dynamic> probeCase,
) {
  switch (probeCase['kind']) {
    case 'center':
      return geometry.center(_coordinate(probeCase['hex']));
    case 'edge':
      final coordinate = _coordinate(probeCase['hex']);
      final corners = _numbers(probeCase['corners']);
      return _midpoint(
        geometry.corner(coordinate, corners[0].toInt()),
        geometry.corner(coordinate, corners[1].toInt()),
      );
    case 'corner':
      return geometry.corner(
        _coordinate(probeCase['hex']),
        probeCase['corner']! as int,
      );
    case 'normalized':
      final normalized = _pointValue(probeCase['point']);
      final bounds = geometry.bounds;
      return (
        x: bounds.x + normalized.x * bounds.width,
        y: bounds.y + normalized.y * bounds.height,
      );
    case 'centerMidpoint':
      final hexes = probeCase['hexes']! as List<dynamic>;
      return _midpoint(
        geometry.center(_coordinate(hexes[0])),
        geometry.center(_coordinate(hexes[1])),
      );
    default:
      throw FormatException('Unknown probe case kind: ${probeCase['kind']}');
  }
}

List<int>? _selectedHex(
  MapView map,
  AonwOddQFlatTopGeometry geometry,
  AonwPoint point,
) {
  final coordinate = geometry.hexAt(point);
  return map.contains(coordinate) ? _hex(coordinate) : null;
}

AonwPoint _midpoint(AonwPoint left, AonwPoint right) =>
    (x: (left.x + right.x) * 0.5, y: (left.y + right.y) * 0.5);

List<int> _hex(MapHexCoordinate coordinate) => [coordinate.col, coordinate.row];

List<double> _point(AonwPoint point) => [point.x, point.y];

List<double> _bounds(AonwBounds bounds) => [
  bounds.x,
  bounds.y,
  bounds.width,
  bounds.height,
];

MapHexCoordinate _coordinate(Object? value) {
  final numbers = _numbers(value);
  return (col: numbers[0].toInt(), row: numbers[1].toInt());
}

AonwPoint _pointValue(Object? value) {
  final numbers = _numbers(value);
  return (x: numbers[0], y: numbers[1]);
}

List<double> _numbers(Object? value) => (value! as List<dynamic>)
    .map((number) => (number as num).toDouble())
    .toList();

List<Map<String, dynamic>> _objects(
  Map<String, dynamic> source,
  String field,
) => (source[field]! as List<dynamic>).cast<Map<String, dynamic>>();

Map<String, dynamic> _readObject(File file) =>
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

void _writeJson(File file, Map<String, Object?> value) {
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(value)}\n',
  );
}

Directory _repositoryRoot() {
  var candidate = Directory.current.absolute;
  while (candidate.parent.path != candidate.path) {
    if (File('${candidate.path}/Makefile').existsSync() &&
        Directory('${candidate.path}/tests').existsSync()) {
      return candidate;
    }
    candidate = candidate.parent;
  }
  throw StateError('Cannot locate the repository root.');
}

int _nonNegative(int value) => value < 0 ? 0 : value;
