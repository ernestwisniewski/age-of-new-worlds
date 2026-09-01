part of 'city_management_overlay_layer.dart';

enum _YieldBadgeKind { food, production, gold, defense, empty }

final class _YieldBadge {
  const _YieldBadge(this.kind, this.value, this.color);

  final _YieldBadgeKind kind;
  final String value;
  final ui.Color color;
}

extension _MapCityManagementOverlayRendering
    on MapCityManagementOverlayLayerComponent {
  void _renderCityManagement(ui.Canvas canvas) {
    for (final hex in _hexes) {
      final color = _managementColor(hex.kind);
      final detailAlpha = hex.actionable ? 255 : 130;
      canvas
        ..drawPath(
          hex.path,
          ui.Paint()
            ..color = color.withAlpha(
              _visibleAlpha(_managementFillAlpha(hex.kind)) *
                  detailAlpha ~/
                  255,
            ),
        )
        ..drawPath(
          hex.path,
          ui.Paint()
            ..color = color.withAlpha(_visibleAlpha(245) * detailAlpha ~/ 255)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = _managementStrokeWidth(hex.kind)
            ..strokeCap = ui.StrokeCap.round
            ..strokeJoin = ui.StrokeJoin.round,
        );
      if (_dimmed) continue;
      final tileYield = hex.tileYield;
      if (tileYield == null) {
        _drawManagementLabel(canvas, hex, color);
      } else {
        _drawYieldBadges(canvas, hex.center, tileYield, color);
      }
    }
  }

  ui.Color _managementColor(MapCityManagementHexKind kind) => switch (kind) {
    MapCityManagementHexKind.growthRecommended => AonwColorTokens.info,
    MapCityManagementHexKind.growthCandidate => AonwColorTokens.warning,
    MapCityManagementHexKind.workedManual ||
    MapCityManagementHexKind.workedAuto ||
    MapCityManagementHexKind.workedIdle => AonwColorTokens.success,
  };

  int _managementFillAlpha(MapCityManagementHexKind kind) => switch (kind) {
    MapCityManagementHexKind.growthRecommended ||
    MapCityManagementHexKind.growthCandidate ||
    MapCityManagementHexKind.workedAuto => 90,
    MapCityManagementHexKind.workedManual => 130,
    MapCityManagementHexKind.workedIdle => 60,
  };

  double _managementStrokeWidth(MapCityManagementHexKind kind) =>
      switch (kind) {
        MapCityManagementHexKind.growthRecommended ||
        MapCityManagementHexKind.workedManual => 2.8,
        _ => 1.5,
      };

  int _visibleAlpha(int alpha) => _dimmed && alpha > 60 ? 60 : alpha;

  void _drawManagementLabel(
    ui.Canvas canvas,
    _CityManagementHexGeometry hex,
    ui.Color color,
  ) {
    final paragraph = _paragraph(hex.label, fontSize: 9.5, width: 72);
    const paddingX = 6.0;
    const paddingY = 3.0;
    final rect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromCenter(
        center: hex.center + const ui.Offset(0, -3),
        width: paragraph.maxIntrinsicWidth + paddingX * 2,
        height: paragraph.height + paddingY * 2,
      ),
      const ui.Radius.circular(6),
    );
    canvas
      ..drawRRect(
        rect,
        ui.Paint()..color = AonwColorTokens.background.withAlpha(220),
      )
      ..drawRRect(
        rect,
        ui.Paint()
          ..color = color.withAlpha(hex.actionable ? 220 : 130)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1.5,
      )
      ..drawParagraph(
        paragraph,
        ui.Offset(rect.left + paddingX, rect.top + paddingY),
      );
  }

  void _drawYieldBadges(
    ui.Canvas canvas,
    ui.Offset center,
    YieldValueView value,
    ui.Color outlineColor,
  ) {
    final badges = _yieldBadges(value);
    final rows = badges.length <= 2
        ? [badges]
        : [badges.take(2).toList(), badges.skip(2).toList()];
    const badgeHeight = 15.0;
    const gap = 2.5;
    const rowGap = 2.0;
    final rowWidths = [
      for (final row in rows)
        row.fold<double>(0, (sum, badge) => sum + _badgeWidth(badge)) +
            gap * (row.length - 1),
    ];
    final totalHeight = rows.length * badgeHeight + rowGap * (rows.length - 1);
    var top = center.dy - totalHeight / 2 - 3;
    for (var rowIndex = 0; rowIndex < rows.length; rowIndex += 1) {
      final row = rows[rowIndex];
      var left = center.dx - rowWidths[rowIndex] / 2;
      for (final badge in row) {
        final width = _badgeWidth(badge);
        _drawYieldBadge(
          canvas,
          ui.Rect.fromLTWH(left, top, width, badgeHeight),
          badge,
          outlineColor,
        );
        left += width + gap;
      }
      top += badgeHeight + rowGap;
    }
  }

  List<_YieldBadge> _yieldBadges(YieldValueView value) {
    final badges = <_YieldBadge>[
      if (value.food > 0)
        _YieldBadge(
          _YieldBadgeKind.food,
          '${value.food}',
          AonwColorTokens.success,
        ),
      if (value.production > 0)
        _YieldBadge(
          _YieldBadgeKind.production,
          '${value.production}',
          AonwColorTokens.copper,
        ),
      if (value.gold > 0)
        _YieldBadge(
          _YieldBadgeKind.gold,
          '${value.gold}',
          AonwColorTokens.brand,
        ),
      if (value.defense > 0)
        _YieldBadge(
          _YieldBadgeKind.defense,
          '${value.defense}',
          AonwColorTokens.info,
        ),
    ];
    return badges.isEmpty
        ? const [
            _YieldBadge(
              _YieldBadgeKind.empty,
              '0',
              AonwColorTokens.textTertiary,
            ),
          ]
        : badges;
  }

  double _badgeWidth(_YieldBadge badge) => badge.value.length > 1 ? 29 : 24;

  void _drawYieldBadge(
    ui.Canvas canvas,
    ui.Rect rect,
    _YieldBadge badge,
    ui.Color outlineColor,
  ) {
    final rrect = ui.RRect.fromRectAndRadius(rect, const ui.Radius.circular(6));
    final accent = ui.Color.lerp(outlineColor, badge.color, 0.42)!;
    canvas
      ..drawRRect(
        rrect,
        ui.Paint()..color = AonwColorTokens.background.withAlpha(235),
      )
      ..drawRRect(
        rrect,
        ui.Paint()
          ..color = accent.withAlpha(220)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    _drawYieldGlyph(
      canvas,
      badge.kind,
      rect.centerLeft + const ui.Offset(8.2, 0.1),
      AonwColorTokens.brandLight,
    );
    final paragraph = _paragraph(badge.value, fontSize: 8.8, width: 14);
    canvas.drawParagraph(
      paragraph,
      ui.Offset(
        rect.right - 4 - paragraph.maxIntrinsicWidth,
        rect.top + (rect.height - paragraph.height) / 2 - 0.5,
      ),
    );
  }

  void _drawYieldGlyph(
    ui.Canvas canvas,
    _YieldBadgeKind kind,
    ui.Offset center,
    ui.Color color,
  ) {
    final paint = ui.Paint()
      ..color = color
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = ui.StrokeCap.round
      ..strokeJoin = ui.StrokeJoin.round;
    switch (kind) {
      case _YieldBadgeKind.food:
        canvas
          ..drawOval(
            ui.Rect.fromCenter(center: center, width: 5.5, height: 8),
            paint,
          )
          ..drawLine(center, center + const ui.Offset(0, 4), paint);
      case _YieldBadgeKind.production:
        canvas
          ..drawLine(
            center + const ui.Offset(-2.5, -3),
            center + const ui.Offset(2.5, 3),
            paint,
          )
          ..drawLine(
            center + const ui.Offset(-3, -1),
            center + const ui.Offset(-0.5, -3.5),
            paint,
          );
      case _YieldBadgeKind.gold:
        canvas.drawCircle(center, 3.4, paint);
      case _YieldBadgeKind.defense:
        final shield = ui.Path()
          ..moveTo(center.dx, center.dy - 4)
          ..lineTo(center.dx + 3.5, center.dy - 2)
          ..lineTo(center.dx + 2.5, center.dy + 2)
          ..lineTo(center.dx, center.dy + 4)
          ..lineTo(center.dx - 2.5, center.dy + 2)
          ..lineTo(center.dx - 3.5, center.dy - 2)
          ..close();
        canvas.drawPath(shield, paint);
      case _YieldBadgeKind.empty:
        canvas.drawLine(
          center + const ui.Offset(-3, 0),
          center + const ui.Offset(3, 0),
          paint,
        );
    }
  }

  ui.Paragraph _paragraph(
    String text, {
    required double fontSize,
    required double width,
  }) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontFamily: AonwTypography.bodyFamily,
        fontSize: fontSize,
        fontWeight: ui.FontWeight.w900,
        maxLines: 1,
        textAlign: ui.TextAlign.center,
      ),
    )..pushStyle(ui.TextStyle(color: AonwColorTokens.textBright));
    final paragraph = (builder..addText(text)).build()
      ..layout(ui.ParagraphConstraints(width: width));
    return paragraph;
  }
}
