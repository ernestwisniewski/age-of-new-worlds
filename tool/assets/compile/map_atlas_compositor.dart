import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'map_texture_geometry.dart';

/// Rasterizes overlapping hex images without blending their edge coverage
/// against transparent black.
///
/// Coverage is evaluated in the atlas coordinate system so neighboring hexes
/// share exactly the same mathematical edge even at fractional compilation
/// scales. Colors at that edge are averaged by coverage and the resulting
/// atlas is opaque RGB, which keeps JPEG encoding from baking the mask into
/// the map as a dark outline.
final class MapAtlasCompositor {
  MapAtlasCompositor({required int width, required int height})
    : image = img.Image(width: width, height: height, numChannels: 3),
      _weights = Float32List(width * height);

  final img.Image image;
  final Float32List _weights;

  void compositeHex(
    img.Image source, {
    required MapTilePixelPlacement placement,
  }) {
    for (var y = 0; y < source.height; y++) {
      final destinationY = placement.rasterTop + y;
      if (destinationY < 0 || destinationY >= image.height) continue;
      for (var x = 0; x < source.width; x++) {
        final destinationX = placement.rasterLeft + x;
        if (destinationX < 0 || destinationX >= image.width) continue;
        final weight = _hexCoverage(destinationX, destinationY, placement);
        if (weight == 0) continue;
        _blend(destinationX, destinationY, source.getPixel(x, y), weight);
      }
    }
  }

  void _blend(int x, int y, img.Pixel source, double coverage) {
    final sourceWeight = coverage * source.aNormalized;
    if (sourceWeight == 0) return;
    final index = y * image.width + x;
    final previousWeight = _weights[index];
    final combinedWeight = previousWeight + sourceWeight;
    if (previousWeight == 0) {
      image.setPixelRgb(x, y, source.r, source.g, source.b);
    } else {
      final destination = image.getPixel(x, y);
      image.setPixelRgb(
        x,
        y,
        (destination.r * previousWeight + source.r * sourceWeight) /
            combinedWeight,
        (destination.g * previousWeight + source.g * sourceWeight) /
            combinedWeight,
        (destination.b * previousWeight + source.b * sourceWeight) /
            combinedWeight,
      );
    }
    _weights[index] = combinedWeight;
  }
}

double _hexCoverage(
  int destinationX,
  int destinationY,
  MapTilePixelPlacement placement,
) {
  const samples = <(double, double)>[
    (0.25, 0.25),
    (0.75, 0.25),
    (0.25, 0.75),
    (0.75, 0.75),
  ];
  var covered = 0;
  for (final sample in samples) {
    final horizontal =
        (destinationX + sample.$1 - placement.exactLeft) / placement.exactWidth;
    final vertical =
        (destinationY + sample.$2 - placement.exactTop) / placement.exactHeight;
    if (unitHexContains(horizontal, vertical)) covered++;
  }
  return covered / samples.length;
}
