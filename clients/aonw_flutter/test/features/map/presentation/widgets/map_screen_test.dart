import 'dart:async';

import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_session_port.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_gamepad_input.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_input.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/features/map/read_model/map_view_mode.dart';
import 'package:aonw_flutter/features/map/read_model/movement_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';
import '../../../../support/map_test_fixture.dart';
import '../../../../support/test_map_input_source.dart';

void main() {
  testWidgets('supports selection, pan, zoom and map view fallback', (
    tester,
  ) async {
    final session = FakeGameSession.success(
      testMapScene(cols: 7, rows: 7, defaultZoom: 1.2),
    );
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );
    final flameGame = AonwFlameGame();
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      LocalizedTestApp(
        home: Scaffold(
          body: MapScreen(
            controller: controller,
            flameGameFactory: () => flameGame,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final viewport = find.byKey(const ValueKey('map-viewport'));
    final flameViewport = find.byKey(const ValueKey(('flame-viewport', 0)));
    final center = flameGame.debugScreenForHex((col: 3, row: 3))!;
    await tester.tapAt(
      tester.getTopLeft(viewport) + Offset(center.x, center.y),
    );
    await tester.pump();
    expect(find.text('Hex 3, 3'), findsOneWidget);

    final beforePan = flameGame.mapCamera.debugTransform!.worldCenter;
    final beforePanUpdates = flameGame.mapCamera.debugTransformUpdateCount;
    final beforePanFlushes = flameGame.inputSurface.debugFlushCount;
    await tester.drag(flameViewport, const Offset(60, 40));
    await tester.pumpAndSettle();
    expect(
      flameGame.inputSurface.debugFlushCount,
      greaterThan(beforePanFlushes),
    );
    expect(
      flameGame.mapCamera.debugTransformUpdateCount,
      greaterThan(beforePanUpdates),
    );
    expect(
      flameGame.mapCamera.debugTransform!.worldCenter,
      isNot(equals(beforePan)),
    );

    final beforeZoom = flameGame.mapCamera.debugTransform!.zoom;
    final viewportCenter = tester.getCenter(flameViewport);
    final first = await tester.createGesture(pointer: 1);
    final second = await tester.createGesture(pointer: 2);
    await first.down(viewportCenter - const Offset(30, 0));
    await second.down(viewportCenter + const Offset(30, 0));
    await first.moveTo(viewportCenter - const Offset(80, 0));
    await second.moveTo(viewportCenter + const Offset(80, 0));
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    expect(flameGame.mapCamera.debugTransform!.zoom, greaterThan(beforeZoom));

    await tester.tap(find.byKey(const ValueKey('map-view-mode-toggle')));
    await tester.pump();
    expect(
      (controller.state as GameSessionReady).interaction.viewMode,
      MapViewMode.graphic,
      reason: 'the fallback tile mode cannot select unavailable graphic art',
    );
  });

  testWidgets('renders a 25 by 19 map without overflow', (tester) async {
    final session = FakeGameSession.success(testMapScene(cols: 25, rows: 19));
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      LocalizedTestApp(home: MapScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('flame-viewport-repaint-boundary')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders reachable and route workflow with explicit confirm', (
    tester,
  ) async {
    final movedPlayer = PlayerMapView.preview(
      actorPlayerId: 'preview-player',
      stamp: testSessionStamp(revision: 1, stateDigest: 'd' * 64),
      turn: 1,
      pendingAction: null,
      units: [testVisibleUnit(coordinate: (col: 1, row: 0), movementUnits: 8)],
    );
    final flameGame = AonwFlameGame();
    final session = FakeGameSession.success(
      testMapScene(units: [testVisibleUnit()]),
      reachableResult: testReachableView(),
      routeResult: testRoutePlanView(),
      moveResult: MoveUnitResultView.accepted(
        player: movedPlayer,
        execution: testMoveUnitExecutionView(),
      ),
    );
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      LocalizedTestApp(
        home: Scaffold(
          body: MapScreen(
            controller: controller,
            flameGameFactory: () => flameGame,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final viewport = find.byKey(const ValueKey('map-viewport'));
    final origin = flameGame.debugScreenForHex((col: 0, row: 0))!;
    await tester.tapAt(
      tester.getTopLeft(viewport) + Offset(origin.x, origin.y),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unit preview-commander'), findsOneWidget);
    expect(flameGame.world.selectionLayer.isVisible, isTrue);
    expect(flameGame.world.unitLayer.debugUnitCount, 1);

    controller.select((col: 1, row: 0));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('confirm-move')), findsOneWidget);
    expect(find.textContaining('Route: 4 movement units'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('confirm-move')));
    await tester.pumpAndSettle();

    final ready = controller.state as GameSessionReady;
    expect(ready.scene.player.units.single.coordinate, (col: 1, row: 0));
    expect(find.byKey(const ValueKey('confirm-move')), findsNothing);
    expect(flameGame.world.effectHost.debugCompletedMovementCount, 1);
    expect(flameGame.world.effectHost.debugActiveEffectCount, 0);
    expect(
      flameGame.world.unitLayer
          .debugComponentForUnit('preview-commander')
          ?.debugUnit
          .coordinate,
      (col: 1, row: 0),
    );
  });

  testWidgets(
    'initial camera uses authored zoom and focuses the active unit once',
    (tester) async {
      final session = FakeGameSession.success(
        testMapScene(
          cols: 7,
          rows: 7,
          defaultZoom: 1.2,
          units: [testVisibleUnit()],
        ),
      );
      final controller = MapPresentationController(
        capabilities: testGameSessionCapabilities(session),
      );
      final flameGame = AonwFlameGame();
      addTearDown(controller.dispose);
      await tester.binding.setSurfaceSize(const Size(900, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        LocalizedTestApp(
          home: MapScreen(
            controller: controller,
            flameGameFactory: () => flameGame,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(flameGame.mapCamera.debugTransform!.zoom, closeTo(1.2, 1e-6));
      final focusedUnit = flameGame.debugScreenForHex((col: 0, row: 0))!;
      final viewport = flameGame.mapCamera.debugTransform!.viewport;
      expect(focusedUnit.x, closeTo(viewport.width / 2, 1e-6));
      expect(focusedUnit.y, closeTo(viewport.height / 2, 1e-6));
      final initialTransform = flameGame.mapCamera.debugTransform;
      final staticGrid = flameGame.world.gridLayer;
      final staticGridUpdates = staticGrid.debugCacheUpdateCount;
      final sceneWrites = flameGame.world.debugSceneWriteCount;
      final cursorUpdates =
          flameGame.world.selectionLayer.debugCursorUpdateCount;

      controller.hover((col: 2, row: 2));
      await tester.pump();

      expect(flameGame.world.debugSceneWriteCount, sceneWrites);
      expect(flameGame.mapCamera.debugTransform, same(initialTransform));
      expect(flameGame.world.gridLayer, same(staticGrid));
      expect(staticGrid.debugCacheUpdateCount, staticGridUpdates);
      expect(
        flameGame.world.selectionLayer.debugCursorUpdateCount,
        cursorUpdates + 1,
      );
      expect(
        flameGame.world.selectionLayer.isVisible,
        isFalse,
        reason: 'legacy standard hover has no generic hex outline',
      );
    },
  );

  testWidgets('replaces the Flame game without retaining old camera state', (
    tester,
  ) async {
    final session = FakeGameSession.success(testMapScene());
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );
    final firstGame = AonwFlameGame();
    final secondGame = AonwFlameGame();
    addTearDown(controller.dispose);
    await controller.load();

    await tester.pumpWidget(
      LocalizedTestApp(
        home: MapScreen(
          controller: controller,
          flameGameFactory: () => firstGame,
          autoLoad: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      LocalizedTestApp(
        home: MapScreen(
          controller: controller,
          flameGameFactory: () => secondGame,
          autoLoad: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(firstGame.debugDisposed, isTrue);
    expect(secondGame.world.debugScene?.map.mapId, 'test-map');
    expect(secondGame.mapCamera.debugTransform, isNotNull);
  });

  testWidgets('shows typed failure and retry action', (tester) async {
    final session = FakeGameSession.failure(
      const MapLoadException(code: 'engine_unavailable', message: 'No engine'),
    );
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      LocalizedTestApp(home: MapScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Map unavailable'), findsOneWidget);
    expect(
      find.text('The native game adapter is unavailable on this platform.'),
      findsOneWidget,
    );
    expect(find.text('engine_unavailable'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('exposes map semantics with reduced motion enabled', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final session = FakeGameSession.success(testMapScene());
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );
    final flameGame = AonwFlameGame();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      LocalizedTestApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MapScreen(
            controller: controller,
            flameGameFactory: () => flameGame,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Map test-map, 3 by 2 hexes'), findsOneWidget);
    final viewportContext = tester.element(
      find.byKey(const ValueKey('map-viewport')),
    );
    expect(MediaQuery.disableAnimationsOf(viewportContext), isTrue);
    expect(flameGame.world.effectHost.debugReducedMotion, isTrue);
    semantics.dispose();
  });

  testWidgets('keyboard and the original gamepad controls drive the map', (
    tester,
  ) async {
    final input = TestMapInputSource();
    final session = FakeGameSession.success(testMapScene(cols: 3, rows: 3));
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );
    final flameGame = AonwFlameGame();
    addTearDown(input.close);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      LocalizedTestApp(
        home: MapScreen(
          controller: controller,
          inputSource: input,
          flameGameFactory: () => flameGame,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cameraBefore = flameGame.mapCamera.debugTransform!.worldCenter;
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    expect(flameGame.keyboardPanDelta(1).x, lessThan(0));
    flameGame.update(0.1);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(controller.cursor.value, isNull);
    expect(
      flameGame.mapCamera.debugTransform!.worldCenter,
      isNot(cameraBefore),
    );

    final beforeGamepad = flameGame.mapCamera.debugTransform!.worldCenter;
    input.addContinuous(const MapGamepadInput(cameraX: 1, dpadUp: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    input.addContinuous(MapGamepadInput.idle);
    await tester.pump();
    expect(
      flameGame.mapCamera.debugTransform!.worldCenter.x,
      lessThan(beforeGamepad.x),
    );
    expect(controller.cursor.value, (col: 1, row: 0));

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect((controller.state as GameSessionReady).interaction.selected, (
      col: 1,
      row: 0,
    ));

    input.add(MapInputCommand.cancel);
    await tester.pump();
    input.add(MapInputCommand.cursorUp);
    input.add(MapInputCommand.activate);
    await tester.pumpAndSettle();
    final interaction = (controller.state as GameSessionReady).interaction;
    expect(controller.cursor.value, (col: 1, row: 0));
    expect(interaction.selected, (col: 1, row: 0));

    input.add(MapInputCommand.toggleMapViewMode);
    await tester.pump();
    expect(
      (controller.state as GameSessionReady).interaction.viewMode,
      MapViewMode.tile,
    );
  });

  testWidgets('a dialog suspends viewport and external map input', (
    tester,
  ) async {
    final input = TestMapInputSource();
    final session = FakeGameSession.success(testMapScene(cols: 3, rows: 3));
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );
    final routeObserver = RouteObserver<ModalRoute<void>>();
    final games = <AonwFlameGame>[];
    addTearDown(input.close);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      LocalizedTestApp(
        navigatorObservers: [routeObserver],
        home: Scaffold(
          body: MapScreen(
            controller: controller,
            inputSource: input,
            routeObserver: routeObserver,
            flameGameFactory: () {
              final game = AonwFlameGame();
              games.add(game);
              return game;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(games.single.debugViewportActive, isTrue);

    final mapContext = tester.element(find.byType(MapScreen));
    unawaited(
      showDialog<void>(
        context: mapContext,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Blocking dialog'),
          actions: [
            TextButton(
              key: const ValueKey('close-blocking-dialog'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(games.single.debugViewportActive, isFalse);

    input.add(MapInputCommand.cursorLeft);
    input.add(MapInputCommand.activate);
    await tester.pump();
    expect((controller.state as GameSessionReady).interaction.selected, isNull);

    await tester.tap(find.byKey(const ValueKey('close-blocking-dialog')));
    await tester.pumpAndSettle();
    expect(games.single.debugViewportActive, isTrue);
    input.add(MapInputCommand.cursorLeft);
    input.add(MapInputCommand.activate);
    await tester.pumpAndSettle();
    expect((controller.state as GameSessionReady).interaction.selected, (
      col: 0,
      row: 1,
    ));
  });
}
