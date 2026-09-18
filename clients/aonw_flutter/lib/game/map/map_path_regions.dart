import 'dart:ui' as ui;

import 'map_canvas_clip.dart';

/// Rebuilds a single ordered batch only when the camera enters another region.
/// Whole paths and their order are retained; no regional raster clips are added.
final class MapPathRegions<T extends Object> {
  MapPathRegions._(this._paths, this._regions)
    : _visible = List.filled(_regions.length, false);

  factory MapPathRegions.empty() => MapPathRegions._(const [], const []);

  final List<(T, ui.Path)> _paths;
  final List<(ui.Rect, List<int>)> _regions;
  final List<bool> _visible;
  Map<T, ui.Path> _selected = const {};
  var _renderedRegionCount = 0;
  var _batchBuildCount = 0;
  var _selectedPathCount = 0;

  int get batchBuildCount => _batchBuildCount;
  int get regionCount => _regions.length;
  int get selectedPathCount => _selectedPathCount;
  int get totalPathCount => _paths.length;

  Map<T, ui.Path> _select(ui.Rect clip) {
    var changed = false;
    _renderedRegionCount = 0;
    for (var index = 0; index < _regions.length; index++) {
      final visible = _regions[index].$1.overlaps(clip);
      if (visible) _renderedRegionCount++;
      if (visible == _visible[index]) continue;
      _visible[index] = visible;
      changed = true;
    }
    if (changed) _rebuildBatch();
    return _selected;
  }

  void _rebuildBatch() {
    final included = List.filled(_paths.length, false);
    for (var index = 0; index < _regions.length; index++) {
      if (!_visible[index]) continue;
      for (final path in _regions[index].$2) {
        included[path] = true;
      }
    }
    final selected = <T, ui.Path>{};
    _selectedPathCount = 0;
    for (var index = 0; index < _paths.length; index++) {
      if (!included[index]) continue;
      _selectedPathCount++;
      final (key, path) = _paths[index];
      (selected[key] ??= ui.Path()).addPath(path, ui.Offset.zero);
    }
    _selected = selected;
    _batchBuildCount++;
  }
}

final class MapPathRegionBuilder<T extends Object> {
  MapPathRegionBuilder({this.padding = 5});

  static const span = 512.0;
  final double padding;
  final _paths = <(T, ui.Path)>[];
  final _regions = <(int, int), List<int>>{};

  void add(T key, ui.Path path) {
    final index = _paths.length;
    _paths.add((key, path));
    final bounds = path.getBounds().inflate(padding);
    for (
      var x = (bounds.left / span).floor();
      x <= (bounds.right / span).floor();
      x++
    ) {
      for (
        var y = (bounds.top / span).floor();
        y <= (bounds.bottom / span).floor();
        y++
      ) {
        (_regions[(x, y)] ??= []).add(index);
      }
    }
  }

  MapPathRegions<T> build() => MapPathRegions._(
    List.unmodifiable(_paths),
    List.unmodifiable([
      for (final entry in _regions.entries)
        (
          ui.Rect.fromLTWH(
            entry.key.$1 * span,
            entry.key.$2 * span,
            span,
            span,
          ),
          List<int>.unmodifiable(entry.value),
        ),
    ]),
  );
}

/// Repeated keys permit ordered passes such as road edges then asphalt.
int renderMapPathRegions<T extends Object>(
  ui.Canvas canvas,
  MapPathRegions<T> regions,
  List<(T, ui.Paint)> passes,
) {
  final paths = regions._select(mapCanvasClipBounds(canvas));
  for (final (key, paint) in passes) {
    final path = paths[key];
    if (path != null) canvas.drawPath(path, paint);
  }
  return regions._renderedRegionCount;
}
