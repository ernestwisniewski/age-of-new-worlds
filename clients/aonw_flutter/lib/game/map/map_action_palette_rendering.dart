part of 'map_action_palette_layer.dart';

extension _MapActionPaletteRendering on MapActionPaletteLayerComponent {
  void _paintMovePill(ui.Canvas canvas, MapMovePreviewPillView view) {
    final bounds = _bounds;
    if (bounds == null) return;
    final panel = ui.Rect.fromLTWH(
      bounds.left,
      bounds.top + 2,
      bounds.width,
      MapActionPaletteLayerComponent._pillPanelHeight,
    );
    final accent = view.warning
        ? AonwColorTokens.warning
        : AonwColorTokens.brandLight;
    final pointer = ui.Path()
      ..moveTo(panel.center.dx - 6, panel.bottom - 0.5)
      ..lineTo(panel.center.dx + 6, panel.bottom - 0.5)
      ..lineTo(panel.center.dx, bounds.bottom)
      ..close();
    final rounded = ui.RRect.fromRectAndRadius(
      panel,
      const ui.Radius.circular(7),
    );
    final shadow = ui.Paint()
      ..color = const ui.Color(0x36000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5);
    final glow = ui.Paint()
      ..color = accent.withAlpha(view.enabled ? 36 : 18)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5);
    final surface = ui.Paint()
      ..color = const ui.Color(0xF0101620).withAlpha(view.enabled ? 160 : 110);
    final border = ui.Paint()
      ..color = accent.withAlpha(view.enabled ? 112 : 62)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas
      ..drawRRect(rounded.shift(const ui.Offset(0, 2)), shadow)
      ..drawPath(pointer.shift(const ui.Offset(0, 2)), shadow)
      ..drawRRect(rounded.inflate(1.5), glow)
      ..drawPath(pointer, glow)
      ..drawRRect(rounded, surface)
      ..drawPath(pointer, surface)
      ..drawRRect(rounded, border)
      ..drawPath(pointer, border);
    _paintMoveGlyph(canvas, ui.Offset(panel.left + 9, panel.center.dy), accent);
    _paintText(
      canvas,
      view.label,
      ui.Rect.fromLTRB(
        panel.left + 25,
        panel.top,
        panel.right - 7,
        panel.bottom,
      ),
      const TextStyle(
        color: AonwColorTokens.textBright,
        fontFamily: AonwTypography.bodyFamily,
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
      ),
      centerVertically: true,
    );
  }

  void _paintWorkerPalette(ui.Canvas canvas, MapWorkerActionPaletteView view) {
    final bounds = _bounds;
    if (bounds == null) return;
    final bar = ui.Rect.fromLTWH(
      bounds.left,
      bounds.top,
      bounds.width,
      MapActionPaletteLayerComponent.iconSize +
          MapActionPaletteLayerComponent.barPaddingY * 2,
    );
    _paintSurface(
      canvas,
      bar,
      radius: MapActionPaletteLayerComponent.barRadius,
      alpha: 224,
    );
    for (var index = 0; index < view.options.length; index += 1) {
      _paintWorkerOption(canvas, view, index);
    }
    _paintWorkerPreview(canvas, view);
  }

  void _paintWorkerOption(
    ui.Canvas canvas,
    MapWorkerActionPaletteView view,
    int index,
  ) {
    final option = view.options[index];
    final rect = _optionRects[index];
    final selected = option.improvement == view.previewedImprovement;
    final fill = ui.Paint()
      ..color = selected
          ? AonwColorTokens.brand.withAlpha(58)
          : AonwColorTokens.info.withAlpha(34);
    final border = ui.Paint()
      ..color = selected
          ? AonwColorTokens.brandLight.withAlpha(190)
          : AonwColorTokens.textSecondary.withAlpha(112)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = selected ? 1.6 : 1;
    final rounded = ui.RRect.fromRectAndRadius(
      rect,
      const ui.Radius.circular(7),
    );
    canvas
      ..drawRRect(rounded, fill)
      ..drawRRect(rounded, border);
    final frame = _framesScope.cached(
      MapSpriteCatalog.improvementFrame(option.improvement),
    );
    if (frame == null) {
      _paintWorkerGlyph(canvas, rect.center);
    } else {
      MapSpritePainter.paint(canvas, frame, destination: rect.deflate(5));
    }
  }

  void _paintWorkerPreview(ui.Canvas canvas, MapWorkerActionPaletteView view) {
    final previewed = view.previewedImprovement;
    final panel = _previewPanelRect;
    if (previewed == null || panel == null) return;
    _paintSurface(canvas, panel, radius: 8, alpha: 210);
    final option = view.options.firstWhere(
      (candidate) => candidate.improvement == previewed,
    );
    _paintText(
      canvas,
      option.label,
      ui.Rect.fromLTRB(
        panel.left + 8,
        panel.top + 6,
        panel.right - 8,
        panel.top + 28,
      ),
      const TextStyle(
        color: AonwColorTokens.textBright,
        fontFamily: AonwTypography.bodyFamily,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
    _paintText(
      canvas,
      option.turnLabel,
      ui.Rect.fromLTRB(
        panel.left + 8,
        panel.bottom - 31,
        panel.center.dx,
        panel.bottom - 7,
      ),
      AonwTextStyles.chipLabel.copyWith(color: AonwColorTokens.textMuted),
      centerVertically: true,
    );
    _paintWorkerCta(canvas, view);
  }

  void _paintWorkerCta(ui.Canvas canvas, MapWorkerActionPaletteView view) {
    final cta = _ctaRect;
    if (cta == null) return;
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(cta, const ui.Radius.circular(6)),
      ui.Paint()
        ..color = view.enabled
            ? AonwColorTokens.brand
            : AonwColorTokens.brandDark.withAlpha(120),
    );
    _paintText(
      canvas,
      view.confirmLabel,
      cta.deflate(4),
      AonwTextStyles.actionLabel.copyWith(color: AonwColorTokens.background),
      center: true,
      centerVertically: true,
    );
  }

  void _paintSurface(
    ui.Canvas canvas,
    ui.Rect rect, {
    required double radius,
    required int alpha,
  }) {
    final rounded = ui.RRect.fromRectAndRadius(
      rect,
      ui.Radius.circular(radius),
    );
    canvas
      ..drawRRect(
        rounded,
        ui.Paint()..color = AonwColorTokens.surface.withAlpha(alpha),
      )
      ..drawRRect(
        rounded,
        ui.Paint()
          ..color = AonwColorTokens.brandLight.withAlpha(132)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1,
      );
  }

  void _paintText(
    ui.Canvas canvas,
    String text,
    ui.Rect bounds,
    TextStyle style, {
    bool center = false,
    bool centerVertically = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      ellipsis: '…',
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: bounds.width);
    painter.paint(
      canvas,
      ui.Offset(
        center ? bounds.center.dx - painter.width / 2 : bounds.left,
        centerVertically ? bounds.center.dy - painter.height / 2 : bounds.top,
      ),
    );
  }

  void _paintMoveGlyph(ui.Canvas canvas, ui.Offset center, ui.Color color) {
    final paint = ui.Paint()
      ..color = color
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = ui.StrokeCap.round
      ..strokeJoin = ui.StrokeJoin.round;
    canvas.drawPath(
      ui.Path()
        ..moveTo(center.dx, center.dy - 5)
        ..lineTo(center.dx + 5, center.dy)
        ..lineTo(center.dx, center.dy + 5)
        ..moveTo(center.dx + 5, center.dy)
        ..lineTo(center.dx - 5, center.dy),
      paint,
    );
  }

  void _paintWorkerGlyph(ui.Canvas canvas, ui.Offset center) {
    final paint = ui.Paint()
      ..color = AonwColorTokens.brandLight
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = ui.StrokeCap.round;
    canvas
      ..drawLine(center.translate(-7, 7), center.translate(5, -5), paint)
      ..drawLine(center.translate(1, -9), center.translate(9, -1), paint)
      ..drawLine(center.translate(-10, 5), center.translate(-5, 10), paint);
  }

  double _measurePillWidth(String label) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontFamily: AonwTypography.bodyFamily,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      maxLines: 1,
      textDirection: ui.TextDirection.ltr,
    )..layout();
    return (painter.width + 42)
        .clamp(
          MapActionPaletteLayerComponent._pillMinWidth,
          MapActionPaletteLayerComponent._pillMaxWidth,
        )
        .toDouble();
  }
}
