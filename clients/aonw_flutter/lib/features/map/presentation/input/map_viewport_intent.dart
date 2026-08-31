import '../../read_model/map_view.dart';
import '../geometry/odd_q_flat_top_geometry.dart';

sealed class MapViewportIntent {
  const MapViewportIntent();
}

final class MapHoverIntent extends MapViewportIntent {
  const MapHoverIntent(this.screenPosition);

  final AonwPoint screenPosition;
}

final class MapSelectIntent extends MapViewportIntent {
  const MapSelectIntent(this.screenPosition);

  final AonwPoint screenPosition;
}

final class MapPanIntent extends MapViewportIntent {
  const MapPanIntent(this.screenDelta);

  final AonwPoint screenDelta;
}

final class MapZoomIntent extends MapViewportIntent {
  const MapZoomIntent({required this.focalPoint, required this.factor});

  final AonwPoint focalPoint;
  final double factor;
}

/// Coalesced pointer state emitted at most once per Flame update.
final class MapViewportFrameIntent extends MapViewportIntent {
  const MapViewportFrameIntent({
    required this.screenPanDelta,
    required this.zoomFocalPoint,
    required this.zoomFactor,
    required this.hoverScreenPosition,
  });

  final AonwPoint screenPanDelta;
  final AonwPoint? zoomFocalPoint;
  final double zoomFactor;
  final AonwPoint? hoverScreenPosition;
}

sealed class MapHexIntent {
  const MapHexIntent(this.coordinate);

  final MapHexCoordinate? coordinate;
}

final class MapHexHoverIntent extends MapHexIntent {
  const MapHexHoverIntent(super.coordinate);
}

final class MapHexSelectIntent extends MapHexIntent {
  const MapHexSelectIntent(super.coordinate);
}

typedef MapViewportIntentSink = void Function(MapViewportIntent intent);
typedef MapHexIntentSink = void Function(MapHexIntent intent);
