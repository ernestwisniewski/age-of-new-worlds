import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_gamepad_input.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_input.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';
import '../../../../support/map_test_fixture.dart';
import '../../../../support/test_map_input_source.dart';

void main() {
  testWidgets('gamepad follows a changed unit and ignores pointer hover', (
    tester,
  ) async {
    final session = FakeGameSession.success(
      testMapScene(
        cols: 5,
        rows: 3,
        units: [
          testVisibleUnit(),
          testVisibleUnit(id: 'other', coordinate: (col: 3, row: 1)),
        ],
      ),
      reachableResult: testReachableView(),
      routeResult: testRoutePlanView(
        unitId: 'other',
        origin: (col: 3, row: 1),
        target: (col: 4, row: 1),
      ),
    );
    final harness = await _Harness.mount(tester, session);
    harness.controller.selectUnit('preview-commander');
    await tester.pumpAndSettle();
    harness.controller.hover((col: 4, row: 2));
    await harness.frame(tester, const MapGamepadInput(dpadRight: true));
    expect(harness.controller.cursor.value, (col: 1, row: 0));
    harness.controller.hover((col: 4, row: 2));
    await harness.frame(tester, const MapGamepadInput(dpadRight: true));
    expect(harness.controller.cursor.value, (col: 2, row: 0));
    session.reachableResult = testReachableView(unitId: 'other');
    harness.controller.selectUnit('other');
    await tester.pumpAndSettle();
    await harness.frame(tester, const MapGamepadInput(dpadRight: true));
    expect(harness.controller.cursor.value, (col: 4, row: 1));
    harness.controller.hover((col: 4, row: 2));
    await harness.frame(tester, const MapGamepadInput(activate: true));
    await tester.pumpAndSettle();
    expect(harness.ready.interaction.selected, (col: 4, row: 1));
    expect(harness.ready.interaction.selectedUnitId, 'other');
    expect(harness.ready.interaction.route?.target, (col: 4, row: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('first gamepad activation uses the visible map center', (
    tester,
  ) async {
    final harness = await _Harness.mount(
      tester,
      FakeGameSession.success(testMapScene(cols: 10, rows: 6)),
    );
    harness.game.mapCamera.centerOnHex((col: 6, row: 2));
    final center = harness.game.mapCamera.hexAtScreen(
      harness.game.mapCamera.viewportCenter!,
    );
    expect(center, (col: 6, row: 2));
    harness.controller.hover((col: 0, row: 0));
    await harness.frame(tester, const MapGamepadInput(activate: true));
    expect(harness.ready.interaction.selected, center);
    expect(tester.takeException(), isNull);
  });

  testWidgets('session reload drops an old cursor even on the same map', (
    tester,
  ) async {
    final harness = await _Harness.mount(
      tester,
      FakeGameSession.success(testMapScene(cols: 10, rows: 6)),
    );
    harness.game.mapCamera.centerOnHex((col: 6, row: 2));
    harness.input.add(MapInputCommand.cursorRight);
    await tester.pumpAndSettle();
    expect(harness.controller.cursor.value, (col: 7, row: 2));
    await harness.controller.load();
    await tester.pumpAndSettle();
    harness.game.mapCamera.centerOnHex((col: 3, row: 2));
    harness.input.add(MapInputCommand.activate);
    await tester.pumpAndSettle();
    expect(harness.ready.interaction.selected, (col: 3, row: 2));
    expect(tester.takeException(), isNull);
  });
}

final class _Harness {
  _Harness(FakeGameSession session)
    : controller = MapPresentationController(
        capabilities: testGameSessionCapabilities(session),
      );
  final MapPresentationController controller;
  final input = TestMapInputSource();
  final game = AonwFlameGame();
  GameSessionReady get ready => controller.state as GameSessionReady;

  static Future<_Harness> mount(
    WidgetTester tester,
    FakeGameSession session,
  ) async {
    final harness = _Harness(session);
    addTearDown(harness.controller.dispose);
    addTearDown(harness.input.close);
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      LocalizedTestApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MapScreen(
            controller: harness.controller,
            inputSource: harness.input,
            flameGameFactory: () => harness.game,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return harness;
  }

  Future<void> frame(WidgetTester tester, MapGamepadInput frame) async {
    input.addContinuous(frame);
    await tester.pump();
    input.addContinuous(MapGamepadInput.idle);
    await tester.pump();
  }
}
