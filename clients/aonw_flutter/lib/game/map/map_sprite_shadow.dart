import 'dart:ui' as ui;

/// The three shared shadow passes used by unit sprites and fallbacks.
abstract final class MapSpriteShadow {
  static final _castPaint = _paint(alpha: 34, blur: 7.4);
  static final _ambientPaint = _paint(alpha: 54, blur: 4.6);
  static final _contactPaint = _paint(alpha: 94, blur: 1.68);

  static void paintUnit(
    ui.Canvas canvas, {
    required ui.Offset center,
    required bool compact,
  }) {
    final rect = ui.Rect.fromCenter(
      center: center.translate(0, compact ? 7 : 9),
      width: compact ? 18 : 24,
      height: compact ? 6 : 8,
    );
    canvas
      ..drawOval(
        ui.Rect.fromCenter(
          center: rect.center.translate(rect.width * 0.16, rect.height * 0.22),
          width: rect.width * 1.42,
          height: rect.height * 1.28,
        ),
        _castPaint,
      )
      ..drawOval(rect.inflate(rect.height * 0.16), _ambientPaint)
      ..drawOval(
        ui.Rect.fromCenter(
          center: rect.center.translate(0, rect.height * 0.14),
          width: rect.width * 0.62,
          height: rect.height * 0.45,
        ),
        _contactPaint,
      );
  }

  static ui.Paint _paint({required int alpha, required double blur}) =>
      ui.Paint()
        ..color = const ui.Color(0xff000000).withAlpha(alpha)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, blur);
}
