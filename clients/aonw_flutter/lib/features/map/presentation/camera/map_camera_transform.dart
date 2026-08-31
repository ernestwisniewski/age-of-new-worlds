import '../geometry/odd_q_flat_top_geometry.dart';

typedef MapViewportSize = ({double width, double height});

/// Framework-neutral camera state shared by the Canvas oracle and Flame.
///
/// [worldCenter] is expressed in map-local coordinates where the rendered map
/// starts at `(0, 0)`. Screen coordinates are logical pixels relative to the
/// viewport, so device pixel ratio never enters picking math.
final class MapCameraTransform {
  static const minSupportedZoom = 0.2;
  static const maxSupportedZoom = 5.0;

  const MapCameraTransform._({
    required this.viewport,
    required this.content,
    required this.worldCenter,
    required this.zoom,
    required this.minZoom,
    required this.maxZoom,
  });

  factory MapCameraTransform.initial({
    required MapViewportSize viewport,
    required MapViewportSize content,
    required double authoredZoom,
    AonwPoint? worldCenter,
  }) {
    return MapCameraTransform._(
      viewport: viewport,
      content: content,
      worldCenter: worldCenter ?? (x: content.width / 2, y: content.height / 2),
      zoom: authoredZoom.clamp(minSupportedZoom, maxSupportedZoom).toDouble(),
      minZoom: minSupportedZoom,
      maxZoom: maxSupportedZoom,
    );
  }

  final MapViewportSize viewport;
  final MapViewportSize content;
  final AonwPoint worldCenter;
  final double zoom;
  final double minZoom;
  final double maxZoom;

  AonwPoint screenToWorld(AonwPoint screenPoint) => (
    x: worldCenter.x + (screenPoint.x - viewport.width / 2) / zoom,
    y: worldCenter.y + (screenPoint.y - viewport.height / 2) / zoom,
  );

  AonwPoint worldToScreen(AonwPoint worldPoint) => (
    x: (worldPoint.x - worldCenter.x) * zoom + viewport.width / 2,
    y: (worldPoint.y - worldCenter.y) * zoom + viewport.height / 2,
  );

  MapCameraTransform panByScreen(AonwPoint delta) => _copyWith(
    worldCenter: (
      x: worldCenter.x - delta.x / zoom,
      y: worldCenter.y - delta.y / zoom,
    ),
  );

  MapCameraTransform zoomAtScreen({
    required AonwPoint focalPoint,
    required double factor,
  }) {
    if (!factor.isFinite || factor <= 0) return this;
    final worldBefore = screenToWorld(focalPoint);
    final nextZoom = (zoom * factor).clamp(minZoom, maxZoom).toDouble();
    final nextCenter = (
      x: worldBefore.x - (focalPoint.x - viewport.width / 2) / nextZoom,
      y: worldBefore.y - (focalPoint.y - viewport.height / 2) / nextZoom,
    );
    return _copyWith(worldCenter: nextCenter, zoom: nextZoom);
  }

  MapCameraTransform centeredAt(AonwPoint point) =>
      _copyWith(worldCenter: point);

  MapCameraTransform resized(MapViewportSize nextViewport) =>
      MapCameraTransform._(
        viewport: nextViewport,
        content: content,
        worldCenter: worldCenter,
        zoom: zoom,
        minZoom: minZoom,
        maxZoom: maxZoom,
      );

  MapCameraTransform _copyWith({AonwPoint? worldCenter, double? zoom}) =>
      MapCameraTransform._(
        viewport: viewport,
        content: content,
        worldCenter: worldCenter ?? this.worldCenter,
        zoom: zoom ?? this.zoom,
        minZoom: minZoom,
        maxZoom: maxZoom,
      );
}
