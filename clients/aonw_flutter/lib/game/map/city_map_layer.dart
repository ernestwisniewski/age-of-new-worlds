import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../../design_system/assets/sprite_frame_id.dart';
import '../../design_system/assets/sprite_frame_repository.dart';
import '../../design_system/assets/sprite_frames.dart';
import '../../features/cities/read_model/city_view.dart';
import '../../features/map/presentation/map_palette.dart';
import '../presentation/flame_scene_patch.dart';
import 'map_sprite_catalog.dart';
import 'map_sprite_painter.dart';
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
    final center = cache.projection.hexTopFaceCenter(city.center);
    return ui.Offset(center.x, center.y);
  }
}

final class MapCityComponent extends PositionComponent
    with HasGameReference<FlameGame> {
  MapCityComponent({
    required CityView city,
    required String actorPlayerId,
    required ui.Offset center,
  }) : _city = city,
       _controlled = city.ownerPlayerId == actorPlayerId,
       super(
         position: Vector2(center.dx, center.dy),
         size: Vector2(_width, _height),
         anchor: Anchor.center,
       );

  static const _width = 120.0;
  static final _height = 60 * math.sqrt(3) * 0.62;
  static final ui.Paint _controlledPaint = ui.Paint()
    ..color = MapPalette.controlledCity;
  static final ui.Paint _foreignPaint = ui.Paint()
    ..color = MapPalette.foreignCity;
  static final ui.Paint _outlinePaint = ui.Paint()
    ..color = MapPalette.cityOutline
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 3;
  static final ui.Paint _spriteSurfacePaint = ui.Paint()
    ..color = const ui.Color(0x28181713);
  static final ui.Paint _spriteRimPaint = ui.Paint()
    ..color = const ui.Color(0xF5D4B46A)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 3;
  static const sharedPaintCount = 5;

  CityView _city;
  bool _controlled;
  SpriteFrame? _frame;
  var _loadGeneration = 0;

  static final _visualBounds = ui.Rect.fromLTWH(
    0,
    0,
    _width,
    _height,
  ).inflate(4);
  var _paintCount = 0;

  @visibleForTesting
  int get debugPaintCount => _paintCount;

  @visibleForTesting
  CityView get debugCity => _city;

  @visibleForTesting
  SpriteFrame? get debugSpriteFrame => _frame;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    unawaited(_loadFrame());
  }

  void applyCity(
    CityView city, {
    required String actorPlayerId,
    required ui.Offset center,
  }) {
    final levelChanged = _visualLevel(_city) != _visualLevel(city);
    _city = city;
    _controlled = city.ownerPlayerId == actorPlayerId;
    position.setValues(center.dx, center.dy);
    if (levelChanged) _reloadFrame();
  }

  @override
  void render(ui.Canvas canvas) {
    if (!canvas.getLocalClipBounds().overlaps(_visualBounds)) return;
    _paintCount++;
    final bounds = ui.Rect.fromLTWH(0, 0, _width, _height);
    final path = MapSpritePainter.flatTopHexPath(bounds);
    final frame = _frame;
    if (frame != null) {
      canvas.drawPath(path, _spriteSurfacePaint);
      MapSpritePainter.paint(canvas, frame, destination: bounds, clip: path);
      canvas.drawPath(path, _spriteRimPaint);
      return;
    }
    canvas.drawPath(path, _controlled ? _controlledPaint : _foreignPaint);
    canvas.drawPath(path, _outlinePaint);
  }

  void _reloadFrame() {
    _frame = null;
    _loadGeneration += 1;
    if (isLoaded) unawaited(_loadFrame());
  }

  Future<void> _loadFrame() async {
    final generation = ++_loadGeneration;
    final id = MapSpriteCatalog.cityFrame(visualLevel: _visualLevel(_city));
    final SpriteFrame frame;
    try {
      frame = await SpriteFrames.load(id);
    } on Object {
      return;
    }
    if (generation != _loadGeneration || id != _frameId) return;
    _frame = frame;
    _refreshGameWidget();
  }

  SpriteFrameId get _frameId =>
      MapSpriteCatalog.cityFrame(visualLevel: _visualLevel(_city));

  static int _visualLevel(CityView city) =>
      MapSpriteCatalog.cityVisualLevel(city.ownedDetails?.population ?? 1);

  void _refreshGameWidget() {
    if (isMounted && game.isAttached && game.paused) {
      game.stepEngine(stepTime: 0);
    }
  }
}
