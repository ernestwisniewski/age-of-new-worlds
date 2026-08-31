import 'dart:async';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../../design_system/assets/sprite_frame_repository.dart';
import '../../design_system/assets/sprite_frames.dart';
import '../../features/map/application/map_interaction_state.dart';
import '../../features/map/presentation/layers/map_canvas_paths.dart';
import '../../features/map/presentation/map_palette.dart';
import '../../features/map/read_model/map_view.dart';
import '../../features/map/read_model/movement_view.dart';
import '../../features/map/read_model/player_map_view.dart';
import '../presentation/flame_scene_patch.dart';
import 'map_sprite_catalog.dart';
import 'map_sprite_painter.dart';
import 'static_map_layers.dart';

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
    final bounds = cache.geometry.bounds;
    final offset = ui.Offset(-bounds.x, -bounds.y);
    final path = ui.Path();
    for (final tile in reachable.tiles) {
      path.addPath(aonwHexPath(cache.geometry, tile.coordinate), offset);
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
    final bounds = cache.geometry.bounds;
    final path = ui.Path();
    for (var index = 0; index < route.steps.length; index++) {
      final center = cache.geometry.center(route.steps[index].coordinate);
      final x = center.x - bounds.x;
      final y = center.y - bounds.y;
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

final class MapUnitLayerComponent extends Component with HasVisibility {
  MapUnitLayerComponent() : super(priority: 50) {
    isVisible = false;
  }

  final _unitsById = <String, MapUnitComponent>{};
  var _createdCount = 0;
  var _updatedCount = 0;
  var _removedCount = 0;

  @visibleForTesting
  int get debugUnitCount => _unitsById.length;

  @visibleForTesting
  int get debugCreatedCount => _createdCount;

  @visibleForTesting
  int get debugUpdatedCount => _updatedCount;

  @visibleForTesting
  int get debugRemovedCount => _removedCount;

  @visibleForTesting
  int get debugSharedPaintCount => MapUnitComponent.sharedPaintCount;

  @visibleForTesting
  MapUnitComponent? debugComponentForUnit(String unitId) => _unitsById[unitId];

  MapUnitComponent? componentForUnit(String unitId) => _unitsById[unitId];

  void applyPatch(FlameScenePatch patch, MapStaticRenderCache cache) {
    final animatedIds = {
      for (final movement in patch.movements) movement.unitId,
    };
    for (final unitId in patch.removedUnitIds) {
      final component = _unitsById.remove(unitId);
      if (component != null) {
        component.removeFromParent();
        _removedCount += 1;
      }
    }
    for (final unit in patch.unitUpserts) {
      final center = _center(cache, unit.coordinate);
      final existing = _unitsById[unit.id];
      if (existing == null) {
        final component = MapUnitComponent(
          unit: unit,
          actorPlayerId: patch.snapshot.player.actorPlayerId,
          center: center,
        );
        _unitsById[unit.id] = component;
        add(component);
        _createdCount += 1;
      } else {
        existing.applyUnit(
          unit,
          actorPlayerId: patch.snapshot.player.actorPlayerId,
          center: center,
          preserveVisualPosition: animatedIds.contains(unit.id),
        );
        _updatedCount += 1;
      }
    }
    isVisible = _unitsById.isNotEmpty;
  }

  void clearLayer() {
    for (final component in _unitsById.values) {
      component.removeFromParent();
    }
    _unitsById.clear();
    isVisible = false;
  }

  ui.Offset centerFor(
    MapStaticRenderCache cache,
    MapHexCoordinate coordinate,
  ) => _center(cache, coordinate);

  static ui.Offset _center(
    MapStaticRenderCache cache,
    MapHexCoordinate coordinate,
  ) {
    final bounds = cache.geometry.bounds;
    final center = cache.geometry.center(coordinate);
    return ui.Offset(center.x - bounds.x, center.y - bounds.y);
  }
}

final class MapUnitComponent extends PositionComponent
    with HasGameReference<FlameGame> {
  MapUnitComponent({
    required VisibleUnitView unit,
    required String actorPlayerId,
    required ui.Offset center,
  }) : _unit = unit,
       _controlled = unit.ownerPlayerId == actorPlayerId,
       super(
         position: Vector2(center.dx, center.dy),
         size: Vector2.all(_diameter),
         anchor: Anchor.center,
       );

  static const _radius = 17.0;
  static const _diameter = 46.0;
  static const _idleFrameDuration = 0.9;
  static const _spriteVerticalLiftFactor = 0.16;
  static final ui.Paint _controlledPaint = ui.Paint()
    ..color = MapPalette.controlledUnit;
  static final ui.Paint _foreignPaint = ui.Paint()
    ..color = MapPalette.foreignUnit;
  static final ui.Paint _outlinePaint = ui.Paint()
    ..color = MapPalette.unitOutline
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 3;
  static const sharedPaintCount = 3;

  VisibleUnitView _unit;
  bool _controlled;
  List<SpriteFrame> _frames = const [];
  var _frameIndex = 0;
  var _frameElapsed = 0.0;
  var _loadGeneration = 0;

  @visibleForTesting
  VisibleUnitView get debugUnit => _unit;

  @visibleForTesting
  ui.Offset get debugVisualCenter => visualCenter;

  ui.Offset get visualCenter => ui.Offset(position.x, position.y);

  @visibleForTesting
  SpriteFrame? get debugSpriteFrame => _currentFrame;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    unawaited(_loadFrames());
  }

  void applyUnit(
    VisibleUnitView unit, {
    required String actorPlayerId,
    required ui.Offset center,
    required bool preserveVisualPosition,
  }) {
    final kindChanged = _unit.kind != unit.kind;
    _unit = unit;
    _controlled = unit.ownerPlayerId == actorPlayerId;
    if (!preserveVisualPosition) setVisualCenter(center);
    if (kindChanged) _reloadFrames();
  }

  void setVisualCenter(ui.Offset center) {
    position.setValues(center.dx, center.dy);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_frames.length < 2) return;
    _frameElapsed += dt;
    while (_frameElapsed >= _idleFrameDuration) {
      _frameElapsed -= _idleFrameDuration;
      _frameIndex = (_frameIndex + 1) % _frames.length;
    }
  }

  @override
  void render(ui.Canvas canvas) {
    const center = ui.Offset(_diameter / 2, _diameter / 2);
    final frame = _currentFrame;
    if (frame != null) {
      final metrics = MapSpriteCatalog.unitMetrics(_unit.kind);
      final destination = ui.Rect.fromCenter(
        center: ui.Offset(
          center.dx,
          center.dy - metrics.height * _spriteVerticalLiftFactor,
        ),
        width: metrics.width,
        height: metrics.height,
      );
      MapSpritePainter.paint(canvas, frame, destination: destination);
      return;
    }
    canvas.drawCircle(
      center,
      _radius,
      _controlled ? _controlledPaint : _foreignPaint,
    );
    canvas.drawCircle(center, _radius, _outlinePaint);
  }

  SpriteFrame? get _currentFrame =>
      _frames.isEmpty ? null : _frames[_frameIndex % _frames.length];

  void _reloadFrames() {
    _frames = const [];
    _frameIndex = 0;
    _frameElapsed = 0;
    _loadGeneration += 1;
    if (isLoaded) unawaited(_loadFrames());
  }

  Future<void> _loadFrames() async {
    final generation = ++_loadGeneration;
    final kind = _unit.kind;
    final List<SpriteFrame> frames;
    try {
      frames = await Future.wait(
        MapSpriteCatalog.idleUnitFrames(kind).map(SpriteFrames.load),
      );
    } on Object {
      return;
    }
    if (generation != _loadGeneration || _unit.kind != kind) return;
    _frames = List.unmodifiable(frames);
    _refreshGameWidget();
  }

  void _refreshGameWidget() {
    if (isMounted && game.isAttached && game.paused) {
      game.stepEngine(stepTime: 0);
    }
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
    final bounds = cache.geometry.bounds;
    return ui.Path()..addPath(
      aonwHexPath(cache.geometry, coordinate),
      ui.Offset(-bounds.x, -bounds.y),
    );
  }
}
