part of 'aonw_flame_game.dart';

extension AonwFlameGameCamera on AonwFlameGame {
  void _handleMapCameraTransform(MapCameraTransform transform) {
    world.cityProductionLayer.applyCamera(transform);
    _synchronizeIdleViewport();
  }

  void _synchronizeIdleViewport() => world.unitLayer.applyIdleViewport(
    bounds: mapCamera.visibleWorldBounds,
    zoom: mapCamera.zoom,
  );

  void setCinematicCamera(bool enabled) {
    if (_disposed || !mapCamera.setCinematicEnabled(enabled)) return;
    _synchronizeIdleViewport();
    final hover = _lastHoverScreenPosition;
    if (_viewportActive && hover != null) {
      inputSurface.submitHover(Vector2(hover.x, hover.y));
    }
    _requestInputFrame();
  }

  void setSmoothCameraMovement(bool enabled) {
    if (_disposed || _smoothCameraMovement == enabled) return;
    _smoothCameraMovement = enabled;
    mapCamera.setMotionEnabled(enabled && !_reducedMotion);
  }

  void _synchronizeMapCamera(
    MapRenderSnapshot? previous,
    MapRenderSnapshot snapshot,
  ) {
    final cache = world._staticRenderCacheForGame;
    if (cache == null) return;
    final mapChanged = mapCamera.replaceMap(
      cache: cache,
      authoredZoom: snapshot.map.defaultZoom,
    );
    final recipientChanged =
        previous?.player.actorPlayerId != snapshot.player.actorPlayerId;
    final reset =
        mapChanged ||
        recipientChanged ||
        previous?.effectEpoch != snapshot.effectEpoch ||
        snapshot.player.stamp.revision < (previous?.player.stamp.revision ?? 0);
    final selection = mapCameraSelection(snapshot);
    if (reset) {
      mapCamera.cancelMotion();
      _lastCameraSelection = selection?.key;
      if (mapChanged || recipientChanged) {
        final focus = initialMapFocus(snapshot);
        if (focus != null) mapCamera.centerOnHex(focus);
      }
      return;
    }
    if (_startedMovementCameraInScene) return;
    _focusMapCameraSelection(snapshot, cache);
  }

  void _focusMapCameraSelection(
    MapRenderSnapshot snapshot,
    MapStaticRenderCache cache,
  ) {
    final selection = mapCameraSelection(snapshot);
    if (_lastCameraSelection == selection?.key) return;
    _lastCameraSelection = selection?.key;
    if (selection == null) {
      mapCamera.cancelMotion();
      return;
    }
    final point = _selectionCameraPoint(selection, cache);
    mapCamera.smoothCenterOnWorld(point);
  }

  AonwPoint _selectionCameraPoint(
    MapCameraSelection selection,
    MapStaticRenderCache cache,
  ) {
    final unitId = selection.unitId;
    if (unitId == null) {
      return cache.projection.hexTopFaceCenter(selection.coordinate);
    }
    final point =
        world.unitLayer.componentForUnit(unitId)?.visualCenter ??
        world.unitLayer.visualCenterFor(cache, unitId, selection.coordinate);
    return (x: point.dx, y: point.dy);
  }

  void _handleCameraActivity(bool active) {
    if (_disposed || _cameraActive == active) return;
    _cameraActive = active;
    _completeCommandEffectsIfIdle();
    _synchronizeGameLoop();
  }
}
