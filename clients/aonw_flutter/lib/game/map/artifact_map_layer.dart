import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../features/artifacts/read_model/artifact_view.dart';
import '../../features/map/presentation/map_palette.dart';
import '../../features/map/read_model/map_view.dart';
import '../presentation/flame_scene_patch.dart';
import 'static_map_layers.dart';

final class MapArtifactLayerComponent extends Component with HasVisibility {
  MapArtifactLayerComponent() : super(priority: 47) {
    isVisible = false;
  }

  final _artifactsById = <String, MapArtifactComponent>{};
  var _createdCount = 0;
  var _updatedCount = 0;
  var _removedCount = 0;

  @visibleForTesting
  int get debugArtifactCount => _artifactsById.length;

  @visibleForTesting
  int get debugCreatedCount => _createdCount;

  @visibleForTesting
  int get debugUpdatedCount => _updatedCount;

  @visibleForTesting
  int get debugRemovedCount => _removedCount;

  @visibleForTesting
  int get debugSharedPaintCount => MapArtifactComponent.sharedPaintCount;

  @visibleForTesting
  MapArtifactComponent? debugComponentForArtifact(String artifactId) =>
      _artifactsById[artifactId];

  void applyPatch(FlameScenePatch patch, MapStaticRenderCache cache) {
    for (final artifactId in patch.removedArtifactIds) {
      _remove(artifactId);
    }
    for (final artifact in patch.artifactUpserts) {
      final coordinate = _visibleCoordinate(artifact.location);
      if (coordinate == null) {
        _remove(artifact.id);
        continue;
      }
      final center = _center(cache, coordinate);
      final existing = _artifactsById[artifact.id];
      if (existing == null) {
        final component = MapArtifactComponent(
          artifact: artifact,
          center: center,
        );
        _artifactsById[artifact.id] = component;
        add(component);
        _createdCount += 1;
      } else {
        existing.applyArtifact(artifact, center: center);
        _updatedCount += 1;
      }
    }
    isVisible = _artifactsById.isNotEmpty;
  }

  void clearLayer() {
    for (final component in _artifactsById.values) {
      component.removeFromParent();
    }
    _artifactsById.clear();
    isVisible = false;
  }

  void _remove(String artifactId) {
    final component = _artifactsById.remove(artifactId);
    if (component == null) return;
    component.removeFromParent();
    _removedCount += 1;
  }

  static MapHexCoordinate? _visibleCoordinate(ArtifactLocationView location) =>
      switch (location) {
        MapArtifactLocationView(:final coordinate) => coordinate,
        ExcavationArtifactLocationView(:final coordinate) => coordinate,
        CarriedArtifactLocationView() || StoredArtifactLocationView() => null,
      };

  static ui.Offset _center(
    MapStaticRenderCache cache,
    MapHexCoordinate coordinate,
  ) {
    final center = cache.geometry.center(coordinate);
    final bounds = cache.geometry.bounds;
    return ui.Offset(center.x - bounds.x, center.y - bounds.y);
  }
}

final class MapArtifactComponent extends PositionComponent {
  MapArtifactComponent({
    required WorldArtifactView artifact,
    required ui.Offset center,
  }) : _artifact = artifact,
       super(
         position: Vector2(center.dx, center.dy),
         size: Vector2.all(_diameter),
         anchor: Anchor.center,
       );

  static const _diameter = 30.0;
  static final ui.Paint _mapPaint = ui.Paint()..color = MapPalette.artifact;
  static final ui.Paint _excavationPaint = ui.Paint()
    ..color = MapPalette.artifactExcavation;
  static final ui.Paint _outlinePaint = ui.Paint()
    ..color = MapPalette.artifactOutline
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2;
  static const sharedPaintCount = 3;

  WorldArtifactView _artifact;

  @visibleForTesting
  WorldArtifactView get debugArtifact => _artifact;

  void applyArtifact(WorldArtifactView artifact, {required ui.Offset center}) {
    _artifact = artifact;
    position.setValues(center.dx, center.dy);
  }

  @override
  void render(ui.Canvas canvas) {
    const center = ui.Offset(_diameter / 2, _diameter / 2);
    final path = ui.Path()
      ..moveTo(center.dx, 2)
      ..lineTo(_diameter - 2, center.dy)
      ..lineTo(center.dx, _diameter - 2)
      ..lineTo(2, center.dy)
      ..close();
    final excavation = _artifact.location is ExcavationArtifactLocationView;
    canvas.drawPath(path, excavation ? _excavationPaint : _mapPaint);
    canvas.drawPath(path, _outlinePaint);
  }
}
