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
import 'map_sprite_catalog.dart';
import 'map_sprite_painter.dart';
import 'static_map_layers.dart';

final class MapWorkerInfrastructureLayerComponent extends Component
    with HasVisibility {
  MapWorkerInfrastructureLayerComponent() : super(priority: 25) {
    isVisible = false;
  }

  final _improvements = <MapHexCoordinate, MapFieldImprovementComponent>{};
  final _roads = <MapHexCoordinate, MapRoadComponent>{};
  var _createdCount = 0;
  var _updatedCount = 0;
  var _removedCount = 0;

  @visibleForTesting
  int get debugImprovementCount => _improvements.length;

  @visibleForTesting
  int get debugRoadCount => _roads.length;

  @visibleForTesting
  int get debugCreatedCount => _createdCount;

  @visibleForTesting
  int get debugUpdatedCount => _updatedCount;

  @visibleForTesting
  int get debugRemovedCount => _removedCount;

  @visibleForTesting
  int get debugSharedPaintCount =>
      MapFieldImprovementComponent.sharedPaintCount +
      MapRoadComponent.sharedPaintCount;

  @visibleForTesting
  MapFieldImprovementComponent? debugImprovementAt(
    MapHexCoordinate coordinate,
  ) => _improvements[coordinate];

  @visibleForTesting
  MapRoadComponent? debugRoadAt(MapHexCoordinate coordinate) =>
      _roads[coordinate];

  void applyPatch(FlameScenePatch patch, MapStaticRenderCache cache) {
    for (final coordinate in patch.removedFieldImprovementCoordinates) {
      _remove(_improvements.remove(coordinate));
    }
    for (final coordinate in patch.removedRoadCoordinates) {
      _remove(_roads.remove(coordinate));
    }
    for (final improvement in patch.fieldImprovementUpserts) {
      final center = _center(cache, improvement.coordinate);
      final existing = _improvements[improvement.coordinate];
      if (existing == null) {
        final component = MapFieldImprovementComponent(
          improvement: improvement,
          center: center,
        );
        _improvements[improvement.coordinate] = component;
        add(component);
        _createdCount += 1;
      } else {
        existing.applyImprovement(improvement, center);
        _updatedCount += 1;
      }
    }
    for (final road in patch.roadUpserts) {
      final center = _center(cache, road.coordinate);
      final existing = _roads[road.coordinate];
      if (existing == null) {
        final component = MapRoadComponent(road: road, center: center);
        _roads[road.coordinate] = component;
        add(component);
        _createdCount += 1;
      } else {
        existing.applyRoad(road, center);
        _updatedCount += 1;
      }
    }
    isVisible = _improvements.isNotEmpty || _roads.isNotEmpty;
  }

  void _remove(Component? component) {
    if (component == null) return;
    component.removeFromParent();
    _removedCount += 1;
  }

  void clearLayer() {
    for (final component in [..._improvements.values, ..._roads.values]) {
      component.removeFromParent();
    }
    _improvements.clear();
    _roads.clear();
    isVisible = false;
  }
}

final class MapFieldImprovementComponent extends PositionComponent
    with HasGameReference<FlameGame> {
  MapFieldImprovementComponent({
    required FieldImprovementView improvement,
    required ui.Offset center,
  }) : _improvement = improvement,
       super(
         position: Vector2(center.dx, center.dy),
         size: Vector2(_width, _height),
         anchor: Anchor.center,
       );

  static const _width = 84.0;
  static final _height = 60 * math.sqrt(3) * 0.62 * 0.70;
  static final ui.Paint _fill = ui.Paint()..color = MapPalette.reachable;
  static final ui.Paint _outline = ui.Paint()
    ..color = MapPalette.cityOutline
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2;
  static final ui.Paint _spriteSurfacePaint = ui.Paint()
    ..color = const ui.Color(0x2615171A);
  static final ui.Paint _spriteRimPaint = ui.Paint()
    ..color = const ui.Color(0xF5C8CCD2)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static const sharedPaintCount = 4;

  FieldImprovementView _improvement;
  SpriteFrame? _frame;
  var _loadGeneration = 0;

  @visibleForTesting
  FieldImprovementView get debugImprovement => _improvement;

  @visibleForTesting
  SpriteFrame? get debugSpriteFrame => _frame;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    unawaited(_loadFrame());
  }

  void applyImprovement(FieldImprovementView value, ui.Offset center) {
    final typeChanged = _improvement.improvement != value.improvement;
    _improvement = value;
    position.setValues(center.dx, center.dy);
    if (typeChanged) _reloadFrame();
  }

  @override
  void render(ui.Canvas canvas) {
    final bounds = ui.Rect.fromLTWH(0, 0, _width, _height);
    final path = MapSpritePainter.flatTopHexPath(bounds);
    final frame = _frame;
    if (frame != null) {
      canvas.drawPath(path, _spriteSurfacePaint);
      MapSpritePainter.paint(canvas, frame, destination: bounds, clip: path);
      canvas.drawPath(path, _spriteRimPaint);
      return;
    }
    canvas.drawPath(path, _fill);
    canvas.drawPath(path, _outline);
  }

  void _reloadFrame() {
    _frame = null;
    _loadGeneration += 1;
    if (isLoaded) unawaited(_loadFrame());
  }

  Future<void> _loadFrame() async {
    final generation = ++_loadGeneration;
    final kind = _improvement.improvement;
    final SpriteFrame frame;
    try {
      frame = await SpriteFrames.load(MapSpriteCatalog.improvementFrame(kind));
    } on Object {
      return;
    }
    if (generation != _loadGeneration || _improvement.improvement != kind) {
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

final class MapRoadComponent extends PositionComponent {
  MapRoadComponent({required RoadView road, required ui.Offset center})
    : _road = road,
      super(
        position: Vector2(center.dx, center.dy),
        size: Vector2.all(_size),
        anchor: Anchor.center,
      );

  static const _size = 38.0;
  static final ui.Paint _operational = ui.Paint()
    ..color = MapPalette.cityOutline
    ..strokeWidth = 5
    ..strokeCap = ui.StrokeCap.round;
  static final ui.Paint _pillaged = ui.Paint()
    ..color = MapPalette.foreignCity
    ..strokeWidth = 5
    ..strokeCap = ui.StrokeCap.round;
  static const sharedPaintCount = 2;

  RoadView _road;

  @visibleForTesting
  RoadView get debugRoad => _road;

  void applyRoad(RoadView value, ui.Offset center) {
    _road = value;
    position.setValues(center.dx, center.dy);
  }

  @override
  void render(ui.Canvas canvas) {
    final paint = _road.condition == TransportConditionView.operational
        ? _operational
        : _pillaged;
    canvas.drawLine(const ui.Offset(3, 28), const ui.Offset(35, 10), paint);
  }
}

ui.Offset _center(MapStaticRenderCache cache, MapHexCoordinate coordinate) {
  final center = cache.projection.hexTopFaceCenter(coordinate);
  return ui.Offset(center.x, center.y);
}
