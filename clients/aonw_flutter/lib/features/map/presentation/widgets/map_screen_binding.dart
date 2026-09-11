part of 'map_screen.dart';

extension _MapScreenBinding on _MapScreenState {
  void _updateInspectionBinding(MapScreen oldWidget) {
    if (oldWidget.interactionEnabled != widget.interactionEnabled) {
      _invalidateKeyboardInput();
      _gamepadFrames.prime(_gamepadInput);
      if (!widget.interactionEnabled) {
        _flameGame.setKeyboardPanDirection(x: 0, y: 0);
      }
    }
    if (oldWidget.controller != widget.controller) {
      if (widget.controller.state case GameSessionReady(
        commandFrame: null,
      ) when widget.controller.readOnly) {
        _sceneEpoch++;
      }
      _automaticOperation = null;
      _automaticGeneration += 1;
      _gamepadCursor.reset();
      _gamepadNavigation.setAvailable(false);
      oldWidget.controller.bindCommandEffects(null);
      oldWidget.controller.bindInteractionSounds(null);
      _flameGame.skipEffects();
      oldWidget.controller.removeListener(_synchronizeFlameScene);
      oldWidget.controller.cursor.removeListener(_synchronizeFlameCursor);
      widget.controller.addListener(_synchronizeFlameScene);
      widget.controller.bindCommandEffects(_flameGame.waitForCommandEffects);
      widget.controller.bindInteractionSounds(_playInteractionSound);
      widget.controller.cursor.addListener(_synchronizeFlameCursor);
    }
  }

  void _applyClientSettings(BuildContext context) {
    final settings = ClientSettingsScope.settingsOf(context);
    _flameGame.setReducedMotion(
      settings.reducedMotion || MediaQuery.disableAnimationsOf(context),
    );
    _flameGame.setUnitMovementAnimations(settings.showUnitMovementAnimations);
    _flameGame.setCombatAnimations(settings.showCombatAnimations);
    _flameGame.setUnitIdleAnimations(settings.showUnitIdleAnimations);
    _flameGame.setRouteAnimations(settings.showRouteAnimations);
    _flameGame.setCameraSensitivity(settings.cameraSensitivity);
    _flameGame.setSmoothCameraMovement(settings.smoothCameraMovement);
    _flameGame.setCinematicCamera(settings.cinematicCamera);
    _flameGame.setMovementCameraOptions((
      focusOwn: settings.focusOwnUnitMovement,
      followOwn: settings.followOwnUnitMovement,
      focusForeign: settings.focusForeignUnitMovement,
      followForeign: settings.followForeignUnitMovement,
    ));
    _flameGame.setMapDisplayOptions(
      MapDisplayOptions(
        showCitySites: settings.showMapCitySites,
        showCityGrowth: settings.showMapCityGrowth,
        showGrid: settings.showMapGrid,
        showElevationWalls: settings.showMapElevationWalls,
        showTerrainIcons: settings.showMapTerrainIcons,
        showResourceIcons: settings.showMapResourceIcons,
        showHeightBadges: settings.showMapHeightBadges,
      ),
    );
    _planningEnabled = settings.showMapCitySites || settings.showMapCityGrowth;
    _synchronizeCityPlanning();
    _synchronizeGamepadSettings(settings.gamepad);
    final ready = ClientSettingsScope.isLoadedOf(context);
    final changed = _automaticFlow.configure(settings.automation);
    if (changed || ready != _automaticSettingsReady) {
      _automaticSettingsReady = ready;
      _automaticGeneration += 1;
      _requestAutomaticTurn();
    }
  }
}
