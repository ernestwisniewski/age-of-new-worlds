import 'package:aonw_flutter/design_system/aonw_theme.dart';
import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/map/read_model/map_view_mode.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_scope.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter/widgets.dart';

import '../../test/support/localized_test_app.dart';
import '../../test/support/map_test_fixture.dart';
import 'large_gameplay_snapshot.dart';

/// Fixed presentation workload; gameplay correctness is covered by native sessions.
final class FullHudPerformanceHost {
  FullHudPerformanceHost() {
    final snapshot = largeGameplaySnapshot();
    final player = snapshot.player;
    scene = MapScene(
      map: snapshot.map,
      reference: snapshot.reference,
      player: PlayerMapView(
        actorPlayerId: player.actorPlayerId,
        stamp: player.stamp,
        turnMode: player.turnMode,
        participants: player.participants,
        economy: player.economy,
        research: player.research,
        victory: player.victory,
        turnView: player.turnView,
        diplomacy: player.diplomacy,
        units: player.units,
        cities: player.cities,
        fieldImprovements: player.fieldImprovements,
        roads: player.roads,
        fog: MapFogView(
          enabled: true,
          discoveredHexes: [
            for (final tile in snapshot.map.tiles)
              if (tile.coordinate.row < 25) tile.coordinate,
          ],
          visibleHexes: [
            for (final tile in snapshot.map.tiles)
              if (tile.coordinate.row < 20) tile.coordinate,
          ],
        ),
      ),
    );
    controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(FakeGameSession.success(scene)),
    );
  }

  MapRenderSnapshot get snapshot {
    return MapRenderSnapshot(
      map: scene.map,
      reference: scene.reference,
      player: scene.player,
      interaction: const MapInteractionState(viewMode: MapViewMode.tile),
    );
  }

  late final MapScene scene;
  late final MapPresentationController controller;
  final settings = ClientSettingsController.ephemeral();
  final game = AonwFlameGame();

  Future<void> prepare() async {
    await settings.load();
    await settings.update(
      settings.settings.copyWith(showUnitIdleAnimations: false),
    );
    await controller.load();
  }

  Widget build() => LocalizedTestApp(
    theme: AonwTheme.dark,
    home: ClientSettingsScope(
      controller: settings,
      child: MapScreen(
        controller: controller,
        autoLoad: false,
        flameGameFactory: () => game,
        onOpenSettings: () {},
      ),
    ),
  );

  void dispose() {
    controller.dispose();
    settings.dispose();
  }
}
