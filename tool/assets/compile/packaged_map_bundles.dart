import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;

import 'map_asset_bundle_manifest.dart';
import 'starter_map_bundle.dart';

const packagedMapIds = <String>[
  'aonw2_starter',
  'dravonia',
  'myranth',
  'terenos',
  'verdantia',
];

const _clientMapRoots = <String>[
  'clients/aonw_flutter/assets/maps',
  'clients/aonw_godot/assets/maps',
];

Future<void> main(List<String> arguments) async {
  try {
    final command = arguments.isEmpty ? 'check' : arguments.first;
    if (arguments.length > 1 || !const {'compile', 'check'}.contains(command)) {
      throw const FormatException(
        'Usage: dart --packages=.dart_tool/package_config.json '
        '../../tool/assets/compile/packaged_map_bundles.dart '
        '<compile|check>',
      );
    }
    final workspace = _repositoryRoot();
    if (command == 'compile') {
      await compilePackagedMapBundles(workspace: workspace);
    } else {
      await checkPackagedMapBundles(workspace: workspace);
    }
  } on FormatException catch (error) {
    stderr.writeln('Packaged map bundle contract error: ${error.message}');
    exitCode = 1;
  } on StateError catch (error) {
    stderr.writeln('Packaged map bundle failed: ${error.message}');
    exitCode = 1;
  }
}

Directory _repositoryRoot() =>
    File.fromUri(Platform.script).parent.parent.parent.parent.absolute;

Future<void> compilePackagedMapBundles({required Directory workspace}) async {
  final temporary = await Directory.systemTemp.createTemp(
    'aonw-packaged-map-bundles-',
  );
  try {
    await buildPackagedMapBundles(workspace: workspace, output: temporary);
    for (final clientRoot in _clientMapRoots) {
      for (final mapId in packagedMapIds) {
        await _synchronizeBundle(
          expected: Directory('${temporary.path}/$mapId'),
          actual: Directory('${workspace.path}/$clientRoot/$mapId'),
        );
      }
    }
  } finally {
    await temporary.delete(recursive: true);
  }
  await checkPackagedMapBundles(workspace: workspace);
}

Future<void> checkPackagedMapBundles({required Directory workspace}) async {
  final temporary = await Directory.systemTemp.createTemp(
    'aonw-packaged-map-bundles-check-',
  );
  try {
    final first = Directory('${temporary.path}/first');
    final second = Directory('${temporary.path}/second');
    await buildPackagedMapBundles(workspace: workspace, output: first);
    await buildPackagedMapBundles(workspace: workspace, output: second);
    await _compareBundleRoots(first, second);
    for (final clientRoot in _clientMapRoots) {
      await _compareBundleRoots(
        first,
        Directory('${workspace.path}/$clientRoot'),
      );
    }
  } finally {
    await temporary.delete(recursive: true);
  }
}

Future<void> buildPackagedMapBundles({
  required Directory workspace,
  required Directory output,
}) async {
  if (await output.exists()) await output.delete(recursive: true);
  await output.create(recursive: true);
  await compileStarterMapBundle(
    workspace: workspace,
    output: Directory('${output.path}/aonw2_starter'),
  );
  for (final mapId in packagedMapIds.skip(1)) {
    await _stageCanonicalBundle(
      workspace: workspace,
      output: Directory('${output.path}/$mapId'),
      mapId: mapId,
    );
  }
}

Future<void> _stageCanonicalBundle({
  required Directory workspace,
  required Directory output,
  required String mapId,
}) async {
  final source = Directory('${workspace.path}/assets/runtime/maps/$mapId');
  final manifestFile = File('${source.path}/$mapAssetBundleManifestName');
  final mapFile = File('${workspace.path}/content/maps/$mapId/map.json');
  if (!await manifestFile.exists() || !await mapFile.exists()) {
    throw StateError('Canonical map bundle is incomplete: $mapId');
  }
  final manifest = MapAssetBundleManifest.decode(
    await manifestFile.readAsString(),
  );
  final map = _mapDocument(await mapFile.readAsString(), mapId);
  manifest.verifyMapIdentity(
    mapId: mapId,
    mapContentHash: manifest.mapContentHash,
    cols: map.cols,
    rows: map.rows,
  );
  await output.create(recursive: true);
  await mapFile.copy('${output.path}/map.json');
  await manifestFile.copy('${output.path}/$mapAssetBundleManifestName');
  for (final page in manifest.pages) {
    if (page.asset != 'assets/runtime/maps/$mapId/${page.file}') {
      throw FormatException('Map asset path does not match $mapId');
    }
    final pageFile = File('${source.path}/${page.file}');
    if (!await pageFile.exists()) {
      throw StateError('Canonical map page is missing: $mapId/${page.file}');
    }
    final bytes = await pageFile.readAsBytes();
    if (sha256.convert(bytes).toString() != page.sha256) {
      throw StateError(
        'Canonical map page digest differs: $mapId/${page.file}',
      );
    }
    final image = img.decodeJpg(bytes);
    if (image == null ||
        image.width != page.pixelWidth ||
        image.height != page.pixelHeight) {
      throw StateError(
        'Canonical map page dimensions differ: $mapId/${page.file}',
      );
    }
    await pageFile.copy('${output.path}/${page.file}');
  }
  final expected = {
    mapAssetBundleManifestName,
    ...manifest.pages.map((page) => page.file),
  };
  final actual = await _relativeFilePaths(source);
  if (actual.difference(expected).isNotEmpty ||
      expected.difference(actual).isNotEmpty) {
    throw StateError('Canonical map bundle file set differs: $mapId');
  }
}

({int cols, int rows}) _mapDocument(String contents, String mapId) {
  final value = jsonDecode(contents);
  if (value is! Map<String, dynamic> ||
      value['schemaVersion'] != 1 ||
      value['mapName'] != mapId ||
      value['gridLayout'] != mapAssetBundleGridLayout ||
      value['cols'] is! int ||
      value['rows'] is! int) {
    throw FormatException('Canonical map document does not match $mapId');
  }
  return (cols: value['cols'] as int, rows: value['rows'] as int);
}

Future<void> _synchronizeBundle({
  required Directory expected,
  required Directory actual,
}) async {
  await actual.create(recursive: true);
  final expectedFiles = await _relativeFiles(expected);
  final actualFiles = await _relativeFiles(actual);
  for (final entry in actualFiles.entries) {
    if (!expectedFiles.containsKey(entry.key)) await entry.value.delete();
  }
  for (final entry in expectedFiles.entries) {
    final destination = File('${actual.path}/${entry.key}');
    await destination.parent.create(recursive: true);
    await entry.value.copy(destination.path);
  }
}

Future<void> _compareBundleRoots(Directory expected, Directory actual) async {
  for (final mapId in packagedMapIds) {
    await _compareBundle(
      Directory('${expected.path}/$mapId'),
      Directory('${actual.path}/$mapId'),
      mapId,
    );
  }
}

Future<void> _compareBundle(
  Directory expected,
  Directory actual,
  String mapId,
) async {
  final expectedFiles = await _relativeFiles(expected);
  final actualFiles = await _relativeFiles(actual);
  if (expectedFiles.keys
          .toSet()
          .difference(actualFiles.keys.toSet())
          .isNotEmpty ||
      actualFiles.keys
          .toSet()
          .difference(expectedFiles.keys.toSet())
          .isNotEmpty) {
    throw StateError('Packaged map bundle file set differs: $mapId');
  }
  for (final path in expectedFiles.keys) {
    final left = expectedFiles[path]!;
    final right = actualFiles[path]!;
    if (await left.length() != await right.length() ||
        await _digest(left) != await _digest(right)) {
      throw StateError('Packaged map bundle bytes differ: $mapId/$path');
    }
  }
}

Future<String> _digest(File file) =>
    sha256.bind(file.openRead()).first.then((value) => value.toString());

Future<Set<String>> _relativeFilePaths(Directory root) async =>
    (await _relativeFiles(root)).keys.toSet();

Future<Map<String, File>> _relativeFiles(Directory root) async {
  final files = <String, File>{};
  if (!await root.exists()) return files;
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File ||
        entity.path.endsWith('.import') ||
        entity.uri.pathSegments.last.startsWith('.')) {
      continue;
    }
    final relative = entity.path
        .substring(root.path.length + 1)
        .replaceAll('\\', '/');
    files[relative] = entity;
  }
  return files;
}
