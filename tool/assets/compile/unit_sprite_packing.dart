import 'dart:math' as math;

import 'unit_sprite_crop.dart';

typedef PackedUnitSprite = ({UnitSpriteCrop crop, int x, int y});
typedef UnitSpritePacking = ({
  int width,
  int height,
  List<PackedUnitSprite> frames,
});

UnitSpritePacking packUnitSprites(List<UnitSpriteCrop> crops) {
  final sorted = [...crops]
    ..sort((a, b) {
      final height = b.height.compareTo(a.height);
      if (height != 0) return height;
      final name = a.region.name.compareTo(b.region.name);
      return name != 0 ? name : a.region.index.compareTo(b.region.index);
    });
  UnitSpritePacking? best;
  for (var width = 256; width <= 2048; width += 64) {
    final candidate = _packRows(sorted, width);
    if (candidate == null) continue;
    if (best == null ||
        candidate.width * candidate.height < best.width * best.height) {
      best = candidate;
    }
  }
  if (best == null)
    throw StateError('Unit frames exceed the atlas page limit.');
  return best;
}

UnitSpritePacking? _packRows(List<UnitSpriteCrop> crops, int limit) {
  var x = 0;
  var y = 0;
  var rowHeight = 0;
  var width = 0;
  final frames = <PackedUnitSprite>[];
  for (final crop in crops) {
    if (crop.width > limit) return null;
    if (x + crop.width > limit) {
      x = 0;
      y += rowHeight;
      rowHeight = 0;
    }
    if (y + crop.height > 2048) return null;
    frames.add((crop: crop, x: x, y: y));
    x += crop.width;
    width = math.max(width, x);
    rowHeight = math.max(rowHeight, crop.height);
  }
  return (width: width, height: y + rowHeight, frames: frames);
}
