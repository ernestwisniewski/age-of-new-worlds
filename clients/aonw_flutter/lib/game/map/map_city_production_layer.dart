import 'dart:async' as async;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../features/map/presentation/camera/map_camera_transform.dart';
import '../../features/map/presentation/map_production_hint_visibility.dart';
import '../../features/map/presentation/map_render_snapshot.dart';
import '../../features/map/read_model/player_map_view.dart';
import 'map_city_production_hint.dart';
import 'static_map_layers.dart';

part 'map_city_production_timing.dart';

final class MapCityProductionLayerComponent extends Component {
  MapCityProductionLayerComponent({DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(priority: 71);

  final DateTime Function() _now;
  final _sources = <String, (ui.Offset, int)>{};
  final _hints = <String, MapCityProductionHint>{};
  final _paint = ui.Paint()
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 1.1);
  MapStaticRenderIdentity? _identity;
  String? _actor;
  int? _revision;
  ui.Rect _viewport = ui.Rect.zero;
  MapCameraTransform? _camera;
  bool _densityVisible = false;
  bool _viewportActive = false;
  bool _reducedMotion = false;
  bool _active = false;
  double _time = 0;
  double _cameraReadyAt = 0;
  double _speed = 1;
  async.Timer? _timer;
  DateTime? _idleStarted;
  double _idleDelay = 0;
  int _updates = 0;
  int _created = 0;
  int _rendered = 0;
  void Function(bool active)? onActivityChanged;

  @visibleForTesting
  int get debugHintCount => _hints.length;
  @visibleForTesting
  int get debugActiveHintCount =>
      _hints.values.where((hint) => hint.activeAt(_time)).length;
  @visibleForTesting
  int get debugActiveUpdateCount => _updates;
  @visibleForTesting
  int get debugCreatedCount => _created;
  @visibleForTesting
  int get debugRenderedHintCount => _rendered;
  @visibleForTesting
  bool get debugSpawnScheduled => _timer?.isActive ?? false;

  void applySnapshot(MapRenderSnapshot snapshot, MapStaticRenderCache cache) {
    final player = snapshot.player;
    if (_identity != cache.identity ||
        _actor != player.actorPlayerId ||
        (_revision != null && player.stamp.revision < _revision!)) {
      clearLayer();
    }
    _identity = cache.identity;
    _actor = player.actorPlayerId;
    _revision = player.stamp.revision;
    _sources.clear();
    if (showMapProductionHints(snapshot)) _readSources(snapshot, cache);
    _synchronizeHints();
  }

  void _readSources(MapRenderSnapshot snapshot, MapStaticRenderCache cache) {
    final player = snapshot.player;
    final color = player.participants
        .where((p) => p.id == player.actorPlayerId)
        .firstOrNull
        ?.colorValue;
    if (color == null) return;
    for (final city in player.cities) {
      if (city.ownerPlayerId != player.actorPlayerId ||
          city.ownedDetails?.productionQueue == null ||
          player.fog.visibilityAt(city.center) !=
              MapFogVisibilityView.visible) {
        continue;
      }
      final center = cache.projection.hexTopFaceCenter(city.center);
      _sources[city.id] = (ui.Offset(center.x, center.y), color);
    }
  }

  void applyCamera(MapCameraTransform transform) {
    final previous = _camera;
    if (previous?.worldCenter == transform.worldCenter &&
        previous?.viewport == transform.viewport &&
        previous?.zoom == transform.zoom) {
      return;
    }
    _camera = transform;
    _cancelTimer();
    final center = transform.worldCenter;
    _viewport = ui.Rect.fromCenter(
      center: ui.Offset(center.x, center.y),
      width: transform.viewport.width / transform.zoom,
      height: transform.viewport.height / transform.zoom,
    );
    final compact =
        transform.viewport.width <= 720 &&
        transform.viewport.height > transform.viewport.width;
    _densityVisible = transform.zoom >= (compact ? 0.65 : 0.55);
    // Wait for a settled camera before allocating the visible city particles.
    _hints.clear();
    _cameraReadyAt = _time + 0.12;
    _synchronizeHints();
  }

  bool get _canShow =>
      _viewportActive &&
      !_reducedMotion &&
      _densityVisible &&
      _sources.isNotEmpty;

  void _synchronizeHints() {
    _cancelTimer();
    if (!_canShow || _time < _cameraReadyAt) {
      _hints.clear();
    } else {
      _hints.removeWhere(
        (id, hint) =>
            _sources[id] != (hint.position, hint.ownerColorValue) ||
            !_viewport.overlaps(hint.bounds),
      );
      for (final entry in _sources.entries) {
        if (_hints.containsKey(entry.key)) continue;
        final hint = MapCityProductionHint(
          entry.value.$1,
          entry.value.$2,
          _time,
        );
        if (!_viewport.overlaps(hint.bounds)) continue;
        _hints[entry.key] = hint;
        _created++;
      }
    }
    _refreshTiming();
  }

  void setViewportActive(bool active) {
    if (_viewportActive == active) return;
    _viewportActive = active;
    _synchronizeHints();
  }

  void setReducedMotion(bool enabled) {
    if (_reducedMotion == enabled) return;
    _reducedMotion = enabled;
    _synchronizeHints();
  }

  void setPlaybackSpeed(double speed) => _changePlaybackSpeed(speed);

  void skip() {
    _cancelTimer();
    _hints.clear();
    _synchronizeHints();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active) return;
    _updates++;
    _time += dt * _speed;
    _refreshTiming();
  }

  void clearLayer() {
    _cancelTimer();
    _sources.clear();
    _hints.clear();
    _identity = null;
    _actor = null;
    _revision = null;
    _camera = null;
    _time = 0;
    _cameraReadyAt = 0;
    _rendered = 0;
    _reportActivity(false);
  }

  @override
  void render(ui.Canvas canvas) {
    _rendered = 0;
    for (final hint in _hints.values) {
      if (hint.render(canvas, _time, _paint)) _rendered++;
    }
  }

  @override
  void onRemove() {
    _viewportActive = false;
    clearLayer();
    super.onRemove();
  }
}
