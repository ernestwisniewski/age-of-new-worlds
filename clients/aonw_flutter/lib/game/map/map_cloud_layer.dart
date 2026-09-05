import 'dart:async' as async;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../features/map/read_model/map_view.dart';
import '../../features/map/read_model/player_map_view.dart';
import 'static_map_layers.dart';

part 'map_cloud_spawning.dart';
part 'map_cloud_rendering.dart';

/// Ambient clouds clipped to the recipient's discovered map.
/// A one-shot timer lets Flame sleep between cloud groups.
final class MapCloudLayerComponent extends Component {
  MapCloudLayerComponent({
    math.Random? random,
    double? initialDelaySeconds,
    ({double min, double max}) spawnGapSeconds = (min: 38, max: 70),
    ({double min, double max}) durationSeconds = (min: 34, max: 52),
  }) : _random = random ?? math.Random(),
       _initialDelaySeconds = initialDelaySeconds,
       _spawnGapSeconds = spawnGapSeconds,
       _durationSeconds = durationSeconds,
       super(priority: 56);

  static const _maxActiveClouds = 3;
  static const _cloudGroupChance = 0.28;
  static const _cloudClusterChance = 0.06;
  final math.Random _random;
  final double? _initialDelaySeconds;
  final ({double min, double max}) _spawnGapSeconds;
  final ({double min, double max}) _durationSeconds;
  final _clouds = <_Cloudlet>[];
  async.Timer? _spawnTimer;
  MapStaticRenderIdentity? _identity;
  String? _actorPlayerId;
  List<MapHexCoordinate> _discovered = const [];
  ui.Path? _discoveredClipPath;
  ui.Rect _mapBounds = ui.Rect.zero;
  var _hexRadius = 0.0;
  var _viewportActive = false;
  var _reducedMotion = false;
  var _reportedActive = false;
  var _activeUpdateCount = 0;
  var _clipBuildCount = 0;
  void Function(bool active)? onActivityChanged;

  final _cloudPaint = ui.Paint()..filterQuality = ui.FilterQuality.medium;
  final _hazePaint = ui.Paint()
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 14);
  final _corePaint = ui.Paint()
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);
  final _shadowPaint = ui.Paint()
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 20);

  @visibleForTesting
  int get debugActiveCloudCount => _clouds.length;
  @visibleForTesting
  int get debugActivePuffCount =>
      _clouds.fold(0, (count, cloud) => count + cloud.puffs.length);
  @visibleForTesting
  int get debugActiveUpdateCount => _activeUpdateCount;
  @visibleForTesting
  int get debugClipBuildCount => _clipBuildCount;
  @visibleForTesting
  bool get debugSpawnScheduled => _spawnTimer?.isActive ?? false;
  @visibleForTesting
  bool debugIsDiscovered(ui.Offset position) =>
      _discoveredClipPath?.contains(position) ?? false;

  void applyFog(
    MapStaticRenderCache cache,
    MapFogView fog, {
    required String actorPlayerId,
  }) {
    final identityChanged =
        _identity != cache.identity || _actorPlayerId != actorPlayerId;
    if (identityChanged) _clearWeather();
    _identity = cache.identity;
    _actorPlayerId = actorPlayerId;
    _mapBounds = cache.clipPath.getBounds();
    _hexRadius = cache.geometry.radius;
    final discovered = fog.enabled
        ? fog.discoveredHexes
        : const <MapHexCoordinate>[];
    if (!identityChanged && listEquals(_discovered, discovered)) return;
    _discovered = discovered;
    final clip = ui.Path();
    for (final coordinate in discovered) {
      final path = cache.tilePaths[coordinate];
      if (path != null) clip.addPath(path, ui.Offset.zero);
    }
    _discoveredClipPath = discovered.isEmpty ? null : clip;
    _clipBuildCount++;
    if (_discoveredClipPath == null) _clearWeather();
    _scheduleSpawn(initial: true);
  }

  void setViewportActive(bool active) {
    if (_viewportActive == active) return;
    _viewportActive = active;
    if (!active) _clearWeather();
    _scheduleSpawn(initial: true);
  }

  void setReducedMotion(bool enabled) {
    if (_reducedMotion == enabled) return;
    _reducedMotion = enabled;
    if (enabled) _clearWeather();
    _scheduleSpawn(initial: true);
  }

  bool get _canAnimate =>
      _viewportActive &&
      !_reducedMotion &&
      _discoveredClipPath != null &&
      !_mapBounds.isEmpty;

  void _scheduleSpawn({required bool initial}) {
    if (!_canAnimate || _clouds.isNotEmpty || _spawnTimer != null) return;
    final seconds = initial
        ? _initialDelaySeconds ?? _range((min: 10, max: 22))
        : _range(_spawnGapSeconds);
    _spawnTimer = async.Timer(
      Duration(microseconds: (seconds * 1000000).round()),
      () {
        _spawnTimer = null;
        if (!_canAnimate) return;
        _spawnCloudlet();
        _notifyActivity();
      },
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_canAnimate || _clouds.isEmpty) return;
    _activeUpdateCount++;
    for (final cloud in _clouds) {
      cloud.elapsed += dt;
    }
    _clouds.removeWhere((cloud) {
      if (cloud.elapsed < cloud.duration) return false;
      cloud.image?.dispose();
      return true;
    });
    if (_clouds.isNotEmpty) return;
    _notifyActivity();
    _scheduleSpawn(initial: false);
  }

  void clearLayer() {
    _identity = null;
    _actorPlayerId = null;
    _discovered = const [];
    _discoveredClipPath = null;
    _mapBounds = ui.Rect.zero;
    _clearWeather();
  }

  void _clearWeather() {
    _spawnTimer?.cancel();
    _spawnTimer = null;
    for (final cloud in _clouds) {
      cloud.image?.dispose();
    }
    _clouds.clear();
    _notifyActivity();
  }

  void _notifyActivity() {
    final active = _clouds.isNotEmpty;
    if (_reportedActive == active) return;
    _reportedActive = active;
    onActivityChanged?.call(active);
  }

  @override
  void onRemove() {
    _viewportActive = false;
    clearLayer();
    super.onRemove();
  }

  @override
  void render(ui.Canvas canvas) {
    final clip = _discoveredClipPath;
    if (!_canAnimate || _clouds.isEmpty || clip == null) return;
    canvas
      ..save()
      ..clipPath(clip);
    for (final cloud in _clouds) {
      _renderCloud(canvas, cloud);
    }
    canvas.restore();
  }
}
