import 'dart:convert';

import 'package:aonw_flutter/features/audio/application/game_audio_port.dart';
import 'package:aonw_flutter/features/audio/infrastructure/audio_asset_catalog.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'packages every cue and playlist with the reviewed audio fingerprints',
    () async {
      final manifest =
          jsonDecode(await rootBundle.loadString('assets/audio/manifest.json'))
              as Map<String, Object?>;
      expect(manifest['schemaVersion'], 1);
      final records = manifest['assets']! as List<Object?>;
      expect(records, hasLength(19));
      expect(
        AudioAssetCatalog.effects.keys.toSet(),
        GameSoundCue.values.toSet(),
      );
      expect(AudioAssetCatalog.effects.values.toSet(), hasLength(10));
      final paths = <String>{};
      for (final record in records.cast<Map<String, Object?>>()) {
        final path = record['asset']! as String;
        expect(paths.add(path), isTrue);
        final data = await rootBundle.load(path);
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        expect(bytes.length, record['bytes']);
        expect(
          sha256.convert(bytes).toString(),
          record['sha256'],
          reason: path,
        );
      }
      expect(paths, AudioAssetCatalog.assets);
    },
  );
}
