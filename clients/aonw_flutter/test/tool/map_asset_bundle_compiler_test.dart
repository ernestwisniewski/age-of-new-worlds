import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/assets/compile/map_asset_bundle_manifest.dart';
import '../../../../tool/assets/compile/map_texture_geometry.dart';
import '../../../../tool/assets/compile/starter_map_bundle.dart';

void main() {
  test('starter bundle is deterministic and self-contained', () async {
    final temporary = await Directory.systemTemp.createTemp(
      'starter-map-bundle-test-',
    );
    addTearDown(() => temporary.delete(recursive: true));
    final workspace = Directory('../..').absolute;
    final first = Directory('${temporary.path}/first');
    final second = Directory('${temporary.path}/second');

    await compileStarterMapBundle(workspace: workspace, output: first);
    await compileStarterMapBundle(workspace: workspace, output: second);

    final firstFiles = await _files(first);
    final secondFiles = await _files(second);
    expect(firstFiles.keys, secondFiles.keys);
    for (final path in firstFiles.keys) {
      expect(firstFiles[path], secondFiles[path], reason: path);
    }
    expect(
      firstFiles.keys,
      containsAll(['map.json', mapAssetBundleManifestName]),
    );
    final manifest = MapAssetBundleManifest.decode(
      String.fromCharCodes(firstFiles[mapAssetBundleManifestName]!),
    );
    expect(manifest.mapId, 'aonw2_starter');
    expect(manifest.worldWidth, closeTo(mapWorldWidth(7), 1e-9));
    expect(manifest.worldHeight, closeTo(mapWorldHeight(7, 7), 1e-9));
    expect(manifest.pages, isNotEmpty);
    for (final page in manifest.pages) {
      expect(firstFiles[page.file], isNotNull);
    }
  });

  test('bundle rejects a different map content hash', () async {
    final temporary = await Directory.systemTemp.createTemp(
      'starter-map-bundle-identity-',
    );
    addTearDown(() => temporary.delete(recursive: true));
    final manifest = await compileStarterMapBundle(
      workspace: Directory('../..').absolute,
      output: temporary,
    );

    expect(
      () => manifest.verifyMapIdentity(
        mapId: manifest.mapId,
        mapContentHash: ''.padLeft(64, '0'),
        cols: manifest.cols,
        rows: manifest.rows,
      ),
      throwsFormatException,
    );
  });
}

Future<Map<String, List<int>>> _files(Directory root) async {
  final result = <String, List<int>>{};
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is File) {
      result[entity.path.substring(root.path.length + 1)] = await entity
          .readAsBytes();
    }
  }
  return result;
}
