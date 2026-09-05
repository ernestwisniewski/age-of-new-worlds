import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../features/map/presentation/map_render_snapshot.dart';
import '../../features/map/read_model/map_feedback_view.dart';
import '../../features/map/read_model/player_map_view.dart';
import 'map_event_particles.dart';
import 'static_map_layers.dart';

final class MapEventFeedbackLayerComponent extends Component {
  MapEventFeedbackLayerComponent() : super(priority: 69);

  static const maximumActiveBursts = 8;
  static const maximumPendingBursts = 64;
  final _pool = List.generate(
    maximumActiveBursts,
    (_) => MapEventParticleBurst(),
  );
  final _pending = Queue<MapParticleCueView>();
  MapStaticRenderCache? _cache;
  MapFogView? _fog;
  String? _actor;
  int? _revision;
  bool _reducedMotion = false;
  bool _active = false;
  double _speed = 1;
  int _activeUpdateCount = 0;
  void Function(bool active)? onActivityChanged;

  @visibleForTesting
  int get debugActiveBurstCount => _pool.where((burst) => burst.active).length;
  @visibleForTesting
  int get debugParticleCount =>
      _pool.fold(0, (count, burst) => count + burst.particleCount);
  @visibleForTesting
  int get debugPendingBurstCount => _pending.length;
  @visibleForTesting
  int get debugActiveUpdateCount => _activeUpdateCount;

  void applySnapshot(MapRenderSnapshot snapshot, MapStaticRenderCache cache) {
    if (_resetIfChanged(snapshot, cache)) return;
    final player = snapshot.player;
    final previousRevision = _revision!;
    _revision = player.stamp.revision;
    _pruneInvisible(player.fog);
    if (_reducedMotion || player.stamp.revision == previousRevision) return;
    _enqueue(player.recentFeedback, previousRevision, player.stamp.revision);
    _startPending();
    _notifyActivity();
  }

  bool _resetIfChanged(MapRenderSnapshot snapshot, MapStaticRenderCache cache) {
    final player = snapshot.player;
    final previousRevision = _revision;
    if (_cache?.identity == cache.identity &&
        _actor == player.actorPlayerId &&
        previousRevision != null &&
        player.stamp.revision >= previousRevision) {
      return false;
    }
    clearLayer();
    _cache = cache;
    _fog = player.fog;
    _actor = player.actorPlayerId;
    _revision = player.stamp.revision;
    return true;
  }

  void _pruneInvisible(MapFogView fog) {
    _fog = fog;
    _pending.removeWhere((cue) => !_visible(cue));
    for (final burst in _pool) {
      final cue = burst.cue;
      if (cue != null && !_visible(cue)) burst.clear();
    }
    _notifyActivity();
  }

  void _enqueue(
    List<MapFeedbackCueView> cues,
    int previousRevision,
    int revision,
  ) {
    for (final cue in cues) {
      if (cue.identity.revision <= previousRevision ||
          cue.identity.revision > revision) {
        continue;
      }
      switch (cue) {
        case MapParticleCueView():
          if (!_visible(cue)) continue;
          if (_pending.length == maximumPendingBursts) _pending.removeFirst();
          _pending.add(cue);
      }
    }
  }

  void _startPending() {
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

  void setReducedMotion(bool enabled) {
    _reducedMotion = enabled;
    if (enabled) skip();
  }

  void setPlaybackSpeed(double speed) {
    if (!speed.isFinite || speed <= 0) {
      throw ArgumentError.value(speed, 'speed', 'must be finite and positive');
    }
    _speed = speed;
  }

  void skip() {
    _pending.clear();
    for (final burst in _pool) {
      burst.clear();
    }
    _notifyActivity();
  }

  void clearLayer() {
    skip();
    _cache = null;
    _fog = null;
    _actor = null;
    _revision = null;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active) return;
    _activeUpdateCount++;
    for (final burst in _pool) {
      burst.update(dt * _speed);
    }
    _startPending();
    _notifyActivity();
  }

  @override
  void render(ui.Canvas canvas) {
    for (final burst in _pool) {
      burst.render(canvas);
    }
  }

  void _notifyActivity() {
    final active = _pending.isNotEmpty || _pool.any((burst) => burst.active);
    if (_active == active) return;
    _active = active;
    onActivityChanged?.call(active);
  }

  bool _visible(MapParticleCueView cue) =>
      _fog?.visibilityAt(cue.coordinate) == MapFogVisibilityView.visible;
}
