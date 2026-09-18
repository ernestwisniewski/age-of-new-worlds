part of 'city_founding_preview_layer.dart';

final _foundingBadgeGlow = ui.Paint()
  ..color = AonwColorTokens.info.withAlpha(90)
  ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);

extension _MapCityFoundingPreviewRendering
    on MapCityFoundingPreviewLayerComponent {
  void _renderFoundingPreview(ui.Canvas canvas) {
    final clip = mapCanvasClipBounds(canvas);
    for (final candidate in _candidates) {
      if (!clip.overlaps(candidate.bounds)) continue;
      _renderedHexCount += 1;
      final accent = candidate.recommended ? AonwColorTokens.info : _cityColor;
      canvas.drawPath(
        candidate.path,
        _fillPaint..color = accent.withAlpha(candidate.recommended ? 90 : 30),
      );
      if (candidate.recommended) {
        _drawDashedPath(
          canvas,
          candidate.metrics,
          _stroke(accent, alpha: 90, width: 5),
        );
        _drawDashedPath(
          canvas,
          candidate.metrics,
          _stroke(accent, alpha: 245, width: 2.8),
        );
        _paintRecommendedBadge(canvas, candidate.center);
      } else {
        _drawDashedPath(
          canvas,
          candidate.metrics,
          _stroke(accent, alpha: 220, width: 2),
        );
      }
    }

    for (final selected in _selected) {
      if (!clip.overlaps(selected.bounds)) continue;
      _renderedHexCount += 1;
      canvas.drawPath(
        selected.path,
        _fillPaint..color = _cityColor.withAlpha(130),
      );
      _drawDashedPath(
        canvas,
        selected.metrics,
        _stroke(AonwColorTokens.textBright, alpha: 60, width: 5),
      );
      _drawDashedPath(
        canvas,
        selected.metrics,
        _stroke(AonwColorTokens.textBright, alpha: 245, width: 2.8),
      );
    }

    final centerPath = _centerPath;
    final center = _center;
    if (centerPath == null || center == null) return;
    if (!clip.overlaps(_centerBounds!)) return;
    _renderedHexCount += 1;
    canvas
      ..drawPath(centerPath, _fillPaint..color = _cityColor.withAlpha(90))
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
  }) => _strokePaint
    ..color = color.withAlpha(alpha)
    ..strokeWidth = width;

  void _drawDashedPath(
    ui.Canvas canvas,
    List<ui.PathMetric> metrics,
    ui.Paint paint,
  ) {
    for (final metric in metrics) {
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
      ..drawCircle(badgeCenter, 10, _foundingBadgeGlow)
      ..drawCircle(
        badgeCenter,
        7,
        _fillPaint..color = AonwColorTokens.surfaceDeep.withAlpha(245),
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

  ui.Paragraph _buildCountParagraph() {
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
    return paragraph;
  }

  ui.RRect _countLabelRect(ui.Offset center) {
    final paragraph = _countParagraph!;
    return ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(
        center.dx + 14,
        center.dy - 32,
        paragraph.maxIntrinsicWidth + 14,
        paragraph.height + 8,
      ),
      const ui.Radius.circular(6),
    );
  }

  void _paintCountLabel(ui.Canvas canvas, ui.Offset center) {
    final paragraph = _countParagraph!;
    final rect = _countLabelRect(center);
    canvas
      ..drawRRect(
        rect,
        _fillPaint..color = AonwColorTokens.background.withAlpha(220),
      )
      ..drawParagraph(paragraph, ui.Offset(rect.left + 7, rect.top + 4));
  }
}
