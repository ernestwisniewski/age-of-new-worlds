import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show FontWeight, TextPainter, TextSpan, TextStyle;

import '../../design_system/aonw_tokens.dart';
import '../../design_system/assets/sprite_frames.dart';
import '../../features/map/presentation/geometry/odd_q_flat_top_geometry.dart';
import '../../features/map/presentation/input/map_action_palette_intent.dart';
import '../../features/map/presentation/map_action_palette_view.dart';
import 'map_sprite_catalog.dart';
import 'map_sprite_painter.dart';
import 'static_map_layers.dart';

part 'map_action_palette_rendering.dart';

final class MapActionPaletteTapResult {
  const MapActionPaletteTapResult._({required this.consumed, this.intent});

  const MapActionPaletteTapResult.ignored() : this._(consumed: false);

  const MapActionPaletteTapResult.consumed([MapActionPaletteIntent? intent])
    : this._(consumed: true, intent: intent);

  final bool consumed;
  final MapActionPaletteIntent? intent;
}

final class MapActionPaletteLayerComponent extends Component
    with HasVisibility, HasGameReference<FlameGame> {
  MapActionPaletteLayerComponent() : super(priority: 80) {
    isVisible = false;
  }

  static const iconSize = 44.0;
  static const iconGap = 6.0;
  static const barPaddingX = 12.0;
  static const barPaddingY = 8.0;
  static const barRadius = 10.0;
  static const previewPanelGap = 6.0;
  static const previewPanelHeight = 92.0;
  static const minPreviewWidth = 228.0;
  static const _workerVerticalOffset = 82.0;
  static const _pillMinWidth = 58.0;
  static const _pillMaxWidth = 172.0;
  static const _pillHeight = 42.0;
  static const _pillPanelHeight = 28.0;
  MapActionPaletteView? _view;
  String? _viewKey;
  String? _dismissedKey;
  ui.Rect? _bounds;
  List<ui.Rect> _optionRects = const [];
  ui.Rect? _previewPanelRect;
  ui.Rect? _ctaRect;
  var _framesScope = SpriteFrames.createScope();
  var _loadGeneration = 0;
  @visibleForTesting
  MapActionPaletteView? get debugView => _view;
  @visibleForTesting
  ui.Rect? get debugBounds => _bounds;
  @visibleForTesting
  List<ui.Rect> get debugOptionRects => List.unmodifiable(_optionRects);
  @visibleForTesting
  ui.Rect? get debugCtaRect => _ctaRect;
  void applyPalette(MapStaticRenderCache cache, MapActionPaletteView? view) {
    _view = view;
    final nextKey = _keyFor(view);
    _viewKey = nextKey;
    if (view == null || nextKey == _dismissedKey) {
      _clearGeometry();
      return;
    }
    _layout(cache, view);
    if (view is MapWorkerActionPaletteView) {
      _preload(view);
    } else {
      _releaseFrames();
    }
  }

  MapActionPaletteTapResult handleTap(AonwPoint worldPoint) {
    if (!isVisible || _view == null) {
      return const MapActionPaletteTapResult.ignored();
    }
    final point = ui.Offset(worldPoint.x, worldPoint.y);
    final view = _view!;
    if (!(_bounds?.contains(point) ?? false)) {
      _dismissedKey = _viewKey;
      _clearGeometry();
      return const MapActionPaletteTapResult.consumed();
    }
    if (!view.enabled) return const MapActionPaletteTapResult.consumed();
    switch (view) {
      case MapMovePreviewPillView():
        _clearGeometry();
        return const MapActionPaletteTapResult.consumed(
          ConfirmMapMovePaletteIntent(),
        );
      case MapWorkerActionPaletteView():
        for (var index = 0; index < _optionRects.length; index += 1) {
          if (!_optionRects[index].contains(point)) continue;
          return MapActionPaletteTapResult.consumed(
            PreviewWorkerImprovementPaletteIntent(
              unitId: view.unitId,
              improvement: view.options[index].improvement,
            ),
          );
        }
        if (_ctaRect?.contains(point) ?? false) {
          final improvement = view.previewedImprovement;
          if (improvement != null) {
            _clearGeometry();
            return MapActionPaletteTapResult.consumed(
              ConfirmWorkerImprovementPaletteIntent(
                unitId: view.unitId,
                improvement: improvement,
              ),
            );
          }
        }
        return const MapActionPaletteTapResult.consumed();
    }
  }

  void clearLayer() {
    _view = null;
    _viewKey = null;
    _dismissedKey = null;
    _clearGeometry();
  }

  void _layout(MapStaticRenderCache cache, MapActionPaletteView view) {
    final projected = cache.projection.hexTopFaceCenter(view.coordinate);
    final anchor = ui.Offset(projected.x, projected.y);
    switch (view) {
      case MapMovePreviewPillView(:final label):
        final width = _measurePillWidth(label);
        _bounds = ui.Rect.fromLTWH(
          anchor.dx - width / 2,
          anchor.dy - _pillHeight,
          width,
          _pillHeight,
        );
        _optionRects = const [];
        _previewPanelRect = null;
        _ctaRect = null;
      case MapWorkerActionPaletteView():
        _layoutWorker(anchor.translate(0, -_workerVerticalOffset), view);
    }
    isVisible = true;
  }

  void _layoutWorker(ui.Offset anchor, MapWorkerActionPaletteView view) {
    final rowWidth =
        view.options.length * iconSize +
        math.max(0, view.options.length - 1) * iconGap;
    final hasPreview = view.previewedImprovement != null;
    final width = math.max<double>(
      rowWidth + barPaddingX * 2,
      hasPreview ? minPreviewWidth : 0,
    );
    final height =
        barPaddingY * 2 +
        iconSize +
        (hasPreview ? previewPanelGap + previewPanelHeight : 0);
    final bounds = ui.Rect.fromCenter(
      center: anchor,
      width: width,
      height: height,
    );
    _bounds = bounds;
    final x = bounds.left + (width - rowWidth) / 2;
    _optionRects = [
      for (var index = 0; index < view.options.length; index += 1)
        ui.Rect.fromLTWH(
          x + index * (iconSize + iconGap),
          bounds.top + barPaddingY,
          iconSize,
          iconSize,
        ),
    ];
    if (!hasPreview) {
      _previewPanelRect = null;
      _ctaRect = null;
      return;
    }
    final preview = ui.Rect.fromLTWH(
      bounds.left + barPaddingX,
      bounds.top + barPaddingY + iconSize + previewPanelGap,
      width - barPaddingX * 2,
      previewPanelHeight,
    );
    _previewPanelRect = preview;
    _ctaRect = ui.Rect.fromLTWH(
      preview.right - math.min(126, preview.width - 24) - 12,
      preview.bottom - 34,
      math.min(126, preview.width - 24),
      24,
    );
  }

  @override
  void onRemove() {
    clearLayer();
    _framesScope.dispose();
    super.onRemove();
  }

  void _releaseFrames() {
    _loadGeneration++;
    _framesScope.dispose();
    _framesScope = SpriteFrames.createScope();
  }

  void _clearGeometry() {
    _releaseFrames();
    _bounds = null;
    _optionRects = const [];
    _previewPanelRect = null;
    _ctaRect = null;
    isVisible = false;
  }

  @override
  void render(ui.Canvas canvas) {
    final view = _view;
    if (view == null) return;
    switch (view) {
      case MapMovePreviewPillView():
        _paintMovePill(canvas, view);
      case MapWorkerActionPaletteView():
        _paintWorkerPalette(canvas, view);
    }
  }

  String? _keyFor(MapActionPaletteView? view) => switch (view) {
    null => null,
    MapMovePreviewPillView() =>
      'move:${view.coordinate.col}:${view.coordinate.row}:${view.label}:${view.enabled}',
    MapWorkerActionPaletteView() =>
      'worker:${view.unitId}:${view.previewedImprovement?.name}:${view.enabled}:'
          '${view.options.map((option) => option.improvement.name).join(',')}',
  };

  void _preload(MapWorkerActionPaletteView view) {
    final generation = ++_loadGeneration;
    unawaited(
      _framesScope
          .preload([
            for (final option in view.options)
              MapSpriteCatalog.improvementFrame(option.improvement),
          ])
          .then((_) {
            if (generation != _loadGeneration || !isMounted) return;
            if (game.isAttached && game.paused) game.stepEngine(stepTime: 0);
          })
          .catchError((Object _) {}),
    );
  }
}
