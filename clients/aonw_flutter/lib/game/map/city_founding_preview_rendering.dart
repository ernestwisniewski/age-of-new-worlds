part of 'city_founding_preview_layer.dart';

extension _MapCityFoundingPreviewRendering
    on MapCityFoundingPreviewLayerComponent {
  void _renderFoundingPreview(ui.Canvas canvas) {
    for (final candidate in _candidates) {
      final accent = candidate.recommended ? AonwColorTokens.info : _cityColor;
      canvas.drawPath(
        candidate.path,
        ui.Paint()..color = accent.withAlpha(candidate.recommended ? 90 : 30),
      );
      if (candidate.recommended) {
        _drawDashedPath(
          canvas,
          candidate.path,
          _stroke(accent, alpha: 90, width: 5),
        );
        _drawDashedPath(
          canvas,
          candidate.path,
          _stroke(accent, alpha: 245, width: 2.8),
        );
        _paintRecommendedBadge(canvas, candidate.center);
      } else {
        _drawDashedPath(
          canvas,
          candidate.path,
          _stroke(accent, alpha: 220, width: 2),
        );
      }
    }

    for (final selected in _selected) {
      canvas.drawPath(
        selected.path,
        ui.Paint()..color = _cityColor.withAlpha(130),
      );
      _drawDashedPath(
        canvas,
        selected.path,
        _stroke(AonwColorTokens.textBright, alpha: 60, width: 5),
      );
      _drawDashedPath(
        canvas,
        selected.path,
        _stroke(AonwColorTokens.textBright, alpha: 245, width: 2.8),
      );
    }

    final centerPath = _centerPath;
    final center = _center;
    if (centerPath == null || center == null) return;
    canvas
      ..drawPath(centerPath, ui.Paint()..color = _cityColor.withAlpha(90))
      ..drawPath(
        centerPath,
        _stroke(AonwColorTokens.textBright, alpha: 220, width: 2),
      );
    _paintCountLabel(canvas, center);
  }

  ui.Paint _stroke(
    ui.Color color, {
    required int alpha,
    required double width,
  }) => ui.Paint()
    ..color = color.withAlpha(alpha)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round;

  void _drawDashedPath(ui.Canvas canvas, ui.Path path, ui.Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = -_dashPhase;
      while (distance < metric.length) {
        final start = distance.clamp(0.0, metric.length);
        final end = (distance + MapCityFoundingPreviewLayerComponent.dashLength)
            .clamp(0.0, metric.length);
        if (end > start) canvas.drawPath(metric.extractPath(start, end), paint);
        distance += MapCityFoundingPreviewLayerComponent.dashPattern;
      }
    }
  }

  void _paintRecommendedBadge(ui.Canvas canvas, ui.Offset center) {
    final badgeCenter = center + const ui.Offset(0, -3);
    canvas
      ..drawCircle(
        badgeCenter,
        10,
        ui.Paint()
          ..color = AonwColorTokens.info.withAlpha(90)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4),
      )
      ..drawCircle(
        badgeCenter,
        7,
        ui.Paint()..color = AonwColorTokens.surfaceDeep.withAlpha(245),
      )
      ..drawCircle(
        badgeCenter,
        7,
        _stroke(AonwColorTokens.info, alpha: 245, width: 1.5),
      );
    final glyph = ui.Path()
      ..moveTo(badgeCenter.dx - 3.5, badgeCenter.dy + 3)
      ..lineTo(badgeCenter.dx - 3.5, badgeCenter.dy - 1)
      ..lineTo(badgeCenter.dx, badgeCenter.dy - 4)
      ..lineTo(badgeCenter.dx + 3.5, badgeCenter.dy - 1)
      ..lineTo(badgeCenter.dx + 3.5, badgeCenter.dy + 3)
      ..moveTo(badgeCenter.dx - 5, badgeCenter.dy + 3)
      ..lineTo(badgeCenter.dx + 5, badgeCenter.dy + 3);
    canvas.drawPath(
      glyph,
      _stroke(AonwColorTokens.textBright, alpha: 245, width: 1.5),
    );
  }

  void _paintCountLabel(ui.Canvas canvas, ui.Offset center) {
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              fontFamily: AonwTypography.bodyFamily,
              fontSize: 11,
              fontWeight: ui.FontWeight.w900,
              maxLines: 1,
            ),
          )
          ..pushStyle(ui.TextStyle(color: AonwColorTokens.textBright))
          ..addText(_label);
    final paragraph = builder.build()
      ..layout(const ui.ParagraphConstraints(width: 52));
    const paddingX = 7.0;
    const paddingY = 4.0;
    final rect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(
        center.dx + 14,
        center.dy - 32,
        paragraph.maxIntrinsicWidth + paddingX * 2,
        paragraph.height + paddingY * 2,
      ),
      const ui.Radius.circular(6),
    );
    canvas
      ..drawRRect(
        rect,
        ui.Paint()..color = AonwColorTokens.background.withAlpha(220),
      )
      ..drawParagraph(
        paragraph,
        ui.Offset(rect.left + paddingX, rect.top + paddingY),
      );
  }
}
