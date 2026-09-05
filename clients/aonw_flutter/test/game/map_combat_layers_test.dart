import 'dart:ui' as ui;

import 'package:aonw_flutter/features/combat/application/combat_state.dart';
import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/flame_map_camera.dart';
import 'package:aonw_flutter/game/presentation/flame_scene_patch.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Lato')
      ..addFont(rootBundle.load('assets/fonts/Lato-Bold.ttf'));
    await loader.load();
  });
  testWithGame<AonwFlameGame>(
    'counts authoritative threats and caches geometry across hover updates',
    AonwFlameGame.new,
    (game) async {
      final scene = _threatScene();
      const selected = MapInteractionState(selectedUnitId: 'preview-commander');
      game.replaceScene(_snapshot(scene, interaction: selected));
      await game.ready();
      final layer = game.world.threatOverlayLayer;
      expect(layer.debugCoordinates, [(col: 0, row: 0), (col: 1, row: 0)]);
      expect(layer.debugThreatCounts, [1, 3]);
      expect(layer.children, isEmpty);
      final builds = layer.debugGeometryBuildCount;
      game.replaceCursor((col: 2, row: 0));
      game.replaceScene(_snapshot(scene, interaction: selected));
      expect(layer.debugGeometryBuildCount, builds);
      game.replaceScene(
        _snapshot(
          scene,
          interaction: const MapInteractionState(
            selectedUnitId: 'preview-commander',
            combat: CombatState(
              attackerUnitId: 'preview-commander',
              defenderCoordinate: (col: 1, row: 0),
              commandPending: true,
            ),
          ),
        ),
      );
      expect(layer.debugDimmed, isTrue);
      game.replaceScene(_snapshot(scene));
      expect(layer.isVisible, isFalse);
      expect(layer.debugHexCount, 0);
      game.replaceScene(
        _snapshot(
          scene,
          interaction: const MapInteractionState(selectedUnitId: 'enemy-0'),
        ),
      );
      expect(layer.isVisible, isFalse);
    },
  );

  testWithGame<AonwFlameGame>(
    'renders threat colors trajectory and distinct combat alerts',
    AonwFlameGame.new,
    (game) async {
      final scene = _threatScene();
      game.replaceScene(_snapshot(scene));
      await game.ready();
      game.replaceScene(_combatSnapshot(scene, 1));
      final effects = game.world.effectHost;
      expect(effects.debugActiveDamageLabelCount, 2);
      expect(effects.debugActiveParticleCount, 28);
      final cache = game.world.debugStaticRenderCache!;
      final start = cache.projection.hexTopFaceCenter((col: 0, row: 0));
      final end = cache.projection.hexTopFaceCenter((col: 1, row: 0));
      expect(
        effects.debugCombatEndpoints!.attacker,
        ui.Offset(start.x, start.y),
      );
      expect(effects.debugCombatEndpoints!.defender, ui.Offset(end.x, end.y));
      final pulse = effects.debugCombatPulse;
      effects.update(0.23);
      expect(effects.debugCombatPulse, isNot(pulse));
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)
        ..drawColor(const ui.Color(0xff202024), ui.BlendMode.src)
        ..translate(24, 45);
      game.world.threatOverlayLayer.render(canvas);
      effects.render(canvas);
      final picture = recorder.endRecording();
      final image = await picture.toImage(340, 210);
      await expectLater(
        image,
        matchesGoldenFile('goldens/map_combat_overlays.png'),
      );
      image.dispose();
      picture.dispose();
      effects.update(1.05);
      expect(effects.debugActiveEffectCount, 0);
      expect(game.paused, isTrue);
      final updates = effects.debugActiveUpdateCount;
      effects.update(1);
      expect(effects.debugActiveUpdateCount, updates);
    },
  );

  testWithGame<AonwFlameGame>(
    'bounds combat pool preserves static reduced-motion alerts and skips',
    AonwFlameGame.new,
    (game) async {
      final scene = _threatScene();
      game.replaceScene(_snapshot(scene));
      await game.ready();
      final effects = game.world.effectHost;
      for (var revision = 1; revision <= 8; revision++) {
        game.replaceScene(_combatSnapshot(scene, revision));
      }
      expect(
        effects.debugActiveCombatEffectCount,
        effects.debugMaximumCombatEffectCount,
      );
      game.setReducedMotion(true);
      expect(effects.debugActiveDamageLabelCount, 8);
      expect(effects.debugActiveParticleCount, 0);
      expect(effects.debugCombatPulse, 0.55);
      effects.update(0.32);
      expect(effects.debugCombatPulse, 0.55);
      game.setEffectPlaybackSpeed(4);
      effects.update(0.24);
      expect(effects.debugActiveEffectCount, 0);
      game.replaceScene(_combatSnapshot(scene, 9));
      expect(effects.debugActiveCombatEffectCount, 1);
      game.skipEffects();
      expect(effects.debugActiveEffectCount, 0);
      expect(effects.debugActiveDamageLabelCount, 0);
      expect(effects.debugActiveParticleCount, 0);
      expect(game.paused, isTrue);
    },
  );

  testWithGame<AonwFlameGame>(
    'combat animation choices preserve damage and respect reduced motion',
    AonwFlameGame.new,
    (game) async {
      final scene = _threatScene();
      game.setViewportActive(true);
      game.replaceScene(_snapshot(scene));
      await game.ready();
      game.replaceScene(_combatSnapshot(scene, 1));
      final effects = game.world.effectHost;
      expect(effects.debugActiveParticleCount, 28);
      final completion = game.waitForCommandEffects();
      game.setCombatAnimations(false);
      expect(effects.debugReducedMotion, isFalse);
      expect(effects.movementAnimationsEnabled, isTrue);
      expect(effects.debugActiveDamageLabelCount, 2);
      expect(effects.debugActiveParticleCount, 0);
      final early = await _renderEffects(game);
      effects.update(0.8);
      final late = await _renderEffects(game);
      expect(late, early, reason: 'Disabled combat renders static evidence.');
      game.setReducedMotion(true);
      game.setCombatAnimations(true);
      expect(effects.debugCombatPulse, 0.55);
      game.setCombatAnimations(false);
      game.setReducedMotion(false);
      expect(effects.debugCombatPulse, 0.55);
      effects.update(0.48);
      game.mapCamera.skipMotion();
      await completion;
      expect(effects.debugActiveEffectCount, 0);
      expect(game.paused, isTrue);

      game.replaceScene(_combatSnapshot(scene, 2));
      expect(effects.debugActiveDamageLabelCount, 2);
      expect(effects.debugActiveParticleCount, 0);
      game.skipEffects();
      game.setCombatAnimations(true);
      game.replaceScene(_combatSnapshot(scene, 3));
      expect(effects.debugActiveParticleCount, 28);
      effects.update(0.23);
      expect(effects.debugCombatPulse, isNot(0.55));
      game.skipEffects();
    },
  );

  testWithGame<AonwFlameGame>(
    'clears transient combat data when the recipient or map changes',
    AonwFlameGame.new,
    (game) async {
      final scene = _threatScene();
      game.replaceScene(_snapshot(scene));
      await game.ready();
      final accepted = _combatSnapshot(scene, 1);
      game.replaceScene(accepted);
      expect(game.world.effectHost.debugActiveCombatEffectCount, 1);
      final nextRecipient = _combatSnapshot(scene, 2, actor: 'next-player');
      expect(FlameScenePatch.between(accepted, nextRecipient).combats, isEmpty);
      game.replaceScene(nextRecipient);
      expect(game.world.effectHost.debugActiveEffectCount, 0);
      game.replaceScene(_snapshot(scene));
      game.replaceScene(accepted);
      game.replaceScene(_snapshot(testMapScene(mapId: 'another-map')));
      expect(game.world.effectHost.debugActiveEffectCount, 0);
      game.clearScene();
      expect(game.world.threatOverlayLayer.isVisible, isFalse);
    },
  );
}

Future<List<int>> _renderEffects(AonwFlameGame game) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)..translate(24, 45);
  game.world.effectHost.render(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(340, 210);
  final bytes = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  picture.dispose();
  return bytes;
}

MapScene _threatScene() => testMapScene(
  units: [
    testVisibleUnit(threatenedHexes: const [(col: 2, row: 1)]),
    for (var index = 0; index < 3; index++)
      testVisibleUnit(
        id: 'enemy-$index',
        ownerPlayerId: 'foreign-player',
        coordinate: (col: index, row: 1),
        threatenedHexes: [if (index == 0) (col: 0, row: 0), (col: 1, row: 0)],
      ),
  ],
);

MapRenderSnapshot _snapshot(
  MapScene scene, {
  MapInteractionState interaction = const MapInteractionState(),
}) => MapRenderSnapshot(
  map: scene.map,
  reference: scene.reference,
  player: scene.player,
  interaction: interaction,
);

MapRenderSnapshot _combatSnapshot(
  MapScene scene,
  int revision, {
  String actor = 'preview-player',
}) => MapRenderSnapshot(
  map: scene.map,
  reference: scene.reference,
  player: PlayerMapView.preview(
    actorPlayerId: actor,
    stamp: SessionStampView(
      revision: revision,
      stateDigest: '$revision'.padLeft(64, 'd'),
      mapHash: scene.map.contentHash,
      rulesetHash: 'c' * 64,
    ),
    turn: 1,
    pendingAction: null,
    units: scene.player.units,
  ),
  interaction: MapInteractionState(
    selectedUnitId: 'preview-commander',
    combat: CombatState(
      attackerUnitId: 'preview-commander',
      defenderCoordinate: (col: 1, row: 0),
      lastExecution: testCombatExecutionView(revision: revision),
    ),
  ),
);
