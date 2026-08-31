import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../features/cities/read_model/city_view.dart';
import '../../features/map/presentation/map_palette.dart';
import '../presentation/flame_scene_patch.dart';
import 'static_map_layers.dart';

final class MapCityLayerComponent extends Component with HasVisibility {
  MapCityLayerComponent() : super(priority: 45) {
    isVisible = false;
  }

  final _citiesById = <String, MapCityComponent>{};
  var _createdCount = 0;
  var _updatedCount = 0;
  var _removedCount = 0;

  @visibleForTesting
  int get debugCityCount => _citiesById.length;

  @visibleForTesting
  int get debugCreatedCount => _createdCount;

  @visibleForTesting
  int get debugUpdatedCount => _updatedCount;

  @visibleForTesting
  int get debugRemovedCount => _removedCount;

  @visibleForTesting
  int get debugSharedPaintCount => MapCityComponent.sharedPaintCount;

  @visibleForTesting
  MapCityComponent? debugComponentForCity(String cityId) => _citiesById[cityId];

  void applyPatch(FlameScenePatch patch, MapStaticRenderCache cache) {
    for (final cityId in patch.removedCityIds) {
      final component = _citiesById.remove(cityId);
      if (component != null) {
        component.removeFromParent();
        _removedCount += 1;
      }
    }
    for (final city in patch.cityUpserts) {
      final center = _center(cache, city);
      final existing = _citiesById[city.id];
      if (existing == null) {
        final component = MapCityComponent(
          city: city,
          actorPlayerId: patch.snapshot.player.actorPlayerId,
          center: center,
        );
        _citiesById[city.id] = component;
        add(component);
        _createdCount += 1;
      } else {
        existing.applyCity(
          city,
          actorPlayerId: patch.snapshot.player.actorPlayerId,
          center: center,
        );
        _updatedCount += 1;
      }
    }
    isVisible = _citiesById.isNotEmpty;
  }

  void clearLayer() {
    for (final component in _citiesById.values) {
      component.removeFromParent();
    }
    _citiesById.clear();
    isVisible = false;
  }

  static ui.Offset _center(MapStaticRenderCache cache, CityView city) {
    final center = cache.geometry.center(city.center);
    final bounds = cache.geometry.bounds;
    return ui.Offset(center.x - bounds.x, center.y - bounds.y);
  }
}

final class MapCityComponent extends PositionComponent {
  MapCityComponent({
    required CityView city,
    required String actorPlayerId,
    required ui.Offset center,
  }) : _city = city,
       _controlled = city.ownerPlayerId == actorPlayerId,
       super(
         position: Vector2(center.dx, center.dy),
         size: Vector2.all(_diameter),
         anchor: Anchor.center,
       );

  static const _diameter = 58.0;
  static final ui.Paint _controlledPaint = ui.Paint()
    ..color = MapPalette.controlledCity;
  static final ui.Paint _foreignPaint = ui.Paint()
    ..color = MapPalette.foreignCity;
  static final ui.Paint _outlinePaint = ui.Paint()
    ..color = MapPalette.cityOutline
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 3;
  static const sharedPaintCount = 3;

  CityView _city;
  bool _controlled;

  @visibleForTesting
  CityView get debugCity => _city;

  void applyCity(
    CityView city, {
    required String actorPlayerId,
    required ui.Offset center,
  }) {
    _city = city;
    _controlled = city.ownerPlayerId == actorPlayerId;
    position.setValues(center.dx, center.dy);
  }

  @override
  void render(ui.Canvas canvas) {
    const center = ui.Offset(_diameter / 2, _diameter / 2);
    final path = ui.Path()
      ..moveTo(center.dx, 6)
      ..lineTo(_diameter - 6, center.dy)
      ..lineTo(center.dx, _diameter - 6)
      ..lineTo(6, center.dy)
      ..close();
    canvas.drawPath(path, _controlled ? _controlledPaint : _foreignPaint);
    canvas.drawPath(path, _outlinePaint);
  }
}
