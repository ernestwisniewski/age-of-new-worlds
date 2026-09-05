import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../design_system/aonw_tokens.dart';
import '../../features/map/read_model/map_feedback_view.dart';

/// A bounded slot caches its text and decoration as one raster image.
final class MapFloatingTextImage {
  static const scale = 3.0;
  static const padding = 10.0;
  ui.Image? image;
  ui.Size size = ui.Size.zero;
  (String, int, MapFloatingTextStyleView)? _key;

  void setText(String text, int colorValue, MapFloatingTextStyleView style) {
    final key = (text, colorValue, style);
    if (_key == key) return;
    dispose();
    _key = key;
    final bubble = style == MapFloatingTextStyleView.bubble;
    final color = ui.Color(colorValue);
    final painter = TextPainter(
      text: TextSpan(text: text, style: _textStyle(color, bubble)),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
      maxLines: bubble ? 2 : 1,
      ellipsis: '...',
    )..layout(maxWidth: bubble ? 136 : 320);
    size = ui.Size(
      bubble ? (painter.width + 20).clamp(68.0, 156.0) : painter.width,
      painter.height + (bubble ? 10 : 0),
    );
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)
      ..scale(scale)
      ..translate(padding + size.width / 2, padding + size.height / 2);
    if (bubble) _drawBubble(canvas, size, color);
    painter.paint(canvas, ui.Offset(-painter.width / 2, -painter.height / 2));
    final picture = recorder.endRecording();
    image = picture.toImageSync(
      ((size.width + padding * 2) * scale).ceil(),
      ((size.height + padding * 2) * scale).ceil(),
    );
    picture.dispose();
    painter.dispose();
  }

  void dispose() {
    image?.dispose();
    image = null;
    _key = null;
    size = ui.Size.zero;
  }
}

TextStyle _textStyle(ui.Color color, bool bubble) => TextStyle(
  color: bubble ? AonwColorTokens.brandLight : color,
  fontFamily: bubble ? AonwTypography.headingFamily : AonwTypography.bodyFamily,
  fontSize: bubble ? 10.5 : 15,
  height: bubble ? 1 : null,
  fontWeight: bubble ? ui.FontWeight.w700 : ui.FontWeight.w900,
  shadows: [
    ui.Shadow(
      color: const ui.Color(0xbf000000),
      offset: ui.Offset(0, bubble ? 1 : 1.5),
      blurRadius: bubble ? 2.5 : 3,
    ),
  ],
);

void _drawBubble(ui.Canvas canvas, ui.Size size, ui.Color color) {
  final rect = ui.Rect.fromCenter(
    center: ui.Offset.zero,
    width: size.width,
    height: size.height,
  );
  final rounded = ui.RRect.fromRectAndRadius(
    rect,
    ui.Radius.circular(rect.height / 2),
  );
  final tail = ui.Path()
    ..moveTo(-5, rect.bottom - 1)
    ..lineTo(5, rect.bottom - 1)
    ..lineTo(0, rect.bottom + 5)
    ..close();
  final shadow = ui.Paint()
    ..color = const ui.Color(0xff000000).withValues(alpha: 0.48)
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
  final fill = ui.Paint()
    ..color = AonwColorTokens.background.withValues(alpha: 0.96);
  final border = ui.Paint()
    ..color = color.withValues(alpha: 0.92)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.05;
  final inner = ui.Paint()
    ..color = AonwColorTokens.brandLight.withValues(alpha: 0.28)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 0.7;
  canvas
    ..drawRRect(rounded.shift(const ui.Offset(0, 1.5)), shadow)
    ..drawRRect(rounded, fill)
    ..drawPath(tail, fill)
    ..drawRRect(rounded, border)
    ..drawPath(tail, border)
    ..drawRRect(rounded.deflate(1.5), inner);
}
