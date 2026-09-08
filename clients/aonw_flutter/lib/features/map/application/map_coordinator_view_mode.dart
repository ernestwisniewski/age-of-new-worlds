part of 'map_coordinator.dart';

extension MapCoordinatorViewMode on MapCoordinator {
  Future<({MapScene scene, MapViewMode viewMode})?> _openPreferredScene(
    Future<MapScene> Function() open,
    int generation,
  ) async {
    final viewMode = await _initialMapViewMode();
    if (!_isCurrent(generation)) return null;
    final scene = await open();
    if (!_isCurrent(generation)) return null;
    return (scene: scene, viewMode: viewMode);
  }

  Future<MapViewMode> _initialMapViewMode() async {
    try {
      return await readInitialMapViewMode?.call() ?? MapViewMode.graphic;
    } on Object catch (error, stackTrace) {
      _diagnosticReporter('map_view_preference_failed', error, stackTrace);
      return MapViewMode.graphic;
    }
  }
}
