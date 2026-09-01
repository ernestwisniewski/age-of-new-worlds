import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../features/map/application/map_interaction_state.dart';
import '../../features/map/presentation/map_palette.dart';
import '../../features/map/read_model/map_view.dart';
import '../../features/map/read_model/player_map_view.dart';
import 'map_interaction_geometry.dart';
import 'static_map_layers.dart';

enum MapHoverMarkerKind { move, attack }

final class MapSelectionLayerComponent extends Component with HasVisibility {
  MapSelectionLayerComponent() : super(priority: 60) {
    isVisible = false;
  }

  static const _selectionDashLength = 6.0;
  static const _selectionGapLength = 4.0;
  static final _selectionGlowPaint = ui.Paint()
    ..color = MapPalette.selectionGlow
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 8
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3.4);
  static final _selectionBackingPaint = ui.Paint()
    ..color = MapPalette.selectionBacking
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 6
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round;
  static final _selectionHighlightPaint = ui.Paint()
    ..color = MapPalette.selection
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 3.8
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round;
  static final _moveGlowPaint = ui.Paint()
    ..color = MapPalette.moveHoverGlow
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 5
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.8);
  static final _moveLinePaint = ui.Paint()
    ..color = MapPalette.route
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round;
  static final _moveHaloPaint = ui.Paint()
    ..color = MapPalette.moveHoverHalo
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
  static final _moveDotPaint = ui.Paint()..color = MapPalette.route;
  static final _attackFillPaint = ui.Paint()
    ..color = MapPalette.attackHoverFill;
  static final _attackGlowPaint = ui.Paint()
    ..color = MapPalette.attackHoverGlow
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 5
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round;
  static final _attackLinePaint = ui.Paint()
    ..color = MapPalette.attackHoverLine
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2.8
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round;
  static final _badgeShadowPaint = ui.Paint()
    ..color = MapPalette.intentBadgeShadow;
  static final _badgeFillPaint = ui.Paint()..color = MapPalette.intentBadgeFill;
  static final _badgeBorderPaint = ui.Paint()
    ..color = MapPalette.intentBadgeBorder
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final _badgeHighlightPaint = ui.Paint()
    ..color = MapPalette.intentBadgeHighlight
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1;
  static final _badgeGlyphPaint = ui.Paint()
    ..color = MapPalette.intentBadgeGlyph
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.8
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round;

  MapInteractionState? _interaction;
  PlayerMapView? _player;
  MapHexCoordinate? _cursor;
  MapStaticRenderCache? _cache;
  List<ui.Offset>? _selectionCorners;
  ui.Path? _selectionPath;
  ui.Path? _hoverPath;
  ui.Offset? _hoverCenter;
  MapHoverMarkerKind? _hoverIntent;
  var _updateCount = 0;
  var _cursorUpdateCount = 0;

  @visibleForTesting
  int get debugUpdateCount => _updateCount;

  @visibleForTesting
  int get debugCursorUpdateCount => _cursorUpdateCount;

  @visibleForTesting
  MapHoverMarkerKind? get debugHoverIntent => _hoverIntent;

  @visibleForTesting
  ui.Rect? get debugSelectionBounds => _selectionPath?.getBounds();

  void applySelection(
    MapStaticRenderCache cache,
    MapInteractionState interaction,
    PlayerMapView player,
  ) {
    if (identical(_interaction, interaction) && identical(_player, player)) {
      return;
    }
    _interaction = interaction;
    _player = player;
    _cache = cache;
    final selected = interaction.selected;
    _selectionCorners = selected == null
        ? null
        : mapProjectedTopFaceCorners(cache, selected);
    _selectionPath = selected == null
        ? null
        : mapProjectedTopFacePath(cache, selected);
    _syncHover();
    _updateCount += 1;
    _refreshVisibility();
  }

  void applyCursor(MapStaticRenderCache cache, MapHexCoordinate? coordinate) {
    if (_cursor == coordinate && identical(_cache, cache)) return;
    _cursor = coordinate;
    _cache = cache;
    _syncHover();
    _cursorUpdateCount += 1;
    _refreshVisibility();
  }

  void clearLayer() {
    _interaction = null;
    _player = null;
    _cursor = null;
    _cache = null;
    _selectionCorners = null;
    _selectionPath = null;
    _hoverPath = null;
    _hoverCenter = null;
    _hoverIntent = null;
    isVisible = false;
  }

  void _syncHover() {
    final cache = _cache;
    final coordinate = _cursor;
    final interaction = _interaction;
    final player = _player;
    if (cache == null ||
        coordinate == null ||
        interaction == null ||
        player == null ||
        interaction.selectedUnitId == null) {
      _clearHover();
      return;
    }
    final hasForeignUnit = player
        .unitsAt(coordinate)
        .any((unit) => unit.ownerPlayerId != player.actorPlayerId);
    final city = player.cityAt(coordinate);
    final hasForeignCity =
        city != null && city.ownerPlayerId != player.actorPlayerId;
    final moveTarget =
        interaction.reachable?.tileAt(coordinate) != null ||
        interaction.route?.target == coordinate;
    final intent = hasForeignUnit || hasForeignCity
        ? MapHoverMarkerKind.attack
        : moveTarget
        ? MapHoverMarkerKind.move
        : null;
    if (intent == null) {
      _clearHover();
      return;
    }
    _hoverIntent = intent;
    _hoverPath = mapProjectedTopFacePath(cache, coordinate, scale: 0.9);
    _hoverCenter = mapProjectedTopFaceCenter(cache, coordinate);
  }

  void _clearHover() {
    _hoverPath = null;
    _hoverCenter = null;
    _hoverIntent = null;
  }

  void _refreshVisibility() {
    isVisible = _selectionPath != null || _hoverPath != null;
  }

  @override
  void render(ui.Canvas canvas) {
    final selection = _selectionPath;
    final corners = _selectionCorners;
    if (selection != null && corners != null) {
      _paintDashedPolygon(canvas, corners, _selectionGlowPaint);
      _paintDashedPolygon(canvas, corners, _selectionBackingPaint);
      _paintDashedPolygon(canvas, corners, _selectionHighlightPaint);
    }
    final hover = _hoverPath;
    final center = _hoverCenter;
    if (hover == null || center == null) return;
    switch (_hoverIntent) {
      case MapHoverMarkerKind.move:
        canvas
          ..drawPath(hover, _moveGlowPaint)
          ..drawPath(hover, _moveLinePaint)
          ..drawCircle(center, 7, _moveHaloPaint)
          ..drawCircle(center, 3.2, _moveDotPaint);
      case MapHoverMarkerKind.attack:
        canvas
          ..drawPath(hover, _attackFillPaint)
          ..drawPath(hover, _attackGlowPaint)
          ..drawPath(hover, _attackLinePaint);
        _paintAttackBadge(canvas, center);
      case null:
        break;
    }
  }
}

void _paintDashedPolygon(
  ui.Canvas canvas,
  List<ui.Offset> corners,
  ui.Paint paint,
) {
  for (var index = 0; index < corners.length; index += 1) {
    _paintDashedLine(
      canvas,
      corners[index],
      corners[(index + 1) % corners.length],
      paint,
    );
  }
}

void _paintDashedLine(
  ui.Canvas canvas,
  ui.Offset from,
  ui.Offset to,
  ui.Paint paint,
) {
  final delta = to - from;
  final length = delta.distance;
  if (length <= 0) return;
  final direction = delta / length;
  var distance = 0.0;
  var drawing = true;
  while (distance < length) {
    final segment = drawing
        ? MapSelectionLayerComponent._selectionDashLength
        : MapSelectionLayerComponent._selectionGapLength;
    final end = math.min(distance + segment, length);
    if (drawing) {
      canvas.drawLine(
        from + direction * distance,
        from + direction * end,
        paint,
      );
    }
    distance = end;
    drawing = !drawing;
  }
}

void _paintAttackBadge(ui.Canvas canvas, ui.Offset center) {
  const size = 24.0;
  final rect = ui.RRect.fromRectAndRadius(
    ui.Rect.fromCenter(center: center, width: size, height: size),
    const ui.Radius.circular(size * 0.38),
  );
  canvas
    ..drawRRect(
      ui.RRect.fromRectAndRadius(
        rect.outerRect.inflate(3),
        const ui.Radius.circular(size * 0.5),
      ),
      ui.Paint()
        ..color = MapPalette.attackBadgeGlow
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4),
    )
    ..drawRRect(
      rect.shift(const ui.Offset(0, 1.5)),
      MapSelectionLayerComponent._badgeShadowPaint,
    )
    ..drawRRect(rect, MapSelectionLayerComponent._badgeFillPaint)
    ..drawRRect(rect, MapSelectionLayerComponent._badgeBorderPaint)
    ..drawRRect(
      rect.deflate(1.4),
      MapSelectionLayerComponent._badgeHighlightPaint,
    )
    ..drawLine(
      center.translate(-4.2, 0),
      center.translate(4.2, 0),
      MapSelectionLayerComponent._badgeGlyphPaint,
    )
    ..drawLine(
      center.translate(0, -4.2),
      center.translate(0, 4.2),
      MapSelectionLayerComponent._badgeGlyphPaint,
    )
    ..drawCircle(center, 2.7, MapSelectionLayerComponent._badgeGlyphPaint);
}
