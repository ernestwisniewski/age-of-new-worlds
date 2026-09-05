import 'package:flutter/animation.dart';

import '../../features/map/presentation/geometry/odd_q_flat_top_geometry.dart';
import 'flame_map_camera.dart';
import 'map_movement_presentation.dart';

typedef MapMovementCameraOptions = ({
  bool focusOwn,
  bool followOwn,
  bool focusForeign,
  bool followForeign,
});

const defaultMapMovementCameraOptions = (
  focusOwn: true,
  followOwn: false,
  focusForeign: false,
  followForeign: false,
);

/// Keeps a movement at its origin until focus finishes, then tracks its sprite.
/// A newer camera generation gives control to selection or manual input.
final class MapMovementCamera implements MapMovementPresentation {
  MapMovementCamera({
    required this.camera,
    required AonwPoint origin,
    required this.point,
    required bool focus,
    required this.follow,
    required this.allowed,
    required this.onComplete,
  }) {
    if (focus) {
      camera.smoothCenterOnWorld(
        origin,
        duration: 0.28,
        curve: Curves.easeOutCubic,
      );
    } else {
      camera.cancelMotion();
    }
    _generation = camera.motionGeneration;
  }

  final FlameMapCameraController camera;
  final AonwPoint? Function() point;
  final bool follow;
  final bool Function() allowed;
  final void Function(bool interrupted) onComplete;
  late int _generation;
  bool _prepared = false;
  bool _completed = false;

  @override
  bool get ready {
    if (_completed || camera.motionGeneration != _generation) return true;
    if (!allowed()) {
      complete(interrupted: true);
      return true;
    }
    if (_prepared) return true;
    if (camera.hasMotion) return false;
    _prepared = true;
    if (follow) {
      camera.followWorldPoint(point);
      _generation = camera.motionGeneration;
    }
    return true;
  }

  @override
  void complete({required bool interrupted}) {
    if (_completed) return;
    _completed = true;
    final retainsControl = camera.motionGeneration == _generation;
    if (retainsControl) camera.cancelMotion();
    onComplete(interrupted || !retainsControl);
  }
}
