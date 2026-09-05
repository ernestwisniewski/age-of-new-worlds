import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../features/map/presentation/map_render_snapshot.dart';
import '../../features/map/read_model/map_feedback_view.dart';
import 'map_event_feedback_queue.dart';
import 'map_event_particle_pool.dart';
import 'map_floating_text_pool.dart';
import 'static_map_layers.dart';

final class MapEventFeedbackLayerComponent extends Component {
  MapEventFeedbackLayerComponent({
    ui.Offset? Function(String unitId)? unitPositionFor,
  }) : _texts = MapFloatingTextPool(unitPositionFor: unitPositionFor),
       super(priority: 69);

  static const maximumActiveBursts = MapEventParticlePool.maximumActive;
  static const maximumPendingBursts = MapEventFeedbackQueue.maximumPending;
  final _particles = MapEventParticlePool();
  final _queue = MapEventFeedbackQueue();
  final MapFloatingTextPool _texts;
  MapStaticRenderCache? _cache;
  String? _actor;
  int? _revision;
  bool _reducedMotion = false;
  bool _active = false;
  double _speed = 1;
  int _activeUpdateCount = 0;
  void Function(bool active)? onActivityChanged;

  @visibleForTesting
  int get debugActiveBurstCount => _particles.activeCount;
  @visibleForTesting
  int get debugParticleCount => _particles.particleCount;
  @visibleForTesting
  int get debugPendingBurstCount => _queue.particleCount;
  @visibleForTesting
  int get debugActiveUpdateCount => _activeUpdateCount;

  @visibleForTesting
  int get debugTextCount => _texts.activeCount;
  @visibleForTesting
  int get debugVisibleTextCount => _texts.visibleCount;
  @visibleForTesting
  int get debugRenderedTextCount => _texts.renderedCount;
  @visibleForTesting
  int get debugPendingTextCount => _queue.textCount;
  @visibleForTesting
  int get debugTextImageCount => _texts.imageCount;

  void applySnapshot(MapRenderSnapshot snapshot, MapStaticRenderCache cache) {
    final reset = _resetIfChanged(snapshot, cache);
    final player = snapshot.player;
    _particles.applyContext(cache, player.fog);
    _texts.applyContext(cache, player.fog, snapshot.feedbackLabels);
    _queue.applyContext(player.fog, snapshot.feedbackLabels, _reducedMotion);
    final previousRevision = _revision!;
    _revision = player.stamp.revision;
    if (!reset && player.stamp.revision > previousRevision) {
      _enqueue(player.recentFeedback, previousRevision, player.stamp.revision);
    }
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
    _actor = player.actorPlayerId;
    _revision = player.stamp.revision;
    return true;
  }

  void _enqueue(
    List<MapFeedbackCueView> cues,
    int previousRevision,
    int revision,
  ) {
    _queue.add([
      for (final cue in cues)
        if (cue.identity.revision > previousRevision &&
            cue.identity.revision <= revision)
          cue,
    ]);
  }

  void _startPending() {
    while (_queue.isNotEmpty) {
      final batch = _queue.first;
      final particle = batch.particle;
      final text = batch.text;
      if ((particle != null &&
              _particles.activeCount >= MapEventParticlePool.maximumActive) ||
          (text != null &&
              _texts.activeCount >= MapFloatingTextPool.maximumActive)) {
        return;
      }
      _queue.removeFirst();
      if (particle != null) _particles.enqueue(particle);
      if (text != null) _texts.enqueue(text, fallbackLabel: batch.label);
      _particles.startPending();
      _texts.startPending();
    }
  }

  void setReducedMotion(bool enabled) {
    _reducedMotion = enabled;
    if (enabled) {
      _particles.skip();
      _queue.reduceMotion();
    }
    _texts.setReducedMotion(enabled);
    _startPending();
    _notifyActivity();
  }

  void setPlaybackSpeed(double speed) {
    if (!speed.isFinite || speed <= 0) {
      throw ArgumentError.value(speed, 'speed', 'must be finite and positive');
    }
    _speed = speed;
  }

  void skip() {
    _particles.skip();
    _texts.skip();
    _queue.clear();
    _notifyActivity();
  }

  void clearLayer() {
    _particles.clear();
    _texts.clear();
    _queue.reset();
    _cache = null;
    _actor = null;
    _revision = null;
    _notifyActivity();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active) return;
    _activeUpdateCount++;
    _particles.update(dt * _speed);
    _texts.update(dt * _speed);
    _startPending();
    _notifyActivity();
  }

  @override
  void render(ui.Canvas canvas) {
    _particles.render(canvas);
    _texts.render(canvas);
  }

  @override
  void onRemove() {
    clearLayer();
    super.onRemove();
  }

  void _notifyActivity() {
    final active = _particles.active || _texts.active || _queue.isNotEmpty;
    if (_active == active) return;
    _active = active;
    onActivityChanged?.call(active);
  }
}
