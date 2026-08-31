import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../features/map/presentation/map_palette.dart';
import '../../features/map/read_model/map_view.dart';
import 'static_map_layers.dart';

/// Static authored objective markers for the current map.
///
/// This layer deliberately knows nothing about ownership, hold progress or victory
/// counters. Those are authoritative engine concerns and are not part of the map
/// contract consumed here.
final class MapObjectiveLayerComponent extends Component with HasVisibility {
  MapObjectiveLayerComponent() : super(priority: 43) {
    isVisible = false;
  }

  final _objectivesById = <String, MapObjectiveComponent>{};
  ({String mapId, String contentHash})? _mapIdentity;
  var _createdCount = 0;
  var _removedCount = 0;

  @visibleForTesting
  int get debugObjectiveCount => _objectivesById.length;

  @visibleForTesting
  int get debugCreatedCount => _createdCount;

  @visibleForTesting
  int get debugRemovedCount => _removedCount;

  @visibleForTesting
  int get debugSharedPaintCount => MapObjectiveComponent.sharedPaintCount;

  @visibleForTesting
  MapObjectiveComponent? debugComponentForObjective(String objectiveId) =>
      _objectivesById[objectiveId];

  void applyMap(MapView map, MapStaticRenderCache cache) {
    final identity = (mapId: map.mapId, contentHash: map.contentHash);
    if (_mapIdentity == identity) return;
    clearLayer();
    _mapIdentity = identity;
    for (final objective in map.objectives) {
      final center = cache.projection.hexTopFaceCenter(objective.coordinate);
      final component = MapObjectiveComponent(
        objective: objective,
        center: ui.Offset(center.x, center.y - 31),
      );
      _objectivesById[objective.id] = component;
      add(component);
      _createdCount += 1;
    }
    isVisible = _objectivesById.isNotEmpty;
  }

  void clearLayer() {
    for (final component in _objectivesById.values) {
      component.removeFromParent();
      _removedCount += 1;
    }
    _objectivesById.clear();
    _mapIdentity = null;
    isVisible = false;
  }
}

final class MapObjectiveComponent extends PositionComponent {
  MapObjectiveComponent({
    required MapObjectiveView objective,
    required ui.Offset center,
  }) : _objective = objective,
       super(
         position: Vector2(center.dx, center.dy),
         size: Vector2.all(_diameter),
         anchor: Anchor.center,
       );

  static const _diameter = 34.0;
  static final ui.Paint _ruinsPaint = ui.Paint()
    ..color = MapPalette.objectiveRuins;
  static final ui.Paint _strategicPassPaint = ui.Paint()
    ..color = MapPalette.objectiveStrategicPass;
  static final ui.Paint _holySitePaint = ui.Paint()
    ..color = MapPalette.objectiveHolySite;
  static final ui.Paint _legendaryResourcePaint = ui.Paint()
    ..color = MapPalette.objectiveLegendaryResource;
  static final ui.Paint _outlinePaint = ui.Paint()
    ..color = MapPalette.objectiveOutline
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2;
  static const sharedPaintCount = 5;

  final MapObjectiveView _objective;

  @visibleForTesting
  MapObjectiveView get debugObjective => _objective;

  @override
  void render(ui.Canvas canvas) {
    const center = ui.Offset(_diameter / 2, _diameter / 2);
    final path = switch (_objective.type) {
      MapObjectiveType.ruins => _diamond(center),
      MapObjectiveType.strategicPass => _triangle(center),
      MapObjectiveType.holySite => _circle(center),
      MapObjectiveType.legendaryResource => _star(center),
    };
    final paint = switch (_objective.type) {
      MapObjectiveType.ruins => _ruinsPaint,
      MapObjectiveType.strategicPass => _strategicPassPaint,
      MapObjectiveType.holySite => _holySitePaint,
      MapObjectiveType.legendaryResource => _legendaryResourcePaint,
    };
    canvas.drawPath(path, paint);
    canvas.drawPath(path, _outlinePaint);
  }

  static ui.Path _diamond(ui.Offset center) => ui.Path()
    ..moveTo(center.dx, 3)
    ..lineTo(_diameter - 3, center.dy)
    ..lineTo(center.dx, _diameter - 3)
    ..lineTo(3, center.dy)
    ..close();

  static ui.Path _triangle(ui.Offset center) => ui.Path()
    ..moveTo(center.dx, 3)
    ..lineTo(_diameter - 3, _diameter - 4)
    ..lineTo(3, _diameter - 4)
    ..close();

  static ui.Path _circle(ui.Offset center) =>
      ui.Path()..addOval(ui.Rect.fromCircle(center: center, radius: 13));

  static ui.Path _star(ui.Offset center) {
    const outer = 14.0;
    const inner = 6.0;
    final path = ui.Path();
    for (var point = 0; point < 10; point++) {
      final angle = -math.pi / 2 + point * math.pi / 5;
      final radius = point.isEven ? outer : inner;
      final offset = ui.Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (point == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }
    return path..close();
  }
}
