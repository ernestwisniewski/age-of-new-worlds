import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/design_system/assets/sprite_frame_id.dart';
import 'package:aonw_flutter/design_system/assets/texture_packer_sprite_frame_repository.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/map/map_sprite_catalog.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Flutter atlas bundle is byte-identical to canonical runtime assets',
    () {
      final canonical = Directory('../../assets/runtime/sprites');
      final bundled = Directory('assets/runtime/sprites');
      final canonicalFiles = _relativeFiles(canonical);
      final bundledFiles = _relativeFiles(bundled);

      expect(bundledFiles, canonicalFiles);
      for (final path in canonicalFiles) {
        final canonicalDigest = sha256.convert(
          File('${canonical.path}/$path').readAsBytesSync(),
        );
        final bundledDigest = sha256.convert(
          File('${bundled.path}/$path').readAsBytesSync(),
        );
        expect(bundledDigest, canonicalDigest, reason: path);
      }
    },
  );

  test('manifest covers every map sprite semantic identifier', () {
    final document =
        jsonDecode(
              File(
                'assets/runtime/sprites/sprite_manifest.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final atlases = document['atlases'] as Map<String, dynamic>;
    final frames = document['frames'] as Map<String, dynamic>;

    expect(document['version'], 1);
    expect(atlases, hasLength(29));
    expect(frames, hasLength(711));
    for (final kind in VisibleUnitKind.values) {
      for (final id in MapSpriteCatalog.idleUnitFrames(kind)) {
        expect(frames, contains(id.value));
      }
    }
    for (final kind in FieldImprovementKind.values) {
      for (var era = 0; era < MapSpriteCatalog.improvementEraCount; era += 1) {
        expect(
          frames,
          contains(MapSpriteCatalog.improvementFrame(kind, era: era).value),
        );
      }
    }
    for (final profile in MapCitySpriteProfile.values) {
      for (var level = 0; level < 6; level += 1) {
        expect(
          frames,
          contains(
            MapSpriteCatalog.cityFrame(
              visualLevel: level,
              profile: profile,
            ).value,
          ),
        );
      }
    }
  });

  testWidgets('repository decodes and caches representative atlas frames', (
    tester,
  ) async {
    final repository = TexturePackerSpriteFrameRepository();
    addTearDown(repository.dispose);

    final loads = await tester.runAsync(
      () => Future.wait([
        repository.load(const SpriteFrameId('unit.warrior.idle.0')),
        repository.load(const SpriteFrameId('unit.warrior.idle.0')),
        repository.load(const SpriteFrameId('city.growthCivic.0')),
        repository.load(const SpriteFrameId('improvement.farm.0')),
      ]),
    );

    expect(loads![0], same(loads[1]));
    expect(loads[0].originalSize.width, 252);
    expect(loads[0].originalSize.height, 380);
    expect(loads[0].contentBounds.isEmpty, isFalse);
    expect(loads[2].originalSize.width, 512);
    expect(loads[2].originalSize.height, 320);
    expect(loads[3].source.isEmpty, isFalse);
  });
}

List<String> _relativeFiles(Directory directory) {
  final rootLength = directory.path.length + 1;
  return [
    for (final file in directory.listSync(recursive: true).whereType<File>())
      file.path.substring(rootLength),
  ]..sort();
}
