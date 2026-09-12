import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../../../../tool/assets/compile/sprite_partition_source.dart';
import '../../../../tool/assets/compile/unit_sprite_crop.dart';
import '../../../../tool/assets/compile/unit_sprite_packing.dart';

void main() {
  test('aligns source crops to the original mipmap sample grid', () {
    final page = img.Image(width: 64, height: 96, numChannels: 4);
    page.setPixelRgba(40, 60, 10, 20, 30, 255);
    final region = SpritePartitionRegion(
      name: 'unit.test.idle',
      page: 'test.webp',
      bounds: [2, 2, 60, 92],
      offsets: [0, 0, 60, 92],
      index: 0,
    );
    final crop = cropUnitSprite(page, region);
    expect((crop.left, crop.top, crop.width, crop.height), (32, 32, 32, 64));
    expect(crop.pixels.getPixel(8, 28).toList(), [10, 20, 30, 255]);
  });
  test(
    'trims transparent margins while preserving logical placement and padding',
    () {
      final page = img.Image(width: 20, height: 24, numChannels: 4);
      for (var y = 10; y <= 14; y++) {
        for (var x = 8; x <= 11; x++) {
          page.setPixelRgba(x, y, 90, 120, 150, 64);
        }
      }
      final crop = cropUnitSprite(page, _region(), alignment: 1);
      expect((crop.left, crop.top, crop.width, crop.height), (4, 6, 12, 13));
      expect(
        crop.descriptor(100, 200),
        'unit.test.idle\nbounds:102,202,8,9\noffsets:7,9,24,28\nindex:0\n',
      );
      for (var y = 0; y < crop.height; y++) {
        for (var x = 0; x < crop.width; x++) {
          expect(
            crop.pixels.getPixel(x, y).toList(),
            page.getPixel(x + 4, y + 6).toList(),
          );
        }
      }
    },
  );

  test('preserves source extrusion when a visible pixel touches an edge', () {
    final page = img.Image(width: 20, height: 24, numChannels: 4);
    page.setPixelRgba(2, 2, 10, 20, 30, 255);
    page.setPixelRgba(0, 0, 40, 50, 60, 255);
    final crop = cropUnitSprite(page, _region(), alignment: 1);
    expect((crop.left, crop.top), (0, 0));
    expect(crop.pixels.getPixel(0, 0).toList(), [40, 50, 60, 255]);
  });

  test('rejects an empty sprite and a region outside the actual image', () {
    expect(
      () => cropUnitSprite(
        img.Image(width: 20, height: 24, numChannels: 4),
        _region(),
      ),
      throwsStateError,
    );
    expect(
      () => cropUnitSprite(
        img.Image(width: 8, height: 8, numChannels: 4),
        _region(),
      ),
      throwsStateError,
    );
  });

  test(
    'packing is deterministic, bounded and has no overlapping padded frames',
    () {
      final crops = [
        for (var i = 0; i < 24; i++)
          UnitSpriteCrop(
            _region(index: i),
            img.Image(width: 180 + i, height: 290 - i, numChannels: 4),
            0,
            0,
          ),
      ];
      final packing = packUnitSprites(crops);
      final reversed = packUnitSprites(crops.reversed.toList());
      expect(
        (packing.width, packing.height),
        (reversed.width, reversed.height),
      );
      expect(
        packing.frames.map((f) => (f.crop.region.index, f.x, f.y)),
        reversed.frames.map((f) => (f.crop.region.index, f.x, f.y)),
      );
      expect(packing.width, lessThanOrEqualTo(2048));
      expect(packing.height, lessThanOrEqualTo(2048));
      for (final a in packing.frames) {
        expect(a.x + a.crop.width, lessThanOrEqualTo(packing.width));
        expect(a.y + a.crop.height, lessThanOrEqualTo(packing.height));
        for (final b in packing.frames) {
          if (identical(a.crop, b.crop)) continue;
          expect(
            a.x + a.crop.width <= b.x ||
                b.x + b.crop.width <= a.x ||
                a.y + a.crop.height <= b.y ||
                b.y + b.crop.height <= a.y,
            isTrue,
          );
        }
      }
    },
  );
}

SpritePartitionRegion _region({int index = 0}) => SpritePartitionRegion(
  name: 'unit.test.idle',
  page: 'test.webp',
  bounds: [2, 2, 16, 20],
  offsets: [3, 4, 24, 28],
  index: index,
);
