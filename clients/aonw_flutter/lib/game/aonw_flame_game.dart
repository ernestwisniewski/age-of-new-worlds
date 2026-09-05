import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../features/map/presentation/geometry/odd_q_flat_top_geometry.dart';
import '../features/map/presentation/input/map_action_palette_intent.dart';
import '../features/map/presentation/input/map_gamepad_input.dart';
import '../features/map/presentation/input/map_hex_selection_palette_intent.dart';
import '../features/map/presentation/input/map_viewport_intent.dart';
import '../features/map/presentation/map_hex_selection_palette_view.dart';
import '../features/map/presentation/map_render_snapshot.dart';
import '../features/map/read_model/map_view.dart';
import 'input/flame_map_input_surface.dart';
import 'map/artifact_map_layer.dart';
import 'map/city_founding_preview_layer.dart';
import 'map/city_management_overlay_layer.dart';
import 'map/city_map_layer.dart';
import 'map/city_territory_layer.dart';
import 'map/flame_map_camera.dart';
import 'map/fog_map_layer.dart';
import 'map/gameplay_map_layers.dart';
import 'map/map_action_palette_layer.dart';
import 'map/map_clipped_viewport.dart';
import 'map/map_cloud_layer.dart';
import 'map/map_display_options.dart';
import 'map/map_effect_host.dart';
import 'map/map_era_tint_layer.dart';
import 'map/map_event_feedback_layer.dart';
import 'map/map_hex_selection_palette_layer.dart';
import 'map/map_threat_overlay_layer.dart';
import 'map/map_tile_details_layer.dart';
import 'map/objective_map_layer.dart';
import 'map/static_map_layers.dart';
import 'map/worker_infrastructure_layer.dart';
import 'presentation/flame_scene_patch.dart';
import 'presentation/flame_scene_sink.dart';

part 'aonw_flame_game_effects.dart';
part 'aonw_flame_game_input.dart';
part 'aonw_world.dart';

base class AonwFlameGame extends FlameGame<AonwWorld>
    implements FlameSceneSink {
  AonwFlameGame({
    AonwWorld? world,
    CameraComponent? camera,
    MapHexIntentSink? onHexIntent,
    MapActionPaletteIntentSink? onActionPaletteIntent,
    MapHexSelectionPaletteIntentSink? onHexSelectionPaletteIntent,
  }) : super(
         world: world ?? AonwWorld(),
         camera: camera ?? CameraComponent(viewport: MapClippedViewport()),
       ) {
    // Route and application visibility are coordinated by the Flutter owner.
    pauseWhenBackgrounded = false;
    pauseEngine();
    _hexIntentSink = onHexIntent;
    _actionPaletteIntentSink = onActionPaletteIntent;
    _hexSelectionPaletteIntentSink = onHexSelectionPaletteIntent;
    mapCamera = FlameMapCameraController(
      this.camera,
      onZoomChanged: (zoom) => this.world.cityTerritoryLayer.setZoom(zoom),
    );
    inputSurface = FlameMapInputSurface(
      onIntent: _handleViewportIntent,
      requestFrame: _requestInputFrame,
    );
    this.camera.viewport.add(inputSurface);
    this.world.effectHost.onActivityChanged = _handleEffectActivity;
    this.world.cloudLayer.onActivityChanged = _handleCloudActivity;
    this.world.eraTintLayer.onActivityChanged = _handleEraTintActivity;
    this.world.eventFeedbackLayer.onActivityChanged =
        _handleEventFeedbackActivity;
  }
  late final FlameMapCameraController mapCamera;
  late final FlameMapInputSurface inputSurface;
  MapHexIntentSink? _hexIntentSink;
  MapActionPaletteIntentSink? _actionPaletteIntentSink;
  MapHexSelectionPaletteIntentSink? _hexSelectionPaletteIntentSink;
  MapHexCoordinate? _lastHoveredHex;
  MapHexCoordinate? _longPressedHex;
  var _hasHoveredHex = false;
  var _mountCount = 0;
  var _removeCount = 0;
  var _disposed = false;
  var _viewportActive = false;
  var _continuousRendering = false;
  var _effectsActive = false;
  var _cloudsActive = false;
  var _eraTintActive = false;
  var _eventFeedbackActive = false;
  var _reducedMotion = false;
  var _foundingPreviewActive = false;
  var _inputFrameScheduled = false;
  var _keyboardPanX = 0.0;
  var _keyboardPanY = 0.0;
  static const _keyboardPanSpeed = 200.0;
  static const _gamepadPanSpeed = 520.0;
  static const _gamepadZoomSpeed = 1.35;
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
    _setFoundingPreviewActive(world.cityFoundingPreviewLayer.isVisible);
    final cache = world._staticRenderCacheForGame;
    if (cache != null) {
      final mapChanged = mapCamera.replaceMap(
        cache: cache,
        authoredZoom: snapshot.map.defaultZoom,
      );
      if (mapChanged) {
        final focus = initialMapFocus(snapshot);
        if (focus != null) mapCamera.centerOnHex(focus);
      }
    }
    _requestInputFrame();
  }

  @override
  void replaceCursor(MapHexCoordinate? coordinate) {
    world.replaceCursor(coordinate);
    _requestInputFrame();
  }

  @override
  void clearScene() {
    world.clearScene();
    _setFoundingPreviewActive(false);
    mapCamera.clear();
    _lastHoveredHex = null;
    _hasHoveredHex = false;
    _requestInputFrame();
  }

  void setViewportActive(bool active) {
    if (_disposed || active == _viewportActive) return;
    _viewportActive = active;
    world.cloudLayer.setViewportActive(active);
    inputSurface.setEnabled(active);
    if (!active) {
      _keyboardPanX = 0;
      _keyboardPanY = 0;
      _longPressedHex = null;
      world.hexSelectionPaletteLayer.clearLayer();
    }
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

  void setActionPaletteIntentSink(MapActionPaletteIntentSink? sink) {
    if (_disposed) return;
    _actionPaletteIntentSink = sink;
  }

  void setCameraSensitivity(double sensitivity) {
    if (_disposed) return;
    inputSurface.setCameraSensitivity(sensitivity);
  }

  void setMapDisplayOptions(MapDisplayOptions options) {
    if (!_disposed && world.applyMapDisplayOptions(options)) {
      _requestInputFrame();
    }
  }

  void setKeyboardPanDirection({required double x, required double y}) {
    if (_disposed || !x.isFinite || !y.isFinite) return;
    final nextX = x.clamp(-1, 1).toDouble();
    final nextY = y.clamp(-1, 1).toDouble();
    if (_keyboardPanX == nextX && _keyboardPanY == nextY) return;
    _keyboardPanX = nextX;
    _keyboardPanY = nextY;
    _synchronizeGameLoop();
  }

  @visibleForTesting
  AonwPoint keyboardPanDelta(double dt) {
    final zoom = mapCamera.zoom;
    final speed = _keyboardPanSpeed * dt / zoom;
    return (x: _keyboardPanX * speed, y: _keyboardPanY * speed);
  }

  void applyGamepadCameraFrame(MapGamepadFrame frame, double dt) {
    if (_disposed || !_viewportActive || !dt.isFinite || dt < 0) return;
    final focalPoint = mapCamera.viewportCenter;
    final zoomFactor = focalPoint == null || frame.zoom == 0
        ? 1.0
        : 1 + frame.zoom * _gamepadZoomSpeed * dt;
    mapCamera.applyIntent(
      MapViewportFrameIntent(
        screenPanDelta: (
          x: frame.cameraX * _gamepadPanSpeed * dt,
          y: -frame.cameraY * _gamepadPanSpeed * dt,
        ),
        zoomFocalPoint: focalPoint,
        zoomFactor: zoomFactor,
        hoverScreenPosition: null,
      ),
    );
  }

  void handleViewportPointerDown(int pointerId, Vector2 position) =>
      inputSurface.handlePointerDown(pointerId, position);

  void handleViewportPointerMove(int pointerId, Vector2 position) =>
      inputSurface.handlePointerMove(pointerId, position);

  void handleViewportPointerUp(int pointerId) =>
      inputSurface.handlePointerUp(pointerId);

  void handleViewportPointerCancel(int pointerId) =>
      inputSurface.handlePointerCancel(pointerId);

  void handleViewportHover(Vector2 position) =>
      inputSurface.submitHover(position);

  void handleViewportExit() => inputSurface.submitHoverExit();

  void handleViewportTap(Vector2 position) =>
      inputSurface.submitSelect(position);

  void handleViewportPanZoomStart(Vector2 focalPoint) =>
      inputSurface.handlePanZoomStart(focalPoint);

  void handleViewportPanZoomUpdate({
    required Vector2 panDelta,
    required double scale,
    required Vector2 focalPoint,
  }) => inputSurface.handlePanZoomUpdate(
    panDelta: panDelta,
    scale: scale,
    focalPoint: focalPoint,
  );

  void handleViewportPanZoomEnd() => inputSurface.handlePanZoomEnd();

  void handleViewportScroll({
    required Vector2 focalPoint,
    required double deltaY,
  }) => inputSurface.handleScroll(focalPoint: focalPoint, deltaY: deltaY);

  void _synchronizeGameLoop() {
    final keyboardActive = _keyboardPanX != 0 || _keyboardPanY != 0;
    if (_viewportActive &&
        (_continuousRendering ||
            _effectsActive ||
            _cloudsActive ||
            _eraTintActive ||
            _eventFeedbackActive ||
            _foundingPreviewActive ||
            keyboardActive)) {
      resumeEngine();
    } else {
      pauseEngine();
    }
  }

  void _setFoundingPreviewActive(bool active) {
    if (_disposed || _foundingPreviewActive == active) return;
    _foundingPreviewActive = active;
    _synchronizeGameLoop();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_viewportActive || (_keyboardPanX == 0 && _keyboardPanY == 0)) return;
    final delta = keyboardPanDelta(dt);
    mapCamera.applyIntent(MapPanIntent(delta));
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    inputSurface.resize(size);
    mapCamera.resize(size);
  }

  @override
  Color backgroundColor() => const Color(0xFF000000);

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

  void _requestInputFrame() {
    if (_inputFrameScheduled || _disposed || !isAttached) return;
    _inputFrameScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _inputFrameScheduled = false;
      if (!_disposed && isAttached && paused) stepEngine(stepTime: 0);
    });
  }
}
