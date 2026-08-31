import 'dart:ui' as ui;

import 'sprite_frame_id.dart';

final class SpriteFrame {
  const SpriteFrame({
    required this.id,
    required this.image,
    required this.source,
    required this.originalSize,
    required this.trimOffset,
    required this.pivot,
    required this.contentBounds,
    required this.statusTop,
  });

  final SpriteFrameId id;
  final ui.Image image;
  final ui.Rect source;
  final ui.Size originalSize;
  final ui.Offset trimOffset;
  final ui.Offset pivot;
  final ui.Rect contentBounds;
  final double statusTop;

  SpriteFrameGeometry geometryFor({
    required ui.Rect logicalSource,
    required ui.Rect destination,
  }) {
    final visibleLogicalRect = trimOffset & source.size;
    final visible = logicalSource.intersect(visibleLogicalRect);
    if (visible.isEmpty || logicalSource.isEmpty || destination.isEmpty) {
      return const SpriteFrameGeometry(
        source: ui.Rect.zero,
        destination: ui.Rect.zero,
      );
    }
    final scaleX = destination.width / logicalSource.width;
    final scaleY = destination.height / logicalSource.height;
    return SpriteFrameGeometry(
      source: ui.Rect.fromLTWH(
        source.left + visible.left - visibleLogicalRect.left,
        source.top + visible.top - visibleLogicalRect.top,
        visible.width,
        visible.height,
      ),
      destination: ui.Rect.fromLTWH(
        destination.left + (visible.left - logicalSource.left) * scaleX,
        destination.top + (visible.top - logicalSource.top) * scaleY,
        visible.width * scaleX,
        visible.height * scaleY,
      ),
    );
  }
}

final class SpriteFrameGeometry {
  const SpriteFrameGeometry({required this.source, required this.destination});

  final ui.Rect source;
  final ui.Rect destination;
}

abstract interface class SpriteFrameRepository {
  SpriteFrame? cached(SpriteFrameId id);

  Future<SpriteFrame> load(SpriteFrameId id);

  Future<void> preload(Iterable<SpriteFrameId> ids);

  void disposeAtlas(String atlasId);

  void dispose();
}
