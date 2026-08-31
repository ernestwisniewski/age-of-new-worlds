import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

import 'map_asset_bundle_compiler.dart';
import 'map_asset_bundle_manifest.dart';
import 'map_atlas_builder.dart';

const _fixturePath = 'content/maps/aonw2_starter/reference_tiles.json';
const _mapPath = 'content/maps/aonw2_starter/map.json';
const _committedOutputs = [
  'clients/aonw_flutter/assets/maps/aonw2_starter',
  'clients/aonw_godot/assets/maps/aonw2_starter',
];

Future<void> main(List<String> arguments) async {
  try {
    final command = arguments.isEmpty ? 'check' : arguments.first;
    if (arguments.length > 1 || !const {'compile', 'check'}.contains(command)) {
      throw const FormatException(
        'Usage: dart --packages=.dart_tool/package_config.json '
        '../../tool/assets/compile/starter_map_bundle.dart '
        '<compile|check>',
      );
    }
    final workspace = _repositoryRoot();
    if (command == 'compile') {
      for (final path in _committedOutputs) {
        await compileStarterMapBundle(
          workspace: workspace,
          output: Directory('${workspace.path}/$path'),
        );
      }
      return;
    }
    await _check(workspace);
  } on FormatException catch (error) {
    stderr.writeln('Starter map bundle contract error: ${error.message}');
    exitCode = 1;
  } on StateError catch (error) {
    stderr.writeln('Starter map bundle failed: ${error.message}');
    exitCode = 1;
  }
}

Directory _repositoryRoot() =>
    File.fromUri(Platform.script).parent.parent.parent.parent.absolute;

Future<MapAssetBundleManifest> compileStarterMapBundle({
  required Directory workspace,
  required Directory output,
}) async {
  final fixture = await _StarterReferenceFixture.fromFile(
    File('${workspace.path}/$_fixturePath'),
  );
  final mapDocument = File('${workspace.path}/$_mapPath');
  await fixture.verifyMapDocument(mapDocument);
  return MapAssetBundleCompiler(
    spec: MapAssetBundleSpec(
      mapId: fixture.mapId,
      mapContentHash: fixture.mapContentHash,
      cols: fixture.cols,
      rows: fixture.rows,
    ),
    source: fixture,
    output: output,
    mapDocument: mapDocument,
  ).compile();
}

Future<void> _check(Directory workspace) async {
  final temporary = await Directory.systemTemp.createTemp(
    'aonw-starter-map-bundle-',
  );
  try {
    final first = Directory('${temporary.path}/first');
    final second = Directory('${temporary.path}/second');
    await compileStarterMapBundle(workspace: workspace, output: first);
    await compileStarterMapBundle(workspace: workspace, output: second);
    await _compareBundle(first, second);
    for (final path in _committedOutputs) {
      await _compareBundle(Directory('${workspace.path}/$path'), first);
    }
  } finally {
    await temporary.delete(recursive: true);
  }
}

Future<void> _compareBundle(Directory expected, Directory actual) async {
  final expectedFiles = await _bundleFiles(expected);
  final actualFiles = await _bundleFiles(actual);
  if (expectedFiles.keys
          .toSet()
          .difference(actualFiles.keys.toSet())
          .isNotEmpty ||
      actualFiles.keys
          .toSet()
          .difference(expectedFiles.keys.toSet())
          .isNotEmpty) {
    throw StateError('Starter map bundle file set differs');
  }
  for (final path in expectedFiles.keys) {
    final left = expectedFiles[path]!;
    final right = actualFiles[path]!;
    if (left.length != right.length) {
      throw StateError('Starter map bundle size differs: $path');
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        throw StateError('Starter map bundle bytes differ: $path');
      }
    }
  }
}

Future<Map<String, List<int>>> _bundleFiles(Directory root) async {
  final files = <String, List<int>>{};
  if (!await root.exists()) return files;
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File || entity.path.endsWith('.import')) continue;
    final path = entity.path
        .substring(root.path.length + 1)
        .replaceAll('\\', '/');
    files[path] = await entity.readAsBytes();
  }
  return files;
}

final class _StarterReferenceFixture implements MapTileImageSource {
  const _StarterReferenceFixture({
    required this.mapId,
    required this.mapContentHash,
    required this.cols,
    required this.rows,
    required this.tileWidth,
    required this.tileHeight,
    required this.palette,
    required this.tileRows,
  });

  static Future<_StarterReferenceFixture> fromFile(File file) async {
    final decoded = _fixtureRoot(jsonDecode(await file.readAsString()));
    final dimensions = _dimensions(decoded);
    final size = _tileSize(decoded['tilePixelSize']);
    final palette = _palette(decoded['palette']);
    return _StarterReferenceFixture(
      mapId: _mapId(decoded['mapId']),
      mapContentHash: _contentHash(decoded['mapContentHash']),
      cols: dimensions.cols,
      rows: dimensions.rows,
      tileWidth: size.width,
      tileHeight: size.height,
      palette: palette,
      tileRows: _tileRows(
        decoded['tileRows'],
        cols: dimensions.cols,
        rows: dimensions.rows,
        palette: palette,
      ),
    );
  }

  final String mapId;
  final String mapContentHash;
  final int cols;
  final int rows;
  final int tileWidth;
  final int tileHeight;
  final Map<String, img.ColorRgb8> palette;
  final List<List<String>> tileRows;

  Future<void> verifyMapDocument(File file) async {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic> ||
        decoded['mapName'] != mapId ||
        decoded['gridLayout'] != mapAssetBundleGridLayout ||
        decoded['cols'] != cols ||
        decoded['rows'] != rows) {
      throw const FormatException(
        'Starter fixture does not match its canonical map document',
      );
    }
  }

  @override
  Future<img.Image> load(int column, int row) async {
    final color = palette[tileRows[row][column]]!;
    return img.Image(width: tileWidth, height: tileHeight, numChannels: 3)
      ..clear(color);
  }
}

Map<String, dynamic> _fixtureRoot(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Starter reference fixture must be an object');
  }
  _expectKeys(value, const {
    'mapId',
    'mapContentHash',
    'cols',
    'rows',
    'tilePixelSize',
    'palette',
    'tileRows',
  }, 'starter reference fixture');
  return value;
}

String _mapId(Object? value) {
  if (value is! String || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value)) {
    throw const FormatException('Starter fixture mapId is invalid');
  }
  return value;
}

String _contentHash(Object? value) {
  if (value is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
    throw const FormatException('Starter fixture mapContentHash is invalid');
  }
  return value;
}

({int cols, int rows}) _dimensions(Map<String, dynamic> value) {
  final cols = value['cols'];
  final rows = value['rows'];
  if (cols is! int || rows is! int || cols <= 0 || rows <= 0) {
    throw const FormatException('Starter fixture dimensions are invalid');
  }
  return (cols: cols, rows: rows);
}

({int width, int height}) _tileSize(Object? value) {
  if (value is! List<dynamic> ||
      value.length != 2 ||
      value.any((item) => item is! int || item <= 0)) {
    throw const FormatException('Starter fixture tile size is invalid');
  }
  return (width: value[0] as int, height: value[1] as int);
}

Map<String, img.ColorRgb8> _palette(Object? value) {
  if (value is! Map<String, dynamic> || value.isEmpty) {
    throw const FormatException('Starter fixture palette is invalid');
  }
  return Map.unmodifiable({
    for (final entry in value.entries)
      entry.key: _color(entry.key, entry.value),
  });
}

img.ColorRgb8 _color(String name, Object? value) {
  if (value is! String || !RegExp(r'^[0-9a-f]{6}$').hasMatch(value)) {
    throw FormatException('Starter palette color $name is invalid');
  }
  final rgb = int.parse(value, radix: 16);
  return img.ColorRgb8((rgb >> 16) & 0xff, (rgb >> 8) & 0xff, rgb & 0xff);
}

List<List<String>> _tileRows(
  Object? value, {
  required int cols,
  required int rows,
  required Map<String, img.ColorRgb8> palette,
}) {
  if (value is! List<dynamic> || value.length != rows) {
    throw const FormatException('Starter fixture tile rows are invalid');
  }
  return List.unmodifiable([
    for (final row in value) _tileRow(row, cols: cols, palette: palette),
  ]);
}

List<String> _tileRow(
  Object? value, {
  required int cols,
  required Map<String, img.ColorRgb8> palette,
}) {
  if (value is! List<dynamic> || value.length != cols) {
    throw const FormatException('Starter fixture tile row has wrong width');
  }
  final row = value.cast<String>();
  if (row.any((color) => !palette.containsKey(color))) {
    throw const FormatException('Starter fixture uses an unknown color');
  }
  return List.unmodifiable(row);
}

void _expectKeys(
  Map<String, dynamic> value,
  Set<String> expected,
  String context,
) {
  final actual = value.keys.toSet();
  if (actual.length != expected.length || !actual.containsAll(expected)) {
    throw FormatException('$context has unexpected fields: $actual');
  }
}
