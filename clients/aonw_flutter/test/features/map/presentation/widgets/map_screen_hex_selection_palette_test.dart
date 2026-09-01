import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';
import '../../../../support/map_test_fixture.dart';

void main() {
  testWidgets('long press opens the legacy fan and selects its exact unit', (
    tester,
  ) async {
    const coordinate = (col: 3, row: 3);
    final session = FakeGameSession.success(
      testMapScene(
        cols: 7,
        rows: 7,
        units: [testVisibleUnit(id: 'fan-unit', coordinate: coordinate)],
      ),
      reachableResult: testReachableView(unitId: 'fan-unit'),
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
    final hexScreen = flameGame.debugScreenForHex(coordinate)!;
    await tester.longPressAt(
      tester.getTopLeft(viewport) + Offset(hexScreen.x, hexScreen.y),
    );
    await tester.pump();

    final palette = flameGame.world.hexSelectionPaletteLayer;
    expect(palette.isVisible, isTrue);
    expect(palette.debugTargetRects, hasLength(2));
    final unitTarget = palette.debugTargetRects[1].center;
    final targetScreen = flameGame.mapCamera.debugTransform!.worldToScreen((
      x: unitTarget.dx,
      y: unitTarget.dy,
    ));
    final target = Vector2(targetScreen.x, targetScreen.y);
    flameGame
      ..handleViewportPointerDown(99, target)
      ..handleViewportPointerUp(99)
      ..handleViewportTap(target);
    await tester.pumpAndSettle();

    final ready = controller.state as GameSessionReady;
    expect(ready.interaction.selectedUnitId, 'fan-unit');
    expect(ready.interaction.selected, coordinate);
    expect(palette.isVisible, isFalse);
  });
}
