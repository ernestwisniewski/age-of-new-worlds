import 'dart:collection';
import 'dart:ui' as ui;

import '../../features/map/read_model/map_feedback_view.dart';
import '../../features/map/read_model/player_map_view.dart';
import 'map_event_particles.dart';
import 'static_map_layers.dart';

final class MapEventParticlePool {
  static const maximumActive = 8;
  static const maximumPending = 64;
  final _pool = List.generate(maximumActive, (_) => MapEventParticleBurst());
  final _pending = Queue<MapParticleCueView>();
  MapStaticRenderCache? _cache;
  MapFogView? _fog;

  int get activeCount => _pool.where((burst) => burst.active).length;
  int get particleCount =>
      _pool.fold(0, (count, burst) => count + burst.particleCount);
  int get pendingCount => _pending.length;
  bool get active => _pending.isNotEmpty || _pool.any((burst) => burst.active);

  void applyContext(MapStaticRenderCache cache, MapFogView fog) {
    _cache = cache;
    _fog = fog;
    _pending.removeWhere((cue) => !_visible(cue));
    for (final burst in _pool) {
      final cue = burst.cue;
      if (cue != null && !_visible(cue)) burst.clear();
    }
  }

  void enqueue(MapParticleCueView cue) {
    if (!_visible(cue)) return;
    if (_pending.length == maximumPending) _pending.removeFirst();
    _pending.add(cue);
  }

  void startPending() {
    final cache = _cache;
    if (cache == null) return;
    for (final burst in _pool) {
      if (_pending.isEmpty) return;
      if (burst.active) continue;
      final cue = _pending.removeFirst();
      final center = cache.projection.hexCenter(cue.coordinate);
      burst.start(cue, ui.Offset(center.x, center.y));
    }
  }

  void update(double dt) {
    for (final burst in _pool) {
      burst.update(dt);
    }
    startPending();
  }

  void render(ui.Canvas canvas) {
    for (final burst in _pool) {
      burst.render(canvas);
    }
  }

  void skip() {
    _pending.clear();
    for (final burst in _pool) {
      burst.clear();
    }
  }

  void clear() {
    skip();
    _cache = null;
    _fog = null;
  }

  bool _visible(MapParticleCueView cue) =>
      _fog?.visibilityAt(cue.coordinate) == MapFogVisibilityView.visible;
}
