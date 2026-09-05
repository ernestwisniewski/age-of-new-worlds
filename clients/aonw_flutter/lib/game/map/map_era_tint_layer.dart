import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import '../../features/map/presentation/map_render_snapshot.dart';
import '../../features/map/read_model/player_map_view.dart';
import 'static_map_layers.dart';

/// Draws the recipient's authoritative research era below infrastructure and fog.
final class MapEraTintLayerComponent extends Component with HasVisibility {
  MapEraTintLayerComponent() : super(priority: 24) {
    isVisible = false;
  }

  static const _duration = 0.65;
  final _paint = ui.Paint();
  MapStaticRenderIdentity? _identity;
  String? _actor;
  PlayerTechnologyEraView? _era;
  List<_TintRegion> _regions = const [];
  ui.Rect _bounds = ui.Rect.zero;
  ui.Color _color = const ui.Color(0x00000000);
  ui.Color _from = const ui.Color(0x00000000);
  ui.Color _target = const ui.Color(0x00000000);
  var _elapsed = 0.0;
  var _active = false;
  var _reducedMotion = false;
  var _playbackSpeed = 1.0;
  var _shaderBuildCount = 0;
  var _activeUpdateCount = 0;
  var _renderedRegionCount = 0;
  void Function(bool active)? onActivityChanged;

  @visibleForTesting
  PlayerTechnologyEraView? get debugEra => _era;
  @visibleForTesting
  ui.Color get debugTintColor => _color;
  @visibleForTesting
  bool get debugActive => _active;
  @visibleForTesting
  int get debugShaderBuildCount => _shaderBuildCount;
  @visibleForTesting
  int get debugActiveUpdateCount => _activeUpdateCount;
  @visibleForTesting
  int get debugRegionCount => _regions.length;
  @visibleForTesting
  int get debugRegionContourCount => _regions.fold(
    0,
    (count, region) => count + region.path.computeMetrics().length,
  );
  @visibleForTesting
  int get debugRenderedRegionCount => _renderedRegionCount;

  void applySnapshot(MapRenderSnapshot snapshot, MapStaticRenderCache cache) {
    final identityChanged =
        _identity != cache.identity || _actor != snapshot.player.actorPlayerId;
    final era = snapshot.player.research.dominantEra;
    if (!identityChanged && _era == era) return;
    if (_identity != cache.identity) _regions = _buildRegions(cache);
    _identity = cache.identity;
    _actor = snapshot.player.actorPlayerId;
    _bounds = cache.clipPath.getBounds();
    _era = era;
    _from = _color;
    _target = colorForEra(era);
    _elapsed = 0;
    if (identityChanged || _reducedMotion || _from == _target) {
      skip();
    } else {
      _setActive(true);
    }
  }

  void setReducedMotion(bool enabled) {
    if (_reducedMotion == enabled) return;
    _reducedMotion = enabled;
    if (enabled) skip();
  }

  void setPlaybackSpeed(double speed) {
    if (!speed.isFinite || speed <= 0) {
      throw ArgumentError.value(speed, 'speed', 'must be finite and positive');
    }
    _playbackSpeed = speed;
  }

  void skip() {
    _color = _target;
    _rebuildShader();
    _setActive(false);
  }

  void clearLayer() {
    _identity = null;
    _actor = null;
    _era = null;
    _regions = const [];
    _renderedRegionCount = 0;
    _bounds = ui.Rect.zero;
    _target = const ui.Color(0x00000000);
    skip();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active) return;
    _activeUpdateCount++;
    _elapsed += dt * _playbackSpeed;
    final progress = (_elapsed / _duration).clamp(0.0, 1.0);
    _color = ui.Color.lerp(
      _from,
      _target,
      Curves.easeInOut.transform(progress),
    )!;
    _rebuildShader();
    if (progress >= 1) _setActive(false);
  }

  void _setActive(bool active) {
    if (_active == active) return;
    _active = active;
    onActivityChanged?.call(active);
  }

  void _rebuildShader() {
    final alpha = (_color.toARGB32() >> 24) & 0xff;
    isVisible = alpha > 0 && !_bounds.isEmpty;
    _paint.shader = isVisible
        ? ui.Gradient.linear(
            _bounds.topLeft,
            _bounds.bottomRight,
            [
              _color.withAlpha((alpha * 0.35).round()),
              _color,
              _color.withAlpha((alpha * 0.55).round()),
            ],
            const [0, 0.55, 1],
          )
        : null;
    _shaderBuildCount++;
  }

  @override
  void render(ui.Canvas canvas) {
    _renderedRegionCount = 0;
    if (!isVisible) return;
    final clip = canvas.getLocalClipBounds();
    for (final region in _regions) {
      if (!region.bounds.overlaps(clip)) continue;
      canvas.drawPath(region.path, _paint);
      _renderedRegionCount++;
    }
  }

  static ui.Color colorForEra(PlayerTechnologyEraView era) => switch (era) {
    PlayerTechnologyEraView.foundation => const ui.Color(0x22f6c365),
    PlayerTechnologyEraView.settlement => const ui.Color(0x14b9d88c),
    PlayerTechnologyEraView.expansion => const ui.Color(0x00000000),
    PlayerTechnologyEraView.specialization => const ui.Color(0x1c78b7ff),
    PlayerTechnologyEraView.industry => const ui.Color(0x286d747c),
    PlayerTechnologyEraView.strategy => const ui.Color(0x24f0a24f),
  };
}

// Bound tessellation to visible 8 by 8 regions while retaining one map-wide
// gradient. Merge shared hex edges once so tessellation retains only the
// region outline, using the same map-wide shader coordinates for every region.
List<_TintRegion> _buildRegions(MapStaticRenderCache cache) {
  final paths = <(int, int), ui.Path>{};
  for (final entry in cache.tilePaths.entries) {
    final coordinate = entry.key;
    final key = (coordinate.col ~/ 8, coordinate.row ~/ 8);
    (paths[key] ??= ui.Path()).addPath(entry.value, ui.Offset.zero);
  }
  return [
    for (final path in paths.values)
      _TintRegion(ui.Path.combine(ui.PathOperation.union, path, ui.Path())),
  ];
}

final class _TintRegion {
  _TintRegion(this.path) : bounds = path.getBounds();

  final ui.Path path;
  final ui.Rect bounds;
}
