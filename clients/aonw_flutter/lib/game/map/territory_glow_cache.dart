import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'city_territory_style.dart';

/// Retains the fixed, diffuse strategic borders while sharp strokes stay vector.
final class MapTerritoryGlowCache {
  static const _pixelBudget = 2 * 1024 * 1024;
  static const _density = 1;
  static const _padding = 12.0;
  final _images = <(ui.Path, int), ({ui.Image image, ui.Rect bounds})>{};
  final _paint = ui.Paint()..filterQuality = ui.FilterQuality.medium;
  var _pixelCount = 0;
  var _buildCount = 0;

  @visibleForTesting
  int get debugBuildCount => _buildCount;

  @visibleForTesting
  int get debugPixelCount => _pixelCount;

  @visibleForTesting
  int get debugImageCount => _images.length;

  void draw(ui.Canvas canvas, ui.Path path, ui.Color color) {
    final key = (path, color.toARGB32());
    var entry = _images.remove(key);
    if (entry == null) {
      final bounds = path.getBounds().inflate(_padding);
      final width = (bounds.width * _density).ceil();
      final height = (bounds.height * _density).ceil();
      final pixels = width * height;
      final glow = territoryStroke(
        color,
        alpha: (color.a * 255).round(),
        width: 5,
      )..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
      if (pixels > _pixelBudget) {
        canvas.drawPath(path, glow);
        return;
      }
      _makeRoom(pixels);
      _buildCount++;
      final recorder = ui.PictureRecorder();
      final local = ui.Canvas(recorder)
        ..scale(_density.toDouble())
        ..translate(-bounds.left, -bounds.top);
      local.drawPath(path, glow);
      final picture = recorder.endRecording();
      entry = (
        image: picture.toImageSync(width, height),
        bounds: ui.Rect.fromLTWH(
          bounds.left,
          bounds.top,
          width / _density,
          height / _density,
        ),
      );
      picture.dispose();
      _pixelCount += pixels;
    }
    _images[key] = entry;
    canvas.drawImageRect(
      entry.image,
      ui.Rect.fromLTWH(
        0,
        0,
        entry.image.width.toDouble(),
        entry.image.height.toDouble(),
      ),
      entry.bounds,
      _paint,
    );
  }

  void clear() {
    for (final entry in _images.values) {
      entry.image.dispose();
    }
    _images.clear();
    _pixelCount = 0;
  }

  void _makeRoom(int pixels) {
    while (_pixelCount + pixels > _pixelBudget) {
      final entry = _images.remove(_images.keys.first)!;
      _pixelCount -= entry.image.width * entry.image.height;
      entry.image.dispose();
    }
  }
}
