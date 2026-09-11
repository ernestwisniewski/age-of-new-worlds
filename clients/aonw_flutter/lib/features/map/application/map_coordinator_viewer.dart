part of 'map_coordinator.dart';

/// Starts a fresh inspection scope for one already verified recipient frame.
MapCoordinator createViewerMapCoordinator({
  required GameSessionCapabilities capabilities,
  required MapScene scene,
  MapCommandFrameView? commandFrame,
  MapViewMode viewMode = MapViewMode.graphic,
}) {
  final coordinator = MapCoordinator(
    capabilities: capabilities.forViewer(map: _ViewerMapSession(scene)),
  );
  coordinator._setState(
    GameSessionReady.initial(
      scene,
      viewMode: viewMode,
    ).withRecipient(scene.player, commandFrame: commandFrame),
  );
  return coordinator;
}

final class _ViewerMapSession implements MapSessionPort {
  const _ViewerMapSession(this.scene);
  final MapScene scene;

  @override
  Future<MapScene> load(MapAssetPaths assets) async => scene;

  // The replay owner retains the transport across inspection scopes.
  @override
  Future<void> close() async {}
}
