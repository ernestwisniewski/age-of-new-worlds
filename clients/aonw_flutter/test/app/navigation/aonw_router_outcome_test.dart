import 'package:aonw_flutter/app/navigation/aonw_app.dart';
import 'package:aonw_flutter/app/navigation/aonw_router.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_gamepad_input.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_input.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/turns/read_model/recipient_turn_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/map_test_fixture.dart';
import '../../support/test_map_input_source.dart';

void main() {
  for (final method in ['pointer', 'keyboard', 'gamepad', 'cancel']) {
    testWidgets('terminal match returns to the main menu by $method', (
      tester,
    ) async {
      final session = FakeGameSession.success(
        testMapScene(
          outcome: GameOutcomeView(
            condition: GameOutcomeConditionView.conquest,
            winnerPlayerId: 'preview-player',
            scoreByPlayerId: const {},
          ),
        ),
      );
      final controller = MapPresentationController(
        capabilities: testGameSessionCapabilities(session),
      );
      final game = AonwFlameGame();
      final input = TestMapInputSource();
      await tester.pumpWidget(
        AonwApp(
          mapController: controller,
          initialRoute: AonwRoute.map,
          mapInputSource: input,
          flameGameFactory: () => game,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Victory'), findsOneWidget);
      final camera = game.mapCamera.debugTransform!;
      input.addContinuous(const MapGamepadInput(cameraX: 1, zoomIn: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(game.mapCamera.debugTransform!.worldCenter, camera.worldCenter);
      expect(game.mapCamera.debugTransform!.zoom, camera.zoom);
      input.addContinuous(MapGamepadInput.idle);
      await tester.pump();
      switch (method) {
        case 'pointer':
          await tester.tap(find.byKey(const ValueKey('outcome-return-menu')));
        case 'keyboard':
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        case 'gamepad':
          input.add(MapInputCommand.activate);
        case 'cancel':
          input.add(MapInputCommand.cancel);
      }
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('single-player')), findsOneWidget);
      expect(find.byKey(const ValueKey('terminal-outcome')), findsNothing);
      final context = tester.element(
        find.byKey(const ValueKey('single-player')),
      );
      expect(Navigator.of(context).canPop(), isFalse);
      expect(session.endTurnCalls, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
