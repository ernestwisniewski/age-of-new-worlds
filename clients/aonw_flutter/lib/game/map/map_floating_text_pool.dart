import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../../features/map/presentation/map_feedback_labels.dart';
import '../../features/map/read_model/map_feedback_view.dart';
import '../../features/map/read_model/map_view.dart';
import '../../features/map/read_model/player_map_view.dart';
import 'map_floating_text.dart';
import 'static_map_layers.dart';

final class MapFloatingTextPool {
  MapFloatingTextPool({ui.Offset? Function(String unitId)? unitPositionFor})
    : _unitPositionFor = unitPositionFor;

  static const maximumActive = 8;
  static const maximumPending = 64;
  final ui.Offset? Function(String unitId)? _unitPositionFor;
  final _pool = List.generate(maximumActive, (_) => MapFloatingText());
  final _pending = Queue<(MapFloatingTextCueView, String)>();
  final _recentSpawns = <(MapHexCoordinate, String), List<(double, int)>>{};
  MapStaticRenderCache? _cache;
  MapFogView? _fog;
  MapFeedbackLabels _labels = const MapFeedbackLabels.empty();
  double _clock = 0;
  bool _reducedMotion = false;
  int renderedCount = 0;

  int get activeCount => _pool.where((text) => text.active).length;
  int get visibleCount =>
      _pool.where((text) => text.ready && text.placed).length;
  int get imageCount => _pool.where((text) => text.hasImage).length;
  int get pendingCount => _pending.length;
  bool get active => _pending.isNotEmpty || _pool.any((text) => text.active);

  @visibleForTesting
  ui.Offset? debugPositionFor(MapEventIdentityView identity) => _pool
      .where((text) => text.cue?.identity == identity)
      .firstOrNull
      ?.position;

  void applyContext(
    MapStaticRenderCache cache,
    MapFogView fog,
    MapFeedbackLabels labels,
  ) {
    _cache = cache;
    _fog = fog;
    _labels = labels;
    _pending.removeWhere((entry) => !_visible(entry.$1));
    for (final text in _pool) {
      final cue = text.cue;
      if (cue == null) continue;
      if (!_visible(cue)) {
        text.clear();
      } else {
        final label = labels.labelFor(cue.identity);
        if (label != null) text.relabel(label);
      }
    }
  }

  void enqueue(MapFloatingTextCueView cue, {String? fallbackLabel}) {
    final label = _labels.labelFor(cue.identity) ?? fallbackLabel;
    if (!_visible(cue) || label == null || label.isEmpty) return;
    if (_pending.length == maximumPending) _pending.removeFirst();
    _pending.add((cue, label));
  }

  void startPending() {
    for (final text in _pool) {
      if (_pending.isEmpty) break;
      if (text.active) continue;
      final (cue, label) = _pending.removeFirst();
      text.start(cue, _labels.labelFor(cue.identity) ?? label);
    }
    _placeReady();
  }

  void update(double dt) {
    _clock += dt;
    for (final text in _pool) {
      text.update(dt);
    }
    startPending();
  }

  void _placeReady() {
    final cache = _cache;
    if (cache == null) return;
    for (final text in _pool) {
      final cue = text.cue;
      if (cue == null || !text.ready || text.placed) continue;
      final center = cache.projection.hexCenter(cue.coordinate);
      final cityCenter = cache.projection.hexTopFaceCenter(cue.coordinate);
      final tile = ui.Offset(center.x, center.y);
      final position = switch (cue.anchor) {
        MapTileTextAnchorView() => tile.translate(0, -28),
        MapCityTextAnchorView() => ui.Offset(cityCenter.x, cityCenter.y - 64),
        MapUnitTextAnchorView(:final unitId) =>
          (_unitPositionFor?.call(unitId) ?? tile.translate(0, -12)).translate(
            0,
            -82,
          ),
      };
      text.place(position.translate(0, _reserveStackSlot(cue) * 12));
    }
  }

  int _reserveStackSlot(MapFloatingTextCueView cue) {
    for (final entries in _recentSpawns.values) {
      entries.removeWhere((entry) => _clock - entry.$1 >= 0.5);
    }
    _recentSpawns.removeWhere((_, entries) => entries.isEmpty);
    final anchor = switch (cue.anchor) {
      MapTileTextAnchorView() => 'tile',
      MapUnitTextAnchorView(:final unitId) => 'unit:$unitId',
      MapCityTextAnchorView(:final cityId) => 'city:$cityId',
    };
    final entries = _recentSpawns.putIfAbsent((
      cue.coordinate,
      anchor,
    ), () => []);
    final used = {for (final entry in entries) entry.$2};
    var slot = 0;
    while (used.contains(slot)) {
      slot++;
    }
    entries.add((_clock, slot));
    return slot;
  }

  void setReducedMotion(bool enabled) => _reducedMotion = enabled;

  void render(ui.Canvas canvas) {
    renderedCount = 0;
    for (final text in _pool) {
      if (text.render(canvas, reducedMotion: _reducedMotion)) renderedCount++;
    }
  }

  void skip() {
    _pending.clear();
    _recentSpawns.clear();
    for (final text in _pool) {
      text.clear();
    }
  }

  void clear() {
    skip();
    _cache = null;
    _fog = null;
    _labels = const MapFeedbackLabels.empty();
    _clock = 0;
    renderedCount = 0;
  }

  bool _visible(MapFloatingTextCueView cue) =>
      _fog?.visibilityAt(cue.coordinate) == MapFogVisibilityView.visible;
}
