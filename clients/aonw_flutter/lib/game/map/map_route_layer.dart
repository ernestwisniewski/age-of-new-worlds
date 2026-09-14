import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../features/map/presentation/map_palette.dart';
import '../../features/map/read_model/map_view.dart';
import '../../features/map/read_model/movement_view.dart';
import '../../features/map/read_model/player_map_view.dart';
import '../../features/map/read_model/stored_unit_route_view.dart';
import 'map_canvas_clip.dart';
import 'map_interaction_geometry.dart';
import 'map_sprite_catalog.dart';
import 'map_unit_sprite_animation.dart';
import 'static_map_layers.dart';

part 'map_route_geometry.dart';
part 'map_route_motion.dart';
part 'map_route_painter.dart';
part 'map_route_stroke.dart';
part 'map_stored_route.dart';

typedef _MapRouteSegment = ({
  _MapRouteStroke stroke,
  bool reachable,
  bool followsRoad,
  bool traversed,
});

final class MapRouteLayerComponent extends Component with HasVisibility {
  MapRouteLayerComponent() : super(priority: 40) {
    isVisible = false;
  }

  RoutePlanView? _route;
  StoredUnitRouteView? _storedRoute;
  (String, MapHexCoordinate)? _storedUnit;
  MapStaticRenderIdentity? _identity;
  String? _actor;
  List<_MapRouteSegment> _segments = const [];
  List<ui.Offset> _boundaries = const [];
  _MapRouteStroke? _target;
  ui.Offset? _destination;
  bool _destinationReachable = false;
  ui.Rect _bounds = ui.Rect.zero;
  ui.Rect _motionBounds = ui.Rect.zero;
  ui.Rect _viewport = ui.Rect.zero;
  VisibleUnitKind? _ghostKind;
  MapUnitSpriteAnimation? _ghost;
  bool _animationsEnabled = true;
  bool _reducedMotion = false;
  bool _viewportActive = false;
  bool _active = false;
  double _flowPhase = 0;
  double _length = 0;
  int _pathBuildCount = 0;
  int _updates = 0;
  void Function(bool)? onActivityChanged;
  void Function()? onFrameRequested;

  bool get animationsEnabled => _animationsEnabled;

  @visibleForTesting
  int get debugPathBuildCount => _pathBuildCount;
  @visibleForTesting
  int get debugSegmentCount => _segments.length;
  @visibleForTesting
  int get debugCurrentTurnSegmentCount =>
      _segments.where((segment) => segment.reachable).length;
  @visibleForTesting
  int get debugFutureTurnSegmentCount => _segments
      .where((segment) => !segment.reachable && !segment.traversed)
      .length;
  @visibleForTesting
  int get debugBoundaryCount => _boundaries.length;
  @visibleForTesting
  int get debugTraversedSegmentCount =>
      _segments.where((segment) => segment.traversed).length;
  @visibleForTesting
  bool debugSegmentFollowsRoad(int index) => _segments[index].followsRoad;
  @visibleForTesting
  ui.Rect debugSegmentBounds(int index) => _segments[index].stroke.bounds;
  @visibleForTesting
  double get debugFlowPhase => _flowPhase;
  @visibleForTesting
  int get debugActiveUpdateCount => _updates;
  @visibleForTesting
  ui.Offset? get debugGhostPosition => _routeSample()?.position;
  @visibleForTesting
  String? get debugGhostFrameId => _ghost?.frame?.id.value;
  @visibleForTesting
  bool get debugGhostMirrored => _ghost?.mirrored ?? false;
  @visibleForTesting
  double get debugRouteLength => _length;
  @visibleForTesting
  Future<void> debugLoadGhost() async => _ghost?.load();
  @visibleForTesting
  int get debugDashBuildCount => _segments.fold(
    _target?.buildCount ?? 0,
    (count, segment) => count + segment.stroke.buildCount,
  );

  void applyRoute(
    MapStaticRenderCache cache,
    RoutePlanView? route,
    PlayerMapView player, {
    String? selectedUnitId,
  }) {
    if (route == null) {
      _applyStoredRoute(cache, player, selectedUnitId);
      return;
    }
    _storedRoute = null;
    _storedUnit = null;
    final kind = route.steps.length < 2
        ? null
        : player.units
              .where((unit) => unit.id == route.unitId)
              .firstOrNull
              ?.kind;
    final sameGeometry =
        _identity == cache.identity &&
        _actor == player.actorPlayerId &&
        _sameRoute(_route, route);
    _route = route;
    _identity = cache.identity;
    _actor = player.actorPlayerId;
    if (sameGeometry) {
      _setGhostKind(kind);
      return;
    }
    _flowPhase = 0;
    if (route.steps.length < 2) {
      _clearGeometry();
      return;
    }
    _buildGeometry(cache, route);
    _setGhostKind(kind);
    _resetGhost();
    _refreshActivity();
  }

  void clearLayer() {
    _route = null;
    _storedRoute = null;
    _storedUnit = null;
    _identity = null;
    _actor = null;
    _clearGeometry();
  }

  void _clearGeometry() {
    _segments = const [];
    _boundaries = const [];
    _target = null;
    _destination = null;
    _destinationReachable = false;
    _bounds = ui.Rect.zero;
    _motionBounds = ui.Rect.zero;
    _length = 0;
    _flowPhase = 0;
    _setGhostKind(null);
    isVisible = false;
    _refreshActivity();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active || !dt.isFinite || dt <= 0) return;
    _updates++;
    _flowPhase = (_flowPhase + dt * 24) % 10000;
    _advanceGhost(dt);
  }

  @override
  void render(ui.Canvas canvas) => _paintRoute(canvas);

  @override
  void onRemove() {
    clearLayer();
    super.onRemove();
  }
}
