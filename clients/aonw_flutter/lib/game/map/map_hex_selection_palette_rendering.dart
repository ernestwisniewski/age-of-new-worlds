part of 'map_hex_selection_palette_layer.dart';

extension _MapHexSelectionPaletteRendering
    on MapHexSelectionPaletteLayerComponent {
  void _paintPalette(
    ui.Canvas canvas,
    MapHexSelectionPaletteView view,
    ui.Offset center,
  ) {
    _paintHalo(canvas, center);
    final connector = ui.Paint()
      ..color = AonwColorTokens.brand.withAlpha(116)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2 * _screenScale;
    for (final rect in _targetRects) {
      canvas.drawLine(
        center,
        ui.Offset.lerp(center, rect.center, 0.72)!,
        connector,
      );
    }
    for (var index = 0; index < view.targets.length; index += 1) {
      _paintTarget(canvas, view.targets[index], _targetRects[index]);
    }
  }

  void _paintHalo(ui.Canvas canvas, ui.Offset center) {
    final bounds = ui.Rect.fromCenter(
      center: center,
      width: MapHexSelectionPaletteLayerComponent._haloWidth * _screenScale,
      height: MapHexSelectionPaletteLayerComponent._haloHeight * _screenScale,
    );
    final path = MapSpritePainter.flatTopHexPath(bounds);
    canvas
      ..drawPath(path, ui.Paint()..color = AonwColorTokens.brand.withAlpha(34))
      ..drawPath(
        path,
        ui.Paint()
          ..color = AonwColorTokens.brand.withAlpha(238)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2.5 * _screenScale,
      );
  }

  void _paintTarget(
    ui.Canvas canvas,
    MapHexSelectionTargetView target,
    ui.Rect rect,
  ) {
    final radius =
        MapHexSelectionPaletteLayerComponent.buttonRadius * _screenScale;
    canvas
      ..drawCircle(
        rect.center + ui.Offset(0, 3 * _screenScale),
        radius + 2 * _screenScale,
        ui.Paint()..color = AonwColorTokens.background.withAlpha(104),
      )
      ..drawCircle(
        rect.center,
        radius,
        ui.Paint()..color = AonwColorTokens.surfaceDeep.withAlpha(244),
      )
      ..drawCircle(
        rect.center,
        radius,
        ui.Paint()
          ..color = AonwColorTokens.brand.withAlpha(238)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2.5 * _screenScale,
      );
    _paintIcon(canvas, target, rect.center);
  }

  void _paintIcon(
    ui.Canvas canvas,
    MapHexSelectionTargetView target,
    ui.Offset center,
  ) {
    final icon = _iconFor(target);
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: AonwColorTokens.brandLight,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: 25 * _screenScale,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - ui.Offset(painter.width / 2, painter.height / 2),
    );
  }

  IconData _iconFor(MapHexSelectionTargetView target) => switch (target) {
    TerrainHexSelectionTargetView() => Icons.landscape_outlined,
    UnitHexSelectionTargetView() => Icons.shield_outlined,
    CityHexSelectionTargetView() => Icons.location_city_outlined,
    FieldImprovementHexSelectionTargetView() => Icons.construction_outlined,
    ArtifactHexSelectionTargetView() => Icons.diamond_outlined,
    ObjectiveHexSelectionTargetView() => Icons.flag_outlined,
  };
}
