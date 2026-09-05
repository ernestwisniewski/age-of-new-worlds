part of 'aonw_flame_game.dart';

extension AonwFlameGameMovementCamera on AonwFlameGame {
  void setMovementCameraOptions(MapMovementCameraOptions options) {
    if (_disposed || _movementCameraOptions == options) return;
    _movementCameraOptions = options;
    _movementCamera?.complete(interrupted: true);
  }

  MapMovementPresentation? _startMovementCamera(
    FlameUnitMovementTransition movement,
    MapUnitComponent unit,
  ) {
    final scene = world._scene;
    if (scene == null || !_canFocusMovement(movement)) return null;
    final owner = scene.player.visibleUnitById(movement.unitId)!.ownerPlayerId;
    final own = owner == scene.player.actorPlayerId;
    final options = _movementCameraOptions;
    final focus = own ? options.focusOwn : options.focusForeign;
    final follow =
        !_reducedMotion &&
        world.effectHost.movementAnimationsEnabled &&
        (own ? options.followOwn : options.followForeign);
    if (!focus && !follow) return null;
    _movementCamera?.complete(interrupted: true);
    _startedMovementCameraInScene = true;
    late final MapMovementCamera presentation;
    presentation = MapMovementCamera(
      camera: mapCamera,
      origin: (x: unit.visualCenter.dx, y: unit.visualCenter.dy),
      point: () => (x: unit.visualCenter.dx, y: unit.visualCenter.dy),
      focus: focus,
      follow: follow,
      allowed: () => _canFocusMovement(movement),
      onComplete: (interrupted) {
        if (!identical(_movementCamera, presentation)) return;
        _movementCamera = null;
        if (!own && !interrupted) _focusSelectionAfterMovement();
      },
    );
    _movementCamera = presentation;
    return presentation;
  }

  bool _canFocusMovement(FlameUnitMovementTransition movement) {
    final scene = world._scene;
    return !_disposed &&
        _viewportActive &&
        scene != null &&
        canFocusMapMovement(scene, movement);
  }

  void _focusSelectionAfterMovement() {
    final scene = world._scene;
    final cache = world._staticRenderCacheForGame;
    if (scene != null && cache != null) {
      _focusMapCameraSelection(scene, cache);
    }
  }
}
