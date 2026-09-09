import 'package:aonw_flutter/features/map/application/city_planning_session_port.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/features/map/read_model/city_planning_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
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
    final planning = _Planning(session.scene!.player);
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(
        session,
        cityPlanning: planning,
      ),
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
    expect(planning.calls, 0);
    final sceneWrites = flameGame.world.debugSceneWriteCount;

    await settings.update(
      settings.settings.copyWith(
        showUnitMovementAnimations: false,
        showUnitIdleAnimations: false,
        showRouteAnimations: false,
        mapDisplay: settings.settings.mapDisplay.copyWith(
          showMapGrid: true,
          cityPlanning: settings.settings.cityPlanning.copyWith(
            showSites: true,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.pump();
    expect(planning.calls, 1);
    expect(flameGame.world.cityPlanningLayer.debugSiteCenters, hasLength(1));
    expect(flameGame.world.cityPlanningLayer.debugGrowthCenters, isEmpty);
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
      settings.settings.copyWith(
        showCombatAnimations: false,
        mapDisplay: settings.settings.mapDisplay.copyWith(
          cityPlanning: settings.settings.cityPlanning.copyWith(
            showGrowth: true,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(planning.calls, 1);
    expect(flameGame.world.cityPlanningLayer.debugGrowthCenters, hasLength(2));
    expect(host.combatAnimationsEnabled, isFalse);
    expect(host.movementAnimationsEnabled, isFalse);
    expect(flameGame.world.debugSceneWriteCount, sceneWrites);

    await settings.reset();
    await tester.pump();
    expect(flameGame.world.cityPlanningLayer.isVisible, isFalse);
    expect(host.combatAnimationsEnabled, isTrue);
    expect(host.movementAnimationsEnabled, isTrue);
    expect(flameGame.world.unitLayer.idleAnimationsEnabled, isTrue);
    expect(flameGame.world.routeLayer.animationsEnabled, isTrue);
  });
}

final class _Planning implements CityPlanningSessionPort {
  _Planning(this.player);
  final PlayerMapView player;
  int calls = 0;
  @override
  Future<CityPlanningView> cityPlanning({required int expectedRevision}) async {
    calls++;
    return CityPlanningView(
      stamp: player.stamp,
      actorPlayerId: player.actorPlayerId,
      citySites: const [(col: 0, row: 0)],
      growthTiles: const [(col: 0, row: 0), (col: 1, row: 0)],
    );
  }
}
