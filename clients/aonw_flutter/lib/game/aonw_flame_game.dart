import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../features/map/presentation/geometry/odd_q_flat_top_geometry.dart';
import '../features/map/presentation/input/map_viewport_intent.dart';
import '../features/map/presentation/map_render_snapshot.dart';
import '../features/map/read_model/map_view.dart';
import 'input/flame_map_input_surface.dart';
import 'map/artifact_map_layer.dart';
import 'map/city_map_layer.dart';
import 'map/flame_map_camera.dart';
import 'map/gameplay_map_layers.dart';
import 'map/map_effect_host.dart';
import 'map/objective_map_layer.dart';
import 'map/static_map_layers.dart';
import 'map/worker_infrastructure_layer.dart';
import 'presentation/flame_scene_patch.dart';
import 'presentation/flame_scene_sink.dart';

typedef AonwFlameGameFactory = AonwFlameGame Function();

final class AonwWorld extends World implements FlameSceneSink {
  AonwWorld()
    : terrainLayer = MapTerrainLayerComponent(),
      referenceLayer = MapReferenceLayerComponent(),
      gridLayer = MapGridLayerComponent() {
    unitLayer = MapUnitLayerComponent();
    cityLayer = MapCityLayerComponent();
    artifactLayer = MapArtifactLayerComponent();
    objectiveLayer = MapObjectiveLayerComponent();
    reachableLayer = MapReachableLayerComponent();
    workerInfrastructureLayer = MapWorkerInfrastructureLayerComponent();
    routeLayer = MapRouteLayerComponent();
    selectionLayer = MapSelectionLayerComponent(units: unitLayer);
    effectHost = MapEffectHostComponent(units: unitLayer);
    addAll([
      terrainLayer,
      referenceLayer,
      gridLayer,
      workerInfrastructureLayer,
      reachableLayer,
      routeLayer,
      objectiveLayer,
      cityLayer,
      artifactLayer,
      unitLayer,
      selectionLayer,
      effectHost,
    ]);
  }

  final MapTerrainLayerComponent terrainLayer;
  final MapReferenceLayerComponent referenceLayer;
  final MapGridLayerComponent gridLayer;
  late final MapReachableLayerComponent reachableLayer;
  late final MapWorkerInfrastructureLayerComponent workerInfrastructureLayer;
  late final MapRouteLayerComponent routeLayer;
  late final MapUnitLayerComponent unitLayer;
  late final MapCityLayerComponent cityLayer;
  late final MapArtifactLayerComponent artifactLayer;
  late final MapObjectiveLayerComponent objectiveLayer;
  late final MapSelectionLayerComponent selectionLayer;
  late final MapEffectHostComponent effectHost;
  MapRenderSnapshot? _scene;
  MapStaticRenderCache? _staticCache;
  var _sceneWriteCount = 0;

  @visibleForTesting
  MapRenderSnapshot? get debugScene => _scene;

  @visibleForTesting
  int get debugSceneWriteCount => _sceneWriteCount;

  @visibleForTesting
  MapStaticRenderCache? get debugStaticRenderCache => _staticCache;

  MapStaticRenderCache? get _staticRenderCacheForGame => _staticCache;

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
    referenceLayer.applyReference(
      cache: cache,
      reference: snapshot.reference,
      visible: snapshot.interaction.referenceVisible,
    );
    gridLayer.applyCache(cache);
    workerInfrastructureLayer.applyPatch(patch, cache);
    reachableLayer.applyReachable(cache, snapshot.interaction.reachable);
    routeLayer.applyRoute(cache, snapshot.interaction.route);
    objectiveLayer.applyMap(snapshot.map, cache);
    cityLayer.applyPatch(patch, cache);
    artifactLayer.applyPatch(patch, cache);
    unitLayer.applyPatch(patch, cache);
    selectionLayer.applySelection(cache, snapshot.interaction);
    effectHost.applyPatch(patch, cache);
  }

  @override
  void clearScene() {
    if (_scene == null) return;
    _scene = null;
    _staticCache = null;
    _sceneWriteCount += 1;
    terrainLayer.clearCache();
    referenceLayer.clearCache();
    gridLayer.clearCache();
    workerInfrastructureLayer.clearLayer();
    reachableLayer.clearLayer();
    routeLayer.clearLayer();
    objectiveLayer.clearLayer();
    cityLayer.clearLayer();
    artifactLayer.clearLayer();
    unitLayer.clearLayer();
    selectionLayer.clearLayer();
    effectHost.clearEffects();
  }

  @override
  void onRemove() {
    clearScene();
    super.onRemove();
  }
}

base class AonwFlameGame extends FlameGame<AonwWorld>
    implements FlameSceneSink {
  AonwFlameGame({
    AonwWorld? world,
    CameraComponent? camera,
    MapHexIntentSink? onHexIntent,
  }) : super(world: world ?? AonwWorld(), camera: camera ?? CameraComponent()) {
    // Route and application visibility are coordinated by the Flutter owner.
    pauseWhenBackgrounded = false;
    pauseEngine();
    _hexIntentSink = onHexIntent;
    mapCamera = FlameMapCameraController(this.camera);
    inputSurface = FlameMapInputSurface(
      onIntent: _handleViewportIntent,
      requestFrame: _requestInputFrame,
    );
    this.camera.viewport.add(inputSurface);
    this.world.effectHost.onActivityChanged = _handleEffectActivity;
  }

  late final FlameMapCameraController mapCamera;
  late final FlameMapInputSurface inputSurface;
  MapHexIntentSink? _hexIntentSink;
  MapHexCoordinate? _lastHoveredHex;
  var _hasHoveredHex = false;
  var _mountCount = 0;
  var _removeCount = 0;
  var _disposed = false;
  var _viewportActive = false;
  var _continuousRendering = false;
  var _effectsActive = false;
  var _inputFrameScheduled = false;

  FlameSceneSink get sceneSink => this;

  @visibleForTesting
  int get debugMountCount => _mountCount;

  @visibleForTesting
  int get debugRemoveCount => _removeCount;

  @visibleForTesting
  bool get debugDisposed => _disposed;

  @visibleForTesting
  bool get debugViewportActive => _viewportActive;

  @visibleForTesting
  bool get debugEffectsActive => _effectsActive;

  @visibleForTesting
  MapHexCoordinate? debugHexAtScreen(AonwPoint screenPoint) =>
      mapCamera.hexAtScreen(screenPoint);

  @visibleForTesting
  AonwPoint? debugScreenForHex(MapHexCoordinate coordinate) =>
      mapCamera.screenForHex(coordinate);

  @override
  void replaceScene(MapRenderSnapshot snapshot) {
    world.replaceScene(snapshot);
    final cache = world._staticRenderCacheForGame;
    if (cache != null) {
      mapCamera.replaceMap(
        cache: cache,
        authoredZoom: snapshot.map.defaultZoom,
      );
    }
    _requestInputFrame();
  }

  @override
  void clearScene() {
    world.clearScene();
    mapCamera.clear();
    _lastHoveredHex = null;
    _hasHoveredHex = false;
    _requestInputFrame();
  }

  void setViewportActive(bool active) {
    if (_disposed || active == _viewportActive) return;
    _viewportActive = active;
    inputSurface.setEnabled(active);
    _synchronizeGameLoop();
  }

  void setContinuousRendering(bool enabled) {
    if (_disposed || enabled == _continuousRendering) return;
    _continuousRendering = enabled;
    _synchronizeGameLoop();
  }

  void setHexIntentSink(MapHexIntentSink? sink) {
    if (_disposed) return;
    _hexIntentSink = sink;
  }

  void setCameraSensitivity(double sensitivity) {
    if (_disposed) return;
    inputSurface.setCameraSensitivity(sensitivity);
  }

  void _synchronizeGameLoop() {
    if (_viewportActive && (_continuousRendering || _effectsActive)) {
      resumeEngine();
    } else {
      pauseEngine();
    }
  }

  void setReducedMotion(bool enabled) {
    if (_disposed) return;
    world.effectHost.setReducedMotion(enabled);
  }

  void setEffectPlaybackSpeed(double speed) {
    if (_disposed) return;
    world.effectHost.setPlaybackSpeed(speed);
  }

  void skipEffects() {
    if (_disposed) return;
    world.effectHost.skipAll();
  }

  void _handleEffectActivity(bool active) {
    if (_disposed || _effectsActive == active) return;
    _effectsActive = active;
    _synchronizeGameLoop();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.center;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    inputSurface.resize(size);
    mapCamera.resize(size);
  }

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  void onAttach() {
    super.onAttach();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_disposed || !isAttached) return;
      if (paused) update(0);
      _synchronizeGameLoop();
    });
  }

  @override
  void onMount() {
    _mountCount += 1;
    super.onMount();
  }

  @override
  void onRemove() {
    _removeCount += 1;
    super.onRemove();
  }

  @override
  void onDispose() {
    if (!_disposed) {
      _disposed = true;
      clearScene();
      dispose();
    }
    super.onDispose();
  }

  void _handleViewportIntent(MapViewportIntent intent) {
    if (!_viewportActive) return;
    mapCamera.applyIntent(intent);
    switch (intent) {
      case MapHoverIntent(:final screenPosition):
        _emitHover(mapCamera.hexAtScreen(screenPosition));
      case MapSelectIntent(:final screenPosition):
        _hexIntentSink?.call(
          MapHexSelectIntent(mapCamera.hexAtScreen(screenPosition)),
        );
      case MapViewportFrameIntent(:final hoverScreenPosition):
        if (hoverScreenPosition != null) {
          _emitHover(mapCamera.hexAtScreen(hoverScreenPosition));
        }
      case MapPanIntent() || MapZoomIntent():
        break;
    }
  }

  void _emitHover(MapHexCoordinate? coordinate) {
    if (_hasHoveredHex && coordinate == _lastHoveredHex) return;
    _hasHoveredHex = true;
    _lastHoveredHex = coordinate;
    _hexIntentSink?.call(MapHexHoverIntent(coordinate));
  }

  void _requestInputFrame() {
    if (_inputFrameScheduled || _disposed || !isAttached) return;
    _inputFrameScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _inputFrameScheduled = false;
      if (!_disposed && isAttached && paused) stepEngine(stepTime: 0);
    });
  }
}
