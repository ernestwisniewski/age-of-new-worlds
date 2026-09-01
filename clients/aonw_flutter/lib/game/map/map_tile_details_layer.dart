import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../../design_system/assets/sprite_frame_id.dart';
import '../../design_system/assets/sprite_frames.dart';
import '../../features/map/presentation/camera/map_viewport_projection.dart';
import '../../features/map/presentation/geometry/odd_q_flat_top_geometry.dart';
import '../../features/map/presentation/map_palette.dart';
import '../../features/map/read_model/map_view.dart';
import 'map_display_options.dart';
import 'map_sprite_catalog.dart';
import 'map_sprite_painter.dart';
import 'static_map_layers.dart';

typedef MapTileIconPlacement = ({SpriteFrameId frameId, ui.Rect destination});

typedef MapHeightBadgePlacement = ({
  ui.Offset offset,
  ui.Paragraph foreground,
  ui.Paragraph outline,
});

abstract final class MapTileDetailLayout {
  static const terrainIconSize = 20.0;
  static const terrainSlotPadding = 2.5;
  static const terrainSlotGap = 2.0;
  static const resourceIconSize = 24.0;
  static const resourceSlotPadding = 4.0;
  static const resourceSlotGap = 4.0;
  static const _columns = 3;

  static List<ui.Rect> terrainIcons({
    required ui.Offset center,
    required int iconCount,
  }) => _icons(
    centerX: center.dx,
    topY:
        center.dy -
        _clusterHeight(
              iconCount,
              iconSize: terrainIconSize,
              slotPadding: terrainSlotPadding,
              slotGap: terrainSlotGap,
            ) *
            MapViewportProjection.perspectiveY /
            2,
    iconCount: iconCount,
    iconSize: terrainIconSize,
    slotPadding: terrainSlotPadding,
    slotGap: terrainSlotGap,
  );

  static List<ui.Rect> resourceIcons({
    required ui.Offset topCenter,
    required int iconCount,
  }) {
    final clusterHeight = _clusterHeight(
      iconCount,
      iconSize: resourceIconSize,
      slotPadding: resourceSlotPadding,
      slotGap: resourceSlotGap,
    );
    final bottomY =
        topCenter.dy +
        aonwMapHexRadius *
            math.sqrt(3) /
            2 *
            MapViewportProjection.perspectiveY;
    return _icons(
      centerX: topCenter.dx,
      topY: bottomY - clusterHeight * MapViewportProjection.perspectiveY,
      iconCount: iconCount,
      iconSize: resourceIconSize,
      slotPadding: resourceSlotPadding,
      slotGap: resourceSlotGap,
    );
  }

  static ui.Offset heightBadge({
    required ui.Offset topCenter,
    required double paragraphHeight,
  }) => ui.Offset(
    topCenter.dx - aonwMapHexRadius + 12,
    topCenter.dy - paragraphHeight / 2 * MapViewportProjection.perspectiveY,
  );

  static List<ui.Rect> _icons({
    required double centerX,
    required double topY,
    required int iconCount,
    required double iconSize,
    required double slotPadding,
    required double slotGap,
  }) {
    if (iconCount == 0) return const [];
    final columns = math.min(iconCount, _columns);
    final slotSize = iconSize + slotPadding * 2;
    final clusterWidth = slotSize * columns + (columns - 1) * slotGap;
    return List.unmodifiable([
      for (var index = 0; index < iconCount; index += 1)
        _iconRect(
          centerX: centerX,
          topY: topY,
          clusterWidth: clusterWidth,
          index: index,
          iconCount: iconCount,
          columns: columns,
          iconSize: iconSize,
          slotSize: slotSize,
          slotGap: slotGap,
        ),
    ]);
  }

  static ui.Rect _iconRect({
    required double centerX,
    required double topY,
    required double clusterWidth,
    required int index,
    required int iconCount,
    required int columns,
    required double iconSize,
    required double slotSize,
    required double slotGap,
  }) {
    final column = index % columns;
    final row = index ~/ columns;
    final rowCount = math.min(iconCount - row * columns, columns);
    final rowWidth = slotSize * rowCount + (rowCount - 1) * slotGap;
    final rowLeft = centerX - rowWidth / 2;
    final center = ui.Offset(
      rowLeft + column * (slotSize + slotGap) + slotSize / 2,
      topY +
          (row * (slotSize + slotGap) + slotSize / 2) *
              MapViewportProjection.perspectiveY,
    );
    return ui.Rect.fromCenter(
      center: center,
      width: iconSize,
      height: iconSize * MapViewportProjection.perspectiveY,
    );
  }

  static double _clusterHeight(
    int iconCount, {
    required double iconSize,
    required double slotPadding,
    required double slotGap,
  }) {
    if (iconCount == 0) return 0;
    final rows = (iconCount + _columns - 1) ~/ _columns;
    final slotSize = iconSize + slotPadding * 2;
    return slotSize * rows + (rows - 1) * slotGap;
  }
}

final class MapTileDetailsLayerComponent extends Component
    with HasGameReference<FlameGame>, HasVisibility {
  MapTileDetailsLayerComponent() : super(priority: 23) {
    isVisible = false;
  }

  static final _fallbackPaint = ui.Paint()..color = MapPalette.mapIconFallback;
  static const _outlineOffsets = [
    ui.Offset(-1, -1),
    ui.Offset(0, -1),
    ui.Offset(1, -1),
    ui.Offset(-1, 0),
    ui.Offset(1, 0),
    ui.Offset(-1, 1),
    ui.Offset(0, 1),
    ui.Offset(1, 1),
  ];

  MapDisplayOptions _options = const MapDisplayOptions();
  MapStaticRenderIdentity? _identity;
  List<MapTileIconPlacement> _terrainIcons = const [];
  List<MapTileIconPlacement> _resourceIcons = const [];
  List<MapHeightBadgePlacement> _heightBadges = const [];
  var _loadGeneration = 0;
  var _cacheUpdateCount = 0;

  @visibleForTesting
  int get debugCacheUpdateCount => _cacheUpdateCount;

  @visibleForTesting
  MapStaticRenderIdentity? get debugIdentity => _identity;

  @visibleForTesting
  int get debugTerrainIconCount => _terrainIcons.length;

  @visibleForTesting
  int get debugResourceIconCount => _resourceIcons.length;

  @visibleForTesting
  int get debugHeightBadgeCount => _heightBadges.length;

  @visibleForTesting
  MapDisplayOptions get debugOptions => _options;

  @visibleForTesting
  Future<void> debugPreloadVisibleFrames() => _preloadVisibleFrames();

  bool setOptions(MapDisplayOptions options) {
    if (_options.showTerrainIcons == options.showTerrainIcons &&
        _options.showResourceIcons == options.showResourceIcons &&
        _options.showHeightBadges == options.showHeightBadges) {
      return false;
    }
    _options = options;
    _updateVisibility();
    if (isLoaded) unawaited(_preloadVisibleFrames());
    return true;
  }

  void applyMap(MapView map, MapStaticRenderCache cache) {
    if (_identity == cache.identity) return;
    final terrainIcons = <MapTileIconPlacement>[];
    final resourceIcons = <MapTileIconPlacement>[];
    final heightBadges = <MapHeightBadgePlacement>[];
    final paragraphs = <int, (ui.Paragraph, ui.Paragraph)>{};
    for (final tile in map.tiles) {
      final centerPoint = cache.projection.hexTopFaceCenter(tile.coordinate);
      final center = ui.Offset(centerPoint.x, centerPoint.y);
      final terrains = [...tile.terrainTags]
        ..sort((left, right) => left.name.compareTo(right.name));
      final resources = [...tile.resources]
        ..sort((left, right) => left.name.compareTo(right.name));
      final terrainRects = MapTileDetailLayout.terrainIcons(
        center: center,
        iconCount: terrains.length,
      );
      final resourceRects = MapTileDetailLayout.resourceIcons(
        topCenter: center,
        iconCount: resources.length,
      );
      for (var index = 0; index < terrains.length; index += 1) {
        terrainIcons.add((
          frameId: MapSpriteCatalog.terrainFrame(terrains[index]),
          destination: terrainRects[index],
        ));
      }
      for (var index = 0; index < resources.length; index += 1) {
        resourceIcons.add((
          frameId: MapSpriteCatalog.resourceFrame(resources[index]),
          destination: resourceRects[index],
        ));
      }
      if (tile.height > 0) {
        final pair = paragraphs.putIfAbsent(
          tile.height,
          () => (
            _heightParagraph(tile.height, MapPalette.heightBadge),
            _heightParagraph(tile.height, MapPalette.heightBadgeOutline),
          ),
        );
        heightBadges.add((
          offset: MapTileDetailLayout.heightBadge(
            topCenter: center,
            paragraphHeight: pair.$1.height,
          ),
          foreground: pair.$1,
          outline: pair.$2,
        ));
      }
    }
    _identity = cache.identity;
    _terrainIcons = List.unmodifiable(terrainIcons);
    _resourceIcons = List.unmodifiable(resourceIcons);
    _heightBadges = List.unmodifiable(heightBadges);
    _cacheUpdateCount += 1;
    _updateVisibility();
    if (isLoaded) unawaited(_preloadVisibleFrames());
  }

  void clearLayer() {
    _loadGeneration += 1;
    _identity = null;
    _terrainIcons = const [];
    _resourceIcons = const [];
    _heightBadges = const [];
    isVisible = false;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    unawaited(_preloadVisibleFrames());
  }

  @override
  void render(ui.Canvas canvas) {
    if (_options.showHeightBadges) {
      for (final badge in _heightBadges) {
        for (final offset in _outlineOffsets) {
          canvas.drawParagraph(badge.outline, badge.offset + offset);
        }
        canvas.drawParagraph(badge.foreground, badge.offset);
      }
    }
    if (_options.showTerrainIcons) _drawIcons(canvas, _terrainIcons);
    if (_options.showResourceIcons) _drawIcons(canvas, _resourceIcons);
  }

  void _drawIcons(ui.Canvas canvas, List<MapTileIconPlacement> placements) {
    for (final placement in placements) {
      final frame = SpriteFrames.cached(placement.frameId);
      if (frame == null) {
        canvas.drawCircle(
          placement.destination.center,
          placement.destination.width / 2,
          _fallbackPaint,
        );
      } else {
        MapSpritePainter.paint(
          canvas,
          frame,
          destination: placement.destination,
        );
      }
    }
  }

  void _updateVisibility() {
    isVisible =
        _identity != null &&
        (_options.showTerrainIcons ||
            _options.showResourceIcons ||
            _options.showHeightBadges);
  }

  Future<void> _preloadVisibleFrames() async {
    final generation = ++_loadGeneration;
    final ids = <SpriteFrameId>{
      if (_options.showTerrainIcons)
        for (final icon in _terrainIcons) icon.frameId,
      if (_options.showResourceIcons)
        for (final icon in _resourceIcons) icon.frameId,
    };
    if (ids.isEmpty) return;
    try {
      await SpriteFrames.preload(ids);
    } on Object {
      return;
    }
    if (generation != _loadGeneration) return;
    if (isMounted && game.isAttached && game.paused) {
      game.stepEngine(stepTime: 0);
    }
  }
}

ui.Paragraph _heightParagraph(int height, ui.Color color) {
  return (ui.ParagraphBuilder(
          ui.ParagraphStyle(
            fontSize: 10,
            height: 1,
            fontWeight: ui.FontWeight.w800,
            textAlign: ui.TextAlign.center,
          ),
        )
        ..pushStyle(ui.TextStyle(color: color))
        ..addText('$height'))
      .build()
    ..layout(const ui.ParagraphConstraints(width: 18));
}
