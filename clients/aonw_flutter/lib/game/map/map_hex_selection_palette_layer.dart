import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show IconData, Icons, TextPainter, TextSpan, TextStyle;

import '../../design_system/aonw_tokens.dart';
import '../../features/map/presentation/geometry/odd_q_flat_top_geometry.dart';
import '../../features/map/presentation/input/map_hex_selection_palette_intent.dart';
import '../../features/map/presentation/map_hex_selection_palette_view.dart';
import 'map_sprite_painter.dart';
import 'static_map_layers.dart';

part 'map_hex_selection_palette_rendering.dart';

final class MapHexSelectionPaletteTapResult {
  const MapHexSelectionPaletteTapResult._({
    required this.consumed,
    this.intent,
  });

  const MapHexSelectionPaletteTapResult.ignored() : this._(consumed: false);

  const MapHexSelectionPaletteTapResult.consumed([
    MapHexSelectionPaletteIntent? intent,
  ]) : this._(consumed: true, intent: intent);

  final bool consumed;
  final MapHexSelectionPaletteIntent? intent;
}

final class MapHexSelectionPaletteLayerComponent extends Component
    with HasVisibility {
  MapHexSelectionPaletteLayerComponent() : super(priority: 100) {
    isVisible = false;
  }

  static const extent = 276.0;
  static const orbitRadius = 92.0;
  static const buttonRadius = 24.0;
  static const angleStep = math.pi / 6;
  static const _haloWidth = 62.0;
  static const _haloHeight = 48.0 * 0.62;
  MapHexSelectionPaletteView? _view;
  ui.Offset? _center;
  List<ui.Rect> _targetRects = const [];
  double _directionAngle = -math.pi / 2;
  double _screenScale = 1;

  @visibleForTesting
  MapHexSelectionPaletteView? get debugView => _view;

  @visibleForTesting
  List<ui.Rect> get debugTargetRects => List.unmodifiable(_targetRects);

  @visibleForTesting
  double get debugDirectionAngle => _directionAngle;

  @visibleForTesting
  double get debugScreenScale => _screenScale;

  void open({
    required MapStaticRenderCache cache,
    required MapHexSelectionPaletteView view,
    required double directionAngle,
    required double screenScale,
  }) {
    if (!directionAngle.isFinite || !screenScale.isFinite || screenScale <= 0) {
      throw ArgumentError('Palette geometry must be finite and positive.');
    }
    final projected = cache.projection.hexTopFaceCenter(view.coordinate);
    _view = view;
    _center = ui.Offset(projected.x, projected.y);
    _directionAngle = directionAngle;
    _screenScale = screenScale;
    _targetRects = _layoutTargets(view.targets.length);
    isVisible = true;
  }

  MapHexSelectionPaletteTapResult handleTap(AonwPoint worldPoint) {
    final view = _view;
    if (!isVisible || view == null) {
      return const MapHexSelectionPaletteTapResult.ignored();
    }
    final point = ui.Offset(worldPoint.x, worldPoint.y);
    for (var index = 0; index < _targetRects.length; index += 1) {
      if (!_targetRects[index].contains(point)) continue;
      final intent = mapHexSelectionIntentFor(view.targets[index]);
      clearLayer();
      return MapHexSelectionPaletteTapResult.consumed(intent);
    }
    clearLayer();
    return const MapHexSelectionPaletteTapResult.consumed();
  }

  void clearLayer() {
    _view = null;
    _center = null;
    _targetRects = const [];
    isVisible = false;
  }

  List<ui.Rect> _layoutTargets(int count) {
    final center = _center!;
    final orbit = orbitRadius * _screenScale;
    final radius = buttonRadius * _screenScale;
    return [
      for (var index = 0; index < count; index += 1)
        ui.Rect.fromCircle(
          center:
              center +
              ui.Offset.fromDirection(
                _directionAngle + _angularOffset(index),
                orbit,
              ),
          radius: radius,
        ),
    ];
  }

  double _angularOffset(int index) {
    if (index == 0) return 0;
    final distance = (index + 1) ~/ 2;
    return (index.isOdd ? -distance : distance) * angleStep;
  }

  @override
  void render(ui.Canvas canvas) {
    final view = _view;
    final center = _center;
    if (view == null || center == null) return;
    _paintPalette(canvas, view, center);
  }
}
