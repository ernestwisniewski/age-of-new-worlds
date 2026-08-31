import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/features/map/application/map_session_port.dart';
import 'package:aonw_flutter/features/map/infrastructure/map_reference_bundle_loader.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

const _manifest = 'assets/maps/aonw2_starter/map_texture_manifest.json';
const _mapHash =
    '4d5603cc00fa8963a71c23133570f89f43c734598d86579e12e1b1059da8712d';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('verifies and loads the committed starter reference page', () async {
    final scene = testMapScene(
      cols: 7,
      rows: 7,
      mapId: 'aonw2_starter',
      contentHash: _mapHash,
    );

    final bundle = await MapReferenceBundleLoader(
      _FileAssetBundle(),
    ).load(manifestAsset: _manifest, map: scene.map);

    expect(bundle.mapContentHash, _mapHash);
    expect(bundle.pages, hasLength(1));
    expect(bundle.pages.single.pixelWidth, 1324);
    expect(bundle.pages.single.pixelHeight, 1563);
    expect(bundle.pages.single.bytes, isNotEmpty);
  });

  test('rejects a bundle with another map content hash', () async {
    final scene = testMapScene(
      cols: 7,
      rows: 7,
      mapId: 'aonw2_starter',
      contentHash: 'b' * 64,
    );

    await expectLater(
      MapReferenceBundleLoader(
        _FileAssetBundle(),
      ).load(manifestAsset: _manifest, map: scene.map),
      throwsA(
        isA<MapLoadException>().having(
          (error) => error.code,
          'code',
          'invalid_map_bundle',
        ),
      ),
    );
  });

  test('rejects world bounds that do not match odd-q geometry', () async {
    final scene = testMapScene(
      cols: 7,
      rows: 7,
      mapId: 'aonw2_starter',
      contentHash: _mapHash,
    );

    await expectLater(
      MapReferenceBundleLoader(
        _FileAssetBundle(
          transformManifest: (contents) {
            final manifest = jsonDecode(contents) as Map<String, dynamic>;
            manifest['worldHeight'] = 727.4613391789285;
            return jsonEncode(manifest);
          },
        ),
      ).load(manifestAsset: _manifest, map: scene.map),
      throwsA(
        isA<MapLoadException>().having(
          (error) => error.code,
          'code',
          'invalid_map_bundle',
        ),
      ),
    );
  });

  test('rejects pages outside, overlapping, gapped or over budget', () async {
    await _expectInvalidManifest(
      (manifest) =>
          (manifest['pages'] as List<dynamic>).first['destination'][0] = -10,
      diagnostic: 'outside the atlas',
    );
    await _expectInvalidManifest((manifest) {
      final pages = manifest['pages'] as List<dynamic>;
      final duplicate = Map<String, dynamic>.from(
        pages.first as Map<String, dynamic>,
      );
      duplicate['file'] = 'page_01.jpg';
      duplicate['asset'] = 'assets/runtime/maps/aonw2_starter/page_01.jpg';
      pages.add(duplicate);
    }, diagnostic: 'overlap excessively');
    await _expectInvalidManifest((manifest) {
      final page = (manifest['pages'] as List<dynamic>).first;
      page['pixelWidth'] = 1300;
      page['destination'][2] = 650.0;
    }, diagnostic: 'coverage has a gap');
    await _expectInvalidManifest((manifest) {
      manifest['pageSizeLimit'] = 10000;
      final page = (manifest['pages'] as List<dynamic>).first;
      page['pixelWidth'] = 10000;
      page['pixelHeight'] = 10000;
      page['destination'] = [-1.0, -1.0, 5000.0, 5000.0];
    }, diagnostic: 'pixel budget');
  });

  test('rejects incomplete average color coverage', () async {
    await _expectInvalidManifest((manifest) {
      (manifest['averageColors'] as Map<String, dynamic>).remove('0,0');
    }, diagnostic: 'average colors are incomplete');
  });
}

Future<void> _expectInvalidManifest(
  void Function(Map<String, dynamic> manifest) mutate, {
  required String diagnostic,
}) async {
  final scene = testMapScene(
    cols: 7,
    rows: 7,
    mapId: 'aonw2_starter',
    contentHash: _mapHash,
  );
  try {
    await MapReferenceBundleLoader(
      _FileAssetBundle(
        transformManifest: (contents) {
          final manifest = jsonDecode(contents) as Map<String, dynamic>;
          mutate(manifest);
          return jsonEncode(manifest);
        },
      ),
    ).load(manifestAsset: _manifest, map: scene.map);
    fail('Expected an invalid map bundle.');
  } on MapLoadException catch (error) {
    expect(error.message, 'The map reference artwork could not be loaded.');
    expect(error.diagnosticCause, isA<FormatException>());
    expect(error.diagnosticCause.toString(), contains(diagnostic));
  }
}

final class _FileAssetBundle extends CachingAssetBundle {
  _FileAssetBundle({this.transformManifest});

  final String Function(String contents)? transformManifest;

  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final contents = utf8.decode((await load(key)).buffer.asUint8List());
    final transform = transformManifest;
    return key == _manifest && transform != null
        ? transform(contents)
        : contents;
  }
}
