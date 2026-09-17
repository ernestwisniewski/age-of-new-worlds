import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_input.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_gamepad_region.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';
import '../../../../support/map_test_fixture.dart';
import '../../../../support/test_map_input_source.dart';

void main() {
  testWidgets('production owns input and closes without losing the city', (
    tester,
  ) async {
    final city = testCityView();
    final session = FakeGameSession.success(
      testMapScene(cities: [city]),
      cityInspection: testCityInspectionView(),
    );
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );
    final input = TestMapInputSource();
    final game = AonwFlameGame();
    addTearDown(controller.dispose);
    addTearDown(input.close);
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      LocalizedTestApp(
        home: MapScreen(
          controller: controller,
          inputSource: input,
          flameGameFactory: () => game,
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.selectCity(city.id);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-production')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('production-modal')), findsOneWidget);
    final navigation = tester
        .widget<MapGamepadFocusRing>(find.byType(MapGamepadFocusRing))
        .navigation;
    expect(navigation.hasModal, isTrue);
    final camera = game.mapCamera.debugTransform!;
    input.add(MapInputCommand.cursorRight);
    await tester.pumpAndSettle();
    expect(game.mapCamera.debugTransform!.worldCenter, camera.worldCenter);
    expect(
      (controller.state as GameSessionReady).interaction.selected,
      city.center,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('production-modal')), findsNothing);
    expect(
      (controller.state as GameSessionReady).interaction.city?.cityId,
      city.id,
    );
    expect(navigation.hasModal, isFalse);
    await tester.tap(find.byKey(const ValueKey('open-production')));
    await tester.pumpAndSettle();
    input.add(MapInputCommand.cancel);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('production-modal')), findsNothing);
    expect(
      (controller.state as GameSessionReady).interaction.city?.cityId,
      city.id,
    );
    expect(session.productionCommandCalls, 0);
    expect(session.endTurnCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening production dismisses another HUD panel', (tester) async {
    final city = testCityView();
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(
        FakeGameSession.success(
          testMapScene(cities: [city]),
          cityInspection: testCityInspectionView(),
        ),
      ),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      LocalizedTestApp(home: MapScreen(controller: controller)),
    );
    await tester.pumpAndSettle();
    controller.selectCity(city.id);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-objectives')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('close-objectives')), findsOneWidget);
    controller.setProductionCatalogOpen(true);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('close-objectives')), findsNothing);
    expect(find.byKey(const ValueKey('production-modal')), findsOneWidget);
    controller.selectCity(city.id);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('production-modal')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
