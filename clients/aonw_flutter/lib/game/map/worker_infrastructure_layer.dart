import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../../design_system/assets/sprite_frame_repository.dart';
import '../../design_system/assets/sprite_frames.dart';
import '../../features/map/presentation/map_palette.dart';
import '../../features/map/read_model/map_view.dart';
import '../../features/workers/read_model/worker_view.dart';
import '../presentation/flame_scene_patch.dart';
import 'map_canvas_clip.dart';
import 'map_sprite_catalog.dart';
import 'map_sprite_painter.dart';
import 'static_map_layers.dart';

final class MapWorkerInfrastructureLayerComponent extends Component
    with HasVisibility {
  MapWorkerInfrastructureLayerComponent() : super(priority: 25) {
    isVisible = false;
  }

  final _improvements = <MapHexCoordinate, MapFieldImprovementComponent>{};
  final _roads = <MapHexCoordinate, RoadView>{};
  Set<MapHexCoordinate> _cityCenters = const {};
  MapHexCoordinate? _selectedCoordinate;
  ui.Path _roadPath = ui.Path();
  ui.Path _markingPath = ui.Path();
  var _operationalRoadCount = 0;
  var _roadGeometryBuildCount = 0;
  var _createdCount = 0;
  var _updatedCount = 0;
  var _removedCount = 0;

  static final _roadEdgePaint = ui.Paint()
    ..color = MapPalette.roadEdge
    ..strokeWidth = 9
    ..strokeCap = ui.StrokeCap.round
    ..style = ui.PaintingStyle.stroke
    ..isAntiAlias = true;
  static final _roadAsphaltPaint = ui.Paint()
    ..color = MapPalette.roadAsphalt
    ..strokeWidth = 7
    ..strokeCap = ui.StrokeCap.round
    ..style = ui.PaintingStyle.stroke
    ..isAntiAlias = true;
  static final _roadMarkingPaint = ui.Paint()
    ..color = MapPalette.roadMarking
    ..strokeWidth = 1.5
    ..strokeCap = ui.StrokeCap.round
    ..style = ui.PaintingStyle.stroke
    ..isAntiAlias = true;

  @visibleForTesting
  int get debugImprovementCount => _improvements.length;

  @visibleForTesting
  int get debugRoadCount => _roads.length;

  @visibleForTesting
  int get debugOperationalRoadCount => _operationalRoadCount;

  @visibleForTesting
  int get debugRoadGeometryBuildCount => _roadGeometryBuildCount;

  @visibleForTesting
  int get debugRoadPathMetricCount => _roadPath.computeMetrics().length;

  @visibleForTesting
  int get debugCityConnectionCount => _cityConnectionCount();

  @visibleForTesting
  int get debugCreatedCount => _createdCount;

  @visibleForTesting
  int get debugUpdatedCount => _updatedCount;

  @visibleForTesting
  int get debugRemovedCount => _removedCount;

  @visibleForTesting
  int get debugSharedPaintCount =>
      MapFieldImprovementComponent.sharedPaintCount + 3;

  @visibleForTesting
  MapFieldImprovementComponent? debugImprovementAt(
    MapHexCoordinate coordinate,
  ) => _improvements[coordinate];

  @visibleForTesting
  RoadView? debugRoadAt(MapHexCoordinate coordinate) => _roads[coordinate];

  void applyPatch(FlameScenePatch patch, MapStaticRenderCache cache) {
    _applyImprovementPatch(patch, cache);
    var roadsChanged = false;
    for (final coordinate in patch.removedRoadCoordinates) {
      if (_roads.remove(coordinate) != null) {
        _removedCount += 1;
        roadsChanged = true;
      }
    }
    for (final road in patch.roadUpserts) {
      final existing = _roads[road.coordinate];
      if (existing == null) {
        _createdCount += 1;
      } else {
        _updatedCount += 1;
      }
      _roads[road.coordinate] = road;
      roadsChanged = true;
    }
    final cityCenters = {
      for (final city in patch.snapshot.player.cities) city.center,
    };
    if (!_sameCoordinates(_cityCenters, cityCenters)) {
      _cityCenters = Set.unmodifiable(cityCenters);
      roadsChanged = true;
    }
    if (roadsChanged) _rebuildRoadGeometry(cache);
    isVisible = _improvements.isNotEmpty || _operationalRoadCount > 0;
  }

  void _applyImprovementPatch(
    FlameScenePatch patch,
    MapStaticRenderCache cache,
  ) {
    for (final coordinate in patch.removedFieldImprovementCoordinates) {
      _remove(_improvements.remove(coordinate));
    }
    for (final improvement in patch.fieldImprovementUpserts) {
      final center = _center(cache, improvement.coordinate);
      final existing = _improvements[improvement.coordinate];
      if (existing == null) {
        final component = MapFieldImprovementComponent(
          improvement: improvement,
          center: center,
          selected:
              improvement.coordinate == patch.snapshot.interaction.selected,
        );
        _improvements[improvement.coordinate] = component;
        add(component);
        _createdCount += 1;
      } else {
        existing.applyImprovement(improvement, center);
        _updatedCount += 1;
      }
    }
    final selectedCoordinate = patch.snapshot.interaction.selected;
    if (_selectedCoordinate != selectedCoordinate) {
      _selectedCoordinate = selectedCoordinate;
      for (final entry in _improvements.entries) {
        entry.value.setSelected(entry.key == selectedCoordinate);
      }
    }
  }

  void _remove(Component? component) {
    if (component == null) return;
    component.removeFromParent();
    _removedCount += 1;
  }

  void clearLayer() {
    for (final component in _improvements.values) {
      component.removeFromParent();
    }
    _improvements.clear();
    _roads.clear();
    _cityCenters = const {};
    _selectedCoordinate = null;
    _roadPath = ui.Path();
    _markingPath = ui.Path();
    _operationalRoadCount = 0;
    isVisible = false;
  }

  @override
  void render(ui.Canvas canvas) {
    if (_operationalRoadCount == 0) return;
    canvas
      ..drawPath(_roadPath, _roadEdgePaint)
      ..drawPath(_roadPath, _roadAsphaltPaint)
      ..drawPath(_markingPath, _roadMarkingPaint);
  }

  void _rebuildRoadGeometry(MapStaticRenderCache cache) {
    _roadGeometryBuildCount += 1;
    final roadPath = ui.Path();
    final markingPath = ui.Path();
    final operational = {
      for (final road in _roads.values)
        if (road.condition == TransportConditionView.operational)
          road.coordinate,
    };
    for (final coordinate in operational) {
      final center = _center(cache, coordinate);
      var connected = false;
      for (final neighbor in cache.geometry.neighbors(coordinate)) {
        final connectsRoad = operational.contains(neighbor);
        final connectsCity = _cityCenters.contains(neighbor);
        if (!connectsRoad && !connectsCity) continue;
        connected = true;
        if (connectsRoad && !_drawsEdge(coordinate, neighbor)) continue;
        _addRoadSegment(
          roadPath,
          markingPath,
          center,
          _center(cache, neighbor),
        );
      }
      if (!connected) {
        _addRoadSegment(
          roadPath,
          markingPath,
          ui.Offset(center.dx - 8, center.dy),
          ui.Offset(center.dx + 8, center.dy),
        );
      }
    }
    _roadPath = roadPath;
    _markingPath = markingPath;
    _operationalRoadCount = operational.length;
  }

  int _cityConnectionCount() {
    var count = 0;
    for (final road in _roads.values) {
      if (road.condition != TransportConditionView.operational) continue;
      for (final neighbor in _neighbors(road.coordinate)) {
        if (_cityCenters.contains(neighbor)) count += 1;
      }
    }
    return count;
  }

  Iterable<MapHexCoordinate> _neighbors(MapHexCoordinate coordinate) {
    final odd = coordinate.col.isOdd;
    return [
      (col: coordinate.col + 1, row: coordinate.row + (odd ? 0 : -1)),
      (col: coordinate.col + 1, row: coordinate.row + (odd ? 1 : 0)),
      (col: coordinate.col, row: coordinate.row + 1),
      (col: coordinate.col - 1, row: coordinate.row + (odd ? 1 : 0)),
      (col: coordinate.col - 1, row: coordinate.row + (odd ? 0 : -1)),
      (col: coordinate.col, row: coordinate.row - 1),
    ];
  }

  static bool _sameCoordinates(
    Set<MapHexCoordinate> left,
    Set<MapHexCoordinate> right,
  ) => left.length == right.length && left.containsAll(right);

  static bool _drawsEdge(MapHexCoordinate source, MapHexCoordinate target) =>
      source.col < target.col ||
      (source.col == target.col && source.row < target.row);

  static void _addRoadSegment(
    ui.Path roadPath,
    ui.Path markingPath,
    ui.Offset start,
    ui.Offset end,
  ) {
    roadPath
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);
    _addDashedLine(markingPath, start, end);
  }

  static void _addDashedLine(ui.Path path, ui.Offset start, ui.Offset end) {
    const dashLength = 6.0;
    const gapLength = 5.0;
    final delta = end - start;
    final length = delta.distance;
    if (length == 0) return;
    final direction = delta / length;
    for (var offset = 0.0; offset < length; offset += dashLength + gapLength) {
      final finish = math.min(offset + dashLength, length);
      final dashStart = start + direction * offset;
      final dashEnd = start + direction * finish;
      path
        ..moveTo(dashStart.dx, dashStart.dy)
        ..lineTo(dashEnd.dx, dashEnd.dy);
    }
  }
}

final class MapFieldImprovementComponent extends PositionComponent
    with HasGameReference<FlameGame> {
  MapFieldImprovementComponent({
    required FieldImprovementView improvement,
    required ui.Offset center,
    required bool selected,
  }) : _improvement = improvement,
       _selected = selected,
       super(
         position: Vector2(center.dx, center.dy),
         size: Vector2(_width, _height),
         anchor: Anchor.center,
       );

  static const _width = 84.0;
  static final _height = 60 * math.sqrt(3) * 0.62 * 0.70;
  static final ui.Paint _spriteSurfacePaint = ui.Paint()
    ..color = MapPalette.improvementSurface;
  static final ui.Paint _spriteRimPaint = ui.Paint()
    ..color = MapPalette.improvementRim
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final ui.Paint _selectedRimPaint = ui.Paint()
    ..color = MapPalette.improvementSelectedRim
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final ui.Paint _selectedShadowStrongPaint = ui.Paint()
    ..color = MapPalette.improvementSelectedShadowStrong
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 7
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
  static final ui.Paint _selectedShadowSoftPaint = ui.Paint()
    ..color = MapPalette.improvementSelectedShadowSoft
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 5
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.6);
  static final ui.Paint _fallbackPaint = ui.Paint()
    ..color = MapPalette.mapIconFallback;
  static const sharedPaintCount = 6;

  FieldImprovementView _improvement;
  bool _selected;
  SpriteFrame? _frame;
  var _loadGeneration = 0;

  static final _visualBounds = ui.Rect.fromLTWH(
    0,
    0,
    _width,
    _height,
  ).inflate(20);
  var _paintCount = 0;

  @visibleForTesting
  int get debugPaintCount => _paintCount;

  @visibleForTesting
  FieldImprovementView get debugImprovement => _improvement;

  @visibleForTesting
  SpriteFrame? get debugSpriteFrame => _frame;

  @visibleForTesting
  bool get debugSelected => _selected;

  @visibleForTesting
  int get debugEraColumn => _improvement.eraColumn;

  @visibleForTesting
  ui.Color get debugEffectiveRimColor =>
      _selected ? _selectedRimPaint.color : _spriteRimPaint.color;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    unawaited(_loadFrame());
  }

  void applyImprovement(FieldImprovementView value, ui.Offset center) {
    final frameChanged =
        _improvement.improvement != value.improvement ||
        _improvement.eraColumn != value.eraColumn;
    _improvement = value;
    position.setValues(center.dx, center.dy);
    if (frameChanged) _reloadFrame();
  }

  void setSelected(bool value) => _selected = value;

  @override
  void render(ui.Canvas canvas) {
    if (!mapCanvasClipBounds(canvas).overlaps(_visualBounds)) return;
    _paintCount++;
    final bounds = ui.Rect.fromLTWH(0, 0, _width, _height);
    final path = MapSpritePainter.flatTopHexPath(bounds);
    final frame = _frame;
    canvas.drawPath(path, _spriteSurfacePaint);
    if (frame != null) {
      MapSpritePainter.paint(canvas, frame, destination: bounds, clip: path);
    } else {
      canvas.drawCircle(bounds.center, 10, _fallbackPaint);
    }
    if (_selected) {
      canvas
        ..drawPath(path, _selectedShadowStrongPaint)
        ..drawPath(path, _selectedShadowSoftPaint)
        ..drawPath(path, _selectedRimPaint);
    } else {
      canvas.drawPath(path, _spriteRimPaint);
    }
  }

  void _reloadFrame() {
    _frame = null;
    _loadGeneration += 1;
    if (isLoaded) unawaited(_loadFrame());
  }

  Future<void> _loadFrame() async {
    final generation = ++_loadGeneration;
    final kind = _improvement.improvement;
    final era = _improvement.eraColumn;
    final SpriteFrame frame;
    try {
      frame = await SpriteFrames.load(
        MapSpriteCatalog.improvementFrame(kind, era: era),
      );
    } on Object {
      return;
    }
    if (generation != _loadGeneration ||
        _improvement.improvement != kind ||
        _improvement.eraColumn != era) {
      return;
    }
    _frame = frame;
    _refreshGameWidget();
  }

  void _refreshGameWidget() {
    if (isMounted && game.isAttached && game.paused) {
      game.stepEngine(stepTime: 0);
    }
  }
}

ui.Offset _center(MapStaticRenderCache cache, MapHexCoordinate coordinate) {
  final center = cache.projection.hexTopFaceCenter(coordinate);
  return ui.Offset(center.x, center.y);
}
