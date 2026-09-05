part of 'city_territory_layer.dart';

extension _CityTerritoryRendering on MapCityTerritoryLayerComponent {
  MapCityTerritoryStyle _styleFor(ui.Color color) {
    final key = (colorValue: color.toARGB32(), strategic: _strategicView);
    return _styleCache.putIfAbsent(
      key,
      () => MapCityTerritoryStyle(color, strategicView: _strategicView),
    );
  }

  void _drawInsetWash(
    ui.Canvas canvas,
    _MapCityTerritory territory,
    MapCityTerritoryStyle style,
  ) {
    canvas
      ..save()
      ..clipPath(territory.boundary, doAntiAlias: true)
      ..drawPath(
        territory.boundary,
        territory.empireHighlighted
            ? style.selectedInsetWashPaint
            : style.insetWashPaint,
      )
      ..restore();
  }

  void _drawBorder(ui.Canvas canvas, _MapCityTerritory territory) {
    final style = _styleFor(territory.playerColor);
    if (!_strategicView) {
      final glow = style.edgeGlowPaint(
        empireHighlighted: territory.empireHighlighted,
        zoomEmphasis: _zoomEmphasis,
      );
      if (_zoomEmphasis >= 0.5) glow.maskFilter = null;
      canvas
        ..drawPath(territory.boundary, glow)
        ..drawPath(
          territory.boundary,
          style.edgeBandPaint(
            empireHighlighted: territory.empireHighlighted,
            zoomEmphasis: _zoomEmphasis,
          ),
        );
    } else {
      _glows.draw(canvas, territory.boundary, style.borderGlowPaint.color);
    }
    canvas
      ..drawPath(territory.boundary, style.outerBorderPaint)
      ..drawPath(territory.boundary, style.solidBorderPaint)
      ..drawPath(territory.boundary, style.atlasInkBorderPaint)
      ..drawPath(
        territory.boundary,
        style.innerBorderHighlightPaint(_zoomEmphasis),
      );
  }

  void _drawStrategicCenter(ui.Canvas canvas, _MapCityTerritory territory) {
    final style = _styleFor(territory.playerColor);
    final center = territory.centerPath.getBounds().center;
    _glows.draw(
      canvas,
      territory.centerPath,
      style.strategicCenterGlowPaint.color,
    );
    canvas
      ..drawPath(territory.centerPath, mapCityTerritoryCenterFillPaint)
      ..drawPath(territory.centerPath, mapCityTerritoryCenterBorderPaint)
      ..drawPath(territory.centerPath, style.strategicCenterInnerPaint);
    MapCityTerritoryLayerComponent._drawCityGlyph(canvas, center);
  }

  void _drawMapDimming(ui.Canvas canvas) {
    final path = ui.Path()
      ..fillType = ui.PathFillType.evenOdd
      ..addRect(const ui.Rect.fromLTRB(-100000, -100000, 100000, 100000));
    for (final territory in _territories) {
      if (territory.empireHighlighted) {
        path.addPath(territory.boundary, ui.Offset.zero);
      }
    }
    canvas.drawPath(path, mapCityTerritoryDimmingPaint);
  }

  void _drawSelectedBorder(ui.Canvas canvas, _MapCityTerritory territory) {
    final style = _styleFor(territory.playerColor);
    _drawDashedPath(
      canvas,
      territory.boundary,
      style.selectedBorderGlowPaint(_zoomEmphasis),
    );
    _drawDashedPath(
      canvas,
      territory.boundary,
      style.selectedBorderBackingPaint,
    );
    _drawDashedPath(
      canvas,
      territory.boundary,
      style.selectedPlayerBorderPaint(_zoomEmphasis),
    );
  }

  void _drawDashedPath(ui.Canvas canvas, ui.Path path, ui.Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 12).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + 7;
      }
    }
  }
}
