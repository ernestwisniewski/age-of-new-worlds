import 'dart:convert';
import 'dart:ui' as ui;

import 'package:aonw_flutter/design_system/assets/sprite_frame_id.dart';
import 'package:aonw_flutter/design_system/assets/sprite_frame_repository.dart';
import 'package:aonw_flutter/design_system/assets/texture_packer_sprite_frame_repository.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

/// Uses Flutter's decoder independently of the offline atlas partitioner.
Future<Map<String, Object?>> readStaticSpritePixels() async {
  final manifest =
      jsonDecode(
            await rootBundle.loadString(
              TexturePackerSpriteFrameRepository.manifestPath,
            ),
          )
          as Map<String, dynamic>;
  final ids =
      (manifest['frames'] as Map).keys
          .cast<String>()
          .where(
            (id) => id.startsWith('city.') || id.startsWith('improvement.'),
          )
          .toList()
        ..sort();
  final repository = TexturePackerSpriteFrameRepository();
  final scope = repository.createScope();
  final pages = <ui.Image, ByteData>{};
  final records = <String, Object?>{};
  try {
    for (final id in ids) {
      final frame = await scope.load(SpriteFrameId(id));
      final data = pages[frame.image] ??= (await frame.image.toByteData())!;
      records[id] = {
        'width': frame.source.width,
        'height': frame.source.height,
        'originalWidth': frame.originalSize.width,
        'originalHeight': frame.originalSize.height,
        'trimX': frame.trimOffset.dx,
        'trimY': frame.trimOffset.dy,
        'sha256': sha256.convert(_pixels(frame, data)).toString(),
      };
    }
    return {
      'pixelFormat': 'premultipliedRgba8888',
      'padding': 2,
      'frames': records,
    };
  } finally {
    scope.dispose();
    repository.dispose();
  }
}

Uint8List _pixels(SpriteFrame frame, ByteData data) {
  final left = frame.source.left.toInt() - 2;
  final top = frame.source.top.toInt() - 2;
  final width = frame.source.width.toInt() + 4;
  final height = frame.source.height.toInt() + 4;
  if (left < 0 ||
      top < 0 ||
      left + width > frame.image.width ||
      top + height > frame.image.height) {
    throw StateError('Missing extrusion for ${frame.id.value}');
  }
  final source = data.buffer.asUint8List(
    data.offsetInBytes,
    data.lengthInBytes,
  );
  final pixels = Uint8List(width * height * 4);
  for (var row = 0; row < height; row++) {
    final offset = ((top + row) * frame.image.width + left) * 4;
    pixels.setRange(row * width * 4, (row + 1) * width * 4, source, offset);
  }
  return pixels;
}
