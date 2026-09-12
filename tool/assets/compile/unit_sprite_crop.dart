import 'dart:math' as math;

import 'package:image/image.dart' as img;

import 'sprite_partition_source.dart';

final class UnitSpriteCrop {
  const UnitSpriteCrop(this.region, this.pixels, this.left, this.top);

  final SpritePartitionRegion region;
  final img.Image pixels;
  final int left;
  final int top;

  int get width => pixels.width;
  int get height => pixels.height;

  String descriptor(int x, int y) {
    final offsets = region.offsets;
    final bottomTrim = region.bounds[3] - top - (height - 4);
    return '${region.name}\n'
        'bounds:${x + 2},${y + 2},${width - 4},${height - 4}\n'
        'offsets:${offsets[0] + left},${offsets[1] + bottomTrim},'
        '${offsets[2]},${offsets[3]}\nindex:${region.index}\n';
  }
}

UnitSpriteCrop cropUnitSprite(
  img.Image page,
  SpritePartitionRegion region, {
  int alignment = 32,
}) {
  final b = region.bounds;
  if (b[0] < 2 ||
      b[1] < 2 ||
      b[0] + b[2] + 2 > page.width ||
      b[1] + b[3] + 2 > page.height) {
    throw StateError('Unit region exceeds its decoded page.');
  }
  final visible = _visibleBounds(page, b);
  // Retain transparent samples inside the sprite, plus the original extrusion.
  if (alignment <= 0) throw ArgumentError.value(alignment, 'alignment');
  final left = math.max(0, (visible.left - 2) ~/ alignment * alignment);
  final top = math.max(0, (visible.top - 2) ~/ alignment * alignment);
  final right = math.min(
    b[2],
    left + _align(visible.right + 7 - left, alignment) - 4,
  );
  final bottom = math.min(
    b[3],
    top + _align(visible.bottom + 7 - top, alignment) - 4,
  );
  final pixels = img.copyCrop(
    page,
    x: b[0] + left - 2,
    y: b[1] + top - 2,
    width: right - left + 4,
    height: bottom - top + 4,
  );
  return UnitSpriteCrop(region, pixels, left, top);
}

({int left, int top, int right, int bottom}) _visibleBounds(
  img.Image page,
  List<int> bounds,
) {
  var left = bounds[2];
  var top = bounds[3];
  var right = -1;
  var bottom = -1;
  for (var y = 0; y < bounds[3]; y++) {
    for (var x = 0; x < bounds[2]; x++) {
      if (page.getPixel(bounds[0] + x, bounds[1] + y).a == 0) continue;
      left = math.min(left, x);
      top = math.min(top, y);
      right = math.max(right, x);
      bottom = math.max(bottom, y);
    }
  }
  if (right < left) throw StateError('Unit sprite has no visible pixels.');
  return (left: left, top: top, right: right, bottom: bottom);
}

int _align(int value, int alignment) =>
    (value + alignment - 1) ~/ alignment * alignment;
