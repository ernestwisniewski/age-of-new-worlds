import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/features/settings/application/client_settings.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_scope.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';
import '../../../../support/map_test_fixture.dart';

void main() {
  testWidgets('applies live camera, map and animation preferences', (
    tester,
  ) async {
    final settings = ClientSettingsController.ephemeral();
    await settings.update(
      ClientSettings.defaults.copyWith(cameraSensitivity: 2),
    );
    final session = FakeGameSession.success(testMapScene());
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );
    final flameGame = AonwFlameGame();
    addTearDown(settings.dispose);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      LocalizedTestApp(
        home: ClientSettingsScope(
          controller: settings,
          child: MapScreen(
            controller: controller,
            flameGameFactory: () => flameGame,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(flameGame.inputSurface.debugCameraSensitivity, 2);
    expect(flameGame.world.gridLayer.isVisible, isFalse);
    final sceneWrites = flameGame.world.debugSceneWriteCount;

    await settings.update(
      settings.settings.copyWith(
        showMapGrid: true,
        showUnitMovementAnimations: false,
        showUnitIdleAnimations: false,
        showRouteAnimations: false,
      ),
    );
    await tester.pump();

    expect(flameGame.world.gridLayer.debugGridVisible, isTrue);
    expect(flameGame.world.gridLayer.isVisible, isTrue);
    expect(flameGame.world.debugSceneWriteCount, sceneWrites);
    final host = flameGame.world.effectHost;
    expect(host.movementAnimationsEnabled, isFalse);
    expect(host.combatAnimationsEnabled, isTrue);
    expect(host.debugReducedMotion, isFalse);
    expect(flameGame.world.unitLayer.idleAnimationsEnabled, isFalse);
    expect(flameGame.world.routeLayer.animationsEnabled, isFalse);

    await settings.update(
      settings.settings.copyWith(showCombatAnimations: false),
    );
    await tester.pump();
    expect(host.combatAnimationsEnabled, isFalse);
    expect(host.movementAnimationsEnabled, isFalse);
    expect(flameGame.world.debugSceneWriteCount, sceneWrites);

    await settings.reset();
    await tester.pump();
    expect(host.combatAnimationsEnabled, isTrue);
    expect(host.movementAnimationsEnabled, isTrue);
    expect(flameGame.world.unitLayer.idleAnimationsEnabled, isTrue);
    expect(flameGame.world.routeLayer.animationsEnabled, isTrue);
  });
}
