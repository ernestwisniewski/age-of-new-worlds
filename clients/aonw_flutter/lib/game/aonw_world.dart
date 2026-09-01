part of 'aonw_flame_game.dart';

final class AonwWorld extends World implements FlameSceneSink {
  AonwWorld()
    : terrainLayer = MapTerrainLayerComponent(),
      referenceLayer = MapReferenceLayerComponent(),
      gridLayer = MapGridLayerComponent(),
      tileDetailsLayer = MapTileDetailsLayerComponent(),
      cityTerritoryLayer = MapCityTerritoryLayerComponent() {
    unitLayer = MapUnitLayerComponent();
    cityLayer = MapCityLayerComponent();
    artifactLayer = MapArtifactLayerComponent();
    objectiveLayer = MapObjectiveLayerComponent();
    workerInfrastructureLayer = MapWorkerInfrastructureLayerComponent();
    fogLayer = MapFogLayerComponent();
    routeLayer = MapRouteLayerComponent();
    selectionLayer = MapSelectionLayerComponent();
    cityFoundingPreviewLayer = MapCityFoundingPreviewLayerComponent();
    cityManagementOverlayLayer = MapCityManagementOverlayLayerComponent();
    actionPaletteLayer = MapActionPaletteLayerComponent();
    hexSelectionPaletteLayer = MapHexSelectionPaletteLayerComponent();
    effectHost = MapEffectHostComponent(units: unitLayer);
    addAll([
      terrainLayer,
      referenceLayer,
      gridLayer,
      cityTerritoryLayer,
      tileDetailsLayer,
      workerInfrastructureLayer,
      fogLayer,
      routeLayer,
      objectiveLayer,
      cityLayer,
      artifactLayer,
      unitLayer,
      cityFoundingPreviewLayer,
      cityManagementOverlayLayer,
      selectionLayer,
      actionPaletteLayer,
      hexSelectionPaletteLayer,
      effectHost,
    ]);
  }

  final MapTerrainLayerComponent terrainLayer;
  final MapReferenceLayerComponent referenceLayer;
  final MapGridLayerComponent gridLayer;
  final MapCityTerritoryLayerComponent cityTerritoryLayer;
  final MapTileDetailsLayerComponent tileDetailsLayer;
  late final MapWorkerInfrastructureLayerComponent workerInfrastructureLayer;
  late final MapFogLayerComponent fogLayer;
  late final MapRouteLayerComponent routeLayer;
  late final MapUnitLayerComponent unitLayer;
  late final MapCityLayerComponent cityLayer;
  late final MapArtifactLayerComponent artifactLayer;
  late final MapObjectiveLayerComponent objectiveLayer;
  late final MapSelectionLayerComponent selectionLayer;
  late final MapCityFoundingPreviewLayerComponent cityFoundingPreviewLayer;
  late final MapCityManagementOverlayLayerComponent cityManagementOverlayLayer;
  late final MapActionPaletteLayerComponent actionPaletteLayer;
  late final MapHexSelectionPaletteLayerComponent hexSelectionPaletteLayer;
  late final MapEffectHostComponent effectHost;
  MapRenderSnapshot? _scene;
  MapStaticRenderCache? _staticCache;
  MapHexCoordinate? _cursor;
  var _sceneWriteCount = 0;

  @visibleForTesting
  MapRenderSnapshot? get debugScene => _scene;

  @visibleForTesting
  int get debugSceneWriteCount => _sceneWriteCount;

  @visibleForTesting
  MapStaticRenderCache? get debugStaticRenderCache => _staticCache;

  MapStaticRenderCache? get _staticRenderCacheForGame => _staticCache;

  bool applyMapDisplayOptions(MapDisplayOptions options) {
    final gridChanged = gridLayer.setGridVisible(options.showGrid);
    final wallsChanged = terrainLayer.setWalls(options.showElevationWalls);
    final detailsChanged = tileDetailsLayer.setOptions(options);
    return gridChanged || wallsChanged || detailsChanged;
  }

  @override
  void replaceScene(MapRenderSnapshot snapshot) {
    if (identical(_scene, snapshot)) return;
    final patch = FlameScenePatch.between(_scene, snapshot);
    _scene = snapshot;
    _sceneWriteCount += 1;
    final identity = (
      mapId: snapshot.map.mapId,
      contentHash: snapshot.map.contentHash,
      cols: snapshot.map.cols,
      rows: snapshot.map.rows,
    );
    final cache = _staticCache?.identity == identity
        ? _staticCache!
        : MapStaticRenderCache.build(snapshot.map);
    _staticCache = cache;
    terrainLayer.applyCache(cache);
    terrainLayer.setViewMode(snapshot.effectiveViewMode);
    referenceLayer.applyReference(
      cache: cache,
      reference: snapshot.reference,
      visible: snapshot.effectiveViewMode.showsReference,
    );
    gridLayer.applyCache(cache);
    cityTerritoryLayer.applySnapshot(snapshot, cache);
    tileDetailsLayer.applyMap(snapshot.map, cache);
    workerInfrastructureLayer.applyPatch(patch, cache);
    fogLayer.applyFog(cache, snapshot.player.fog);
    routeLayer.applyRoute(cache, snapshot.interaction.route, snapshot.player);
    objectiveLayer.applyMap(snapshot.map, cache);
    cityLayer.applyPatch(patch, cache);
    artifactLayer.applyPatch(patch, cache);
    unitLayer.applyPatch(patch, cache);
    cityFoundingPreviewLayer.applyFounding(
      cache,
      snapshot.interaction.city,
      snapshot.player,
    );
    cityManagementOverlayLayer.applyManagement(
      cache,
      snapshot.interaction.city,
      snapshot.player,
    );
    selectionLayer.applySelection(cache, snapshot.interaction, snapshot.player);
    selectionLayer.applyCursor(cache, _cursor);
    actionPaletteLayer.applyPalette(cache, snapshot.actionPalette);
    hexSelectionPaletteLayer.clearLayer();
    effectHost.applyPatch(patch, cache);
  }

  @override
  void replaceCursor(MapHexCoordinate? coordinate) {
    if (_cursor == coordinate) return;
    _cursor = coordinate;
    final cache = _staticCache;
    if (cache != null) selectionLayer.applyCursor(cache, coordinate);
  }

  @override
  void clearScene() {
    if (_scene == null) return;
    _scene = null;
    _staticCache = null;
    _cursor = null;
    _sceneWriteCount += 1;
    terrainLayer.clearCache();
    referenceLayer.clearCache();
    gridLayer.clearCache();
    cityTerritoryLayer.clearLayer();
    tileDetailsLayer.clearLayer();
    workerInfrastructureLayer.clearLayer();
    fogLayer.clearLayer();
    routeLayer.clearLayer();
    objectiveLayer.clearLayer();
    cityLayer.clearLayer();
    artifactLayer.clearLayer();
    unitLayer.clearLayer();
    cityFoundingPreviewLayer.clearLayer();
    cityManagementOverlayLayer.clearLayer();
    selectionLayer.clearLayer();
    actionPaletteLayer.clearLayer();
    hexSelectionPaletteLayer.clearLayer();
    effectHost.clearEffects();
  }

  @override
  void onRemove() {
    clearScene();
    super.onRemove();
  }
}
