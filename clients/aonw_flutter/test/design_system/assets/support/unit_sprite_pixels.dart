import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:aonw_flutter/design_system/assets/sprite_frame_id.dart';
import 'package:aonw_flutter/design_system/assets/sprite_frame_repository.dart';
import 'package:aonw_flutter/design_system/assets/texture_packer_sprite_frame_repository.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Hashes each native-decoded unit in its original transparent canvas.
Future<Map<String, Object?>> readUnitSpritePixels() async {
  final manifest =
      jsonDecode(
            await rootBundle.loadString(
              TexturePackerSpriteFrameRepository.manifestPath,
            ),
          )
          as Map<String, dynamic>;
  final entries = (manifest['frames'] as Map).entries.where(
    (entry) => (entry.key as String).startsWith('unit.'),
  );
  final groups = <String, List<String>>{};
  for (final entry in entries) {
    (groups[(entry.value as Map)['atlas'] as String] ??= []).add(
      entry.key as String,
    );
  }
  final records = <String, Object?>{};
  for (final ids in groups.values) {
    final repository = TexturePackerSpriteFrameRepository();
    final scope = repository.createScope();
    final pages = <ui.Image, ByteData>{};
    try {
      for (final id in ids..sort()) {
        final frame = await scope.load(SpriteFrameId(id));
        final data = pages[frame.image] ??= (await frame.image.toByteData())!;
        records[id] = {
          'width': frame.originalSize.width,
          'height': frame.originalSize.height,
          'sha256': sha256.convert(_logicalPixels(frame, data)).toString(),
        };
      }
    } finally {
      scope.dispose();
      repository.dispose();
    }
  }
  return {'pixelFormat': 'premultipliedRgba8888', 'frames': records};
}

Uint8List _logicalPixels(SpriteFrame frame, ByteData data) {
  final width = frame.originalSize.width.toInt();
  final height = frame.originalSize.height.toInt();
  final left = frame.trimOffset.dx.toInt();
  final top = frame.trimOffset.dy.toInt();
  final regionWidth = frame.source.width.toInt();
  final regionHeight = frame.source.height.toInt();
  if (left < 0 ||
      top < 0 ||
      left + regionWidth > width ||
      top + regionHeight > height) {
    throw StateError(
      'Unit trim is outside its original canvas: ${frame.id.value}',
    );
  }
  final source = data.buffer.asUint8List(
    data.offsetInBytes,
    data.lengthInBytes,
  );
  final pixels = Uint8List(width * height * 4);
  for (var row = 0; row < regionHeight; row++) {
    final sourceOffset =
        ((frame.source.top.toInt() + row) * frame.image.width +
            frame.source.left.toInt()) *
        4;
    final targetOffset = ((top + row) * width + left) * 4;
    pixels.setRange(
      targetOffset,
      targetOffset + regionWidth * 4,
      source,
      sourceOffset,
    );
  }
  return pixels;
}
