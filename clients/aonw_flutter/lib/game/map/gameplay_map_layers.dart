import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../features/map/application/map_interaction_state.dart';
import '../../features/map/presentation/layers/map_canvas_paths.dart';
import '../../features/map/presentation/map_palette.dart';
import '../../features/map/read_model/map_view.dart';
import '../../features/map/read_model/movement_view.dart';
import 'static_map_layers.dart';
import 'unit_map_layer.dart';

export 'unit_map_layer.dart';

final class MapReachableLayerComponent extends Component with HasVisibility {
  MapReachableLayerComponent() : super(priority: 30) {
    isVisible = false;
  }

  static final ui.Paint _paint = ui.Paint()
    ..color = MapPalette.reachable
    ..style = ui.PaintingStyle.fill;
  ReachableView? _reachable;
  ui.Path? _path;
  var _pathBuildCount = 0;

  @visibleForTesting
  int get debugPathBuildCount => _pathBuildCount;

  void applyReachable(MapStaticRenderCache cache, ReachableView? reachable) {
    if (identical(_reachable, reachable)) return;
    _reachable = reachable;
    if (reachable == null) {
      _path = null;
      isVisible = false;
      return;
    }
    final path = ui.Path();
    for (final tile in reachable.tiles) {
      path.addPath(
        aonwProjectedHexPath(cache.projection, tile.coordinate),
        ui.Offset.zero,
      );
    }
    _path = path;
    _pathBuildCount += 1;
    isVisible = true;
  }

  void clearLayer() {
    _reachable = null;
    _path = null;
    isVisible = false;
  }

  @override
  void render(ui.Canvas canvas) {
    final path = _path;
    if (path != null) canvas.drawPath(path, _paint);
  }
}

final class MapRouteLayerComponent extends Component with HasVisibility {
  MapRouteLayerComponent() : super(priority: 40) {
    isVisible = false;
  }

  static final ui.Paint _paint = ui.Paint()
    ..color = MapPalette.route
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 7
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round;
  RoutePlanView? _route;
  ui.Path? _path;
  var _pathBuildCount = 0;

  @visibleForTesting
  int get debugPathBuildCount => _pathBuildCount;

  void applyRoute(MapStaticRenderCache cache, RoutePlanView? route) {
    if (identical(_route, route)) return;
    _route = route;
    if (route == null || route.steps.isEmpty) {
      _path = null;
      isVisible = false;
      return;
    }
    final path = ui.Path();
    for (var index = 0; index < route.steps.length; index++) {
      final center = cache.projection.hexCenter(route.steps[index].coordinate);
      final x = center.x;
      final y = center.y;
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    _path = path;
    _pathBuildCount += 1;
    isVisible = true;
  }

  void clearLayer() {
    _route = null;
    _path = null;
    isVisible = false;
  }

  @override
  void render(ui.Canvas canvas) {
    final path = _path;
    if (path != null) canvas.drawPath(path, _paint);
  }
}

final class MapSelectionLayerComponent extends Component with HasVisibility {
  MapSelectionLayerComponent({required MapUnitLayerComponent units})
    : _units = units,
      super(priority: 60) {
    isVisible = false;
  }

  final MapUnitLayerComponent _units;
  static final ui.Paint _hoverPaint = ui.Paint()
    ..color = MapPalette.hover
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 3;
  static final ui.Paint _selectionPaint = ui.Paint()
    ..color = MapPalette.selection
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 5;
  static final ui.Paint _selectedUnitPaint = ui.Paint()
    ..color = MapPalette.selection
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 4;
  ui.Path? _hoverPath;
  ui.Path? _selectionPath;
  String? _selectedUnitId;
  MapInteractionState? _interaction;
  MapHexCoordinate? _cursor;
  MapStaticRenderCache? _cursorCache;
  var _updateCount = 0;
  var _cursorUpdateCount = 0;

  @visibleForTesting
  int get debugUpdateCount => _updateCount;

  @visibleForTesting
  int get debugCursorUpdateCount => _cursorUpdateCount;

  void applySelection(
    MapStaticRenderCache cache,
    MapInteractionState interaction,
  ) {
    if (identical(_interaction, interaction)) return;
    _interaction = interaction;
    _selectionPath = _pathFor(cache, interaction.selected);
    _selectedUnitId = interaction.selectedUnitId;
    _updateCount += 1;
    _refreshVisibility();
  }

  void applyCursor(MapStaticRenderCache cache, MapHexCoordinate? coordinate) {
    if (_cursor == coordinate && identical(_cursorCache, cache)) return;
    _cursor = coordinate;
    _cursorCache = cache;
    _hoverPath = _pathFor(cache, coordinate);
    _cursorUpdateCount += 1;
    _refreshVisibility();
  }

  void clearLayer() {
    _interaction = null;
    _cursor = null;
    _cursorCache = null;
    _hoverPath = null;
    _selectionPath = null;
    _selectedUnitId = null;
    isVisible = false;
  }

  void _refreshVisibility() {
    isVisible =
        _hoverPath != null || _selectionPath != null || _selectedUnitId != null;
  }

  @override
  void render(ui.Canvas canvas) {
    final hover = _hoverPath;
    if (hover != null) canvas.drawPath(hover, _hoverPaint);
    final selection = _selectionPath;
    if (selection != null) canvas.drawPath(selection, _selectionPaint);
    final selectedUnit = _selectedUnitId == null
        ? null
        : _units.componentForUnit(_selectedUnitId!);
    if (selectedUnit != null) {
      canvas.drawCircle(selectedUnit.visualCenter, 23, _selectedUnitPaint);
    }
  }

  static ui.Path? _pathFor(
    MapStaticRenderCache cache,
    MapHexCoordinate? coordinate,
  ) {
    if (coordinate == null) return null;
    return ui.Path()..addPath(
      aonwProjectedHexPath(cache.projection, coordinate),
      ui.Offset.zero,
    );
  }
}
