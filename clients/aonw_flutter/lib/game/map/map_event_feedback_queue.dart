import 'dart:collection';

import '../../features/map/presentation/map_feedback_labels.dart';
import '../../features/map/read_model/map_feedback_view.dart';
import '../../features/map/read_model/player_map_view.dart';

/// Keeps the particle and text of one event together while capacity is occupied.
final class MapEventFeedbackBatch {
  const MapEventFeedbackBatch({this.particle, this.text, this.label});
  final MapParticleCueView? particle;
  final MapFloatingTextCueView? text;
  final String? label;
  bool get empty => particle == null && text == null;

  MapEventFeedbackBatch filtered(
    MapFogView fog,
    MapFeedbackLabels labels,
    bool reducedMotion,
  ) {
    final p = particle;
    final t = text;
    return MapEventFeedbackBatch(
      particle:
          p != null &&
              !reducedMotion &&
              fog.visibilityAt(p.coordinate) == MapFogVisibilityView.visible
          ? p
          : null,
      text:
          t != null &&
              fog.visibilityAt(t.coordinate) == MapFogVisibilityView.visible
          ? t
          : null,
      label: t == null ? null : labels.labelFor(t.identity) ?? label,
    );
  }
}

final class MapEventFeedbackQueue {
  static const maximumPending = 64;
  final _pending = Queue<MapEventFeedbackBatch>();
  MapFogView? _fog;
  MapFeedbackLabels _labels = const MapFeedbackLabels.empty();
  bool _reducedMotion = false;
  bool get isNotEmpty => _pending.isNotEmpty;
  MapEventFeedbackBatch get first => _pending.first;
  int get particleCount =>
      _pending.where((batch) => batch.particle != null).length;
  int get textCount => _pending.where((batch) => batch.text != null).length;

  void applyContext(
    MapFogView fog,
    MapFeedbackLabels labels,
    bool reducedMotion,
  ) {
    _fog = fog;
    _labels = labels;
    _reducedMotion = reducedMotion;
    final retained = [
      for (final batch in _pending) batch.filtered(fog, labels, reducedMotion),
    ];
    _pending
      ..clear()
      ..addAll(retained.where((batch) => !batch.empty));
  }

  void add(List<MapFeedbackCueView> cues) {
    final fog = _fog;
    if (fog == null) return;
    final batches = <MapEventIdentityView, MapEventFeedbackBatch>{};
    for (final cue in cues) {
      final previous = batches[cue.identity];
      batches[cue.identity] = switch (cue) {
        MapParticleCueView() => MapEventFeedbackBatch(
          particle: cue,
          text: previous?.text,
          label: previous?.label,
        ),
        MapFloatingTextCueView() => _withText(previous, cue),
      };
    }
    for (final batch in batches.values) {
      final value = batch.filtered(fog, _labels, _reducedMotion);
      if (value.empty) continue;
      if (_pending.length == maximumPending) _pending.removeFirst();
      _pending.add(value);
    }
  }

  MapEventFeedbackBatch _withText(
    MapEventFeedbackBatch? previous,
    MapFloatingTextCueView cue,
  ) {
    final label = _labels.labelFor(cue.identity);
    return MapEventFeedbackBatch(
      particle: previous?.particle,
      text: label == null || label.isEmpty ? null : cue,
      label: label,
    );
  }

  void reduceMotion() {
    final fog = _fog;
    if (fog != null) applyContext(fog, _labels, true);
  }

  void removeFirst() => _pending.removeFirst();
  void clear() => _pending.clear();

  void reset() {
    clear();
    _fog = null;
    _labels = const MapFeedbackLabels.empty();
    _reducedMotion = false;
  }
}
