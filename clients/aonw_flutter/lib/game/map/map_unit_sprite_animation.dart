import 'dart:async';
import 'dart:ui' as ui;

import '../../design_system/assets/sprite_animation_adjustments.dart';
import '../../design_system/assets/sprite_frame_id.dart';
import '../../design_system/assets/sprite_frame_repository.dart';
import '../../design_system/assets/sprite_frames.dart';
import '../../features/map/read_model/player_map_view.dart';
import 'map_sprite_catalog.dart';

enum MapUnitSpriteAction { idle, walk }

/// Owns unit poses, direction and authored frame geometry.
final class MapUnitSpriteAnimation {
  MapUnitSpriteAnimation({
    required VisibleUnitKind kind,
    required this.onLoaded,
  }) : _kind = kind;

  final void Function() onLoaded;
  VisibleUnitKind _kind;
  final _frames = <MapUnitSpriteAction, List<SpriteFrame>>{};
  final _pending = <MapUnitSpriteAction, Future<void>>{};
  var _adjustments = SpriteAnimationAdjustments.empty;
  var _generation = 0;
  var _disposed = false;
  var _action = MapUnitSpriteAction.idle;
  var _index = 0;
  var _elapsed = 0.0;
  var _mirrored = false;
  SpriteFrame? _geometryFrame;
  ui.Rect? _geometryDestination;
  SpriteFrameGeometry? _geometry;

  MapUnitSpriteAction get action => _action;
  bool get mirrored => _mirrored;
  int get index => _index;
  SpriteSequenceId get _sequence => _sequenceFor(_action);
  SpriteFrame? get frame => _frames[_action]?[_index];
  double get frameDuration => _adjustments.frameDuration(
    _sequence,
    _action == MapUnitSpriteAction.idle ? 0.9 : 0.14,
  );

  Future<void> load() async {
    await Future.wait([
      _loadAction(MapUnitSpriteAction.idle),
      _loadAction(MapUnitSpriteAction.walk),
    ]);
  }

  void setKind(VisibleUnitKind kind) {
    if (_kind == kind || _disposed) return;
    _generation++;
    _kind = kind;
    _frames.clear();
    _geometryFrame = null;
    _pending.clear();
    _action = MapUnitSpriteAction.idle;
    _index = 0;
    _elapsed = 0;
    _mirrored = false;
    unawaited(load());
  }

  void playIdle() => _play(MapUnitSpriteAction.idle);

  void playWalkToward(ui.Offset from, ui.Offset to) {
    final dx = to.dx - from.dx;
    if (dx.abs() > 0.001) _mirrored = dx < 0;
    _play(MapUnitSpriteAction.walk);
  }

  void _play(MapUnitSpriteAction action) {
    if (_disposed || _action == action) return;
    _action = action;
    _index = 0;
    _elapsed = 0;
    unawaited(_loadAction(action));
  }

  void advance(double dt) {
    if (_disposed || !dt.isFinite || dt <= 0) return;
    _elapsed += dt;
    final count = (_elapsed / frameDuration).floor();
    _elapsed -= count * frameDuration;
    _index = (_index + count) % MapSpriteCatalog.unitFrameCount;
  }

  void paint(ui.Canvas canvas, ui.Rect destination) {
    final current = frame;
    if (current == null) return;
    final geometry = _geometryFor(current, destination);
    if (geometry.source.isEmpty || geometry.destination.isEmpty) return;
    canvas.save();
    if (_mirrored) {
      canvas
        ..translate(destination.left + destination.right, 0)
        ..scale(-1, 1);
    }
    canvas
      ..clipRect(destination)
      ..drawImageRect(
        current.image,
        geometry.source,
        geometry.destination,
        _paint,
      )
      ..restore();
  }

  double? statusTopOffset(ui.Size size) {
    final current = frame;
    if (current == null) return null;
    final metrics = MapSpriteCatalog.unitMetrics(_kind);
    final offset = _adjustments
        .forFrame(_sequence, _index)
        .scaledOffset(ui.Size(metrics.width, metrics.height), size);
    return offset.dy +
        current.statusTop / current.originalSize.height * size.height;
  }

  SpriteFrameGeometry _geometryFor(SpriteFrame current, ui.Rect destination) {
    if (identical(_geometryFrame, current) &&
        _geometryDestination == destination) {
      return _geometry!;
    }
    _geometryFrame = current;
    _geometryDestination = destination;
    final metrics = MapSpriteCatalog.unitMetrics(_kind);
    return _geometry = _adjustments
        .forFrame(_sequence, _index)
        .geometryFor(
          current,
          baseSize: ui.Size(metrics.width, metrics.height),
          destination: destination,
        );
  }

  Future<void> _loadAction(MapUnitSpriteAction action) {
    if (_disposed || _frames.containsKey(action)) return Future.value();
    return _pending[action] ??= _readAction(action);
  }

  Future<void> _readAction(MapUnitSpriteAction action) async {
    final generation = _generation;
    final sequence = _sequenceFor(action);
    try {
      final frames = await Future.wait([
        for (var index = 0; index < MapSpriteCatalog.unitFrameCount; index++)
          SpriteFrames.load(sequence.frame(index)),
      ]);
      final adjustments = await SpriteAnimationAdjustments.load();
      if (_disposed || generation != _generation) return;
      _adjustments = adjustments;
      _frames[action] = List.unmodifiable(frames);
      if (_action == action) onLoaded();
    } on Object {
      // The unit's vector marker remains available if its atlas cannot load.
    } finally {
      if (generation == _generation) _pending.remove(action);
    }
  }

  SpriteSequenceId _sequenceFor(MapUnitSpriteAction action) =>
      SpriteSequenceId('unit.${_kind.name}.${action.name}');

  void dispose() {
    _disposed = true;
    _generation++;
    _frames.clear();
    _geometryFrame = null;
    _pending.clear();
  }

  static final _paint = ui.Paint()..filterQuality = ui.FilterQuality.medium;
}
