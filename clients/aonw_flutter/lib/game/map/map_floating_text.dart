import 'dart:ui' as ui;

import 'package:flutter/animation.dart';

import '../../features/map/read_model/map_feedback_view.dart';
import 'map_canvas_clip.dart';
import 'map_floating_text_image.dart';

final class MapFloatingText {
  final _raster = MapFloatingTextImage();
  final _paint = ui.Paint()..filterQuality = ui.FilterQuality.medium;
  MapFloatingTextCueView? cue;
  ui.Offset? _position;
  double _elapsed = 0;

  bool get active => cue != null;
  bool get ready => active && _elapsed >= 0;
  bool get placed => _position != null;
  bool get hasImage => _raster.image != null;
  ui.Offset? get position => _position;

  void start(MapFloatingTextCueView cue, String label) {
    this.cue = cue;
    _elapsed = -cue.delay.inMicroseconds / Duration.microsecondsPerSecond;
    _position = null;
    relabel(label);
  }

  void relabel(String label) {
    final value = cue;
    if (value != null) _raster.setText(label, value.colorValue, value.style);
  }

  void place(ui.Offset position) => _position = position;

  void update(double dt) {
    final value = cue;
    if (value == null) return;
    _elapsed += dt;
    if (_elapsed >=
        (value.style == MapFloatingTextStyleView.bubble ? 3.7 : 1.08)) {
      cue = null;
      _position = null;
    }
  }

  void clear() {
    cue = null;
    _position = null;
    _raster.dispose();
  }

  bool render(ui.Canvas canvas, {required bool reducedMotion}) {
    final value = cue;
    final image = _raster.image;
    final position = _position;
    if (!ready || value == null || image == null || position == null) {
      return false;
    }
    final (rise, opacity) = _motion(value.style, reducedMotion);
    final origin = position.translate(
      -_raster.size.width / 2 - MapFloatingTextImage.padding,
      -_raster.size.height / 2 - MapFloatingTextImage.padding + rise,
    );
    final bounds =
        origin &
        ui.Size(
          image.width / MapFloatingTextImage.scale,
          image.height / MapFloatingTextImage.scale,
        );
    if (opacity == 0 || !mapCanvasClipBounds(canvas).overlaps(bounds)) {
      return false;
    }
    _paint.color = const ui.Color(0xffffffff).withValues(alpha: opacity);
    canvas
      ..save()
      ..translate(origin.dx, origin.dy)
      ..scale(1 / MapFloatingTextImage.scale)
      ..drawImage(image, ui.Offset.zero, _paint)
      ..restore();
    return true;
  }

  (double, double) _motion(MapFloatingTextStyleView style, bool reducedMotion) {
    if (reducedMotion) return (0, 1);
    final bubble = style == MapFloatingTextStyleView.bubble;
    final progress = (_elapsed / (bubble ? 3.05 : 1.05)).clamp(0.0, 1.0);
    final rise = (bubble ? -24 : -34) * Curves.easeOutCubic.transform(progress);
    final opacity =
        (1 - (_elapsed - (bubble ? 2.05 : 0.45)) / (bubble ? 1.45 : 0.55))
            .clamp(0.0, 1.0);
    return (rise, opacity);
  }
}
