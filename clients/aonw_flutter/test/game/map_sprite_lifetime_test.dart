import 'dart:ui' as ui;

import 'package:aonw_flutter/design_system/assets/sprite_frames.dart';
import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_action_palette_view.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/workers/read_model/worker_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/map_display_options.dart';
import 'package:aonw_flutter/game/map/map_sprite_catalog.dart';
import 'package:aonw_flutter/game/map/map_unit_sprite_animation.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a kind change releases only atlases without another sprite', () async {
    final first = MapUnitSpriteAnimation(
      kind: VisibleUnitKind.worker,
      onLoaded: () {},
    );
    final second = MapUnitSpriteAnimation(
      kind: VisibleUnitKind.worker,
      onLoaded: () {},
    );
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await Future.wait([first.load(), second.load()]);
    final worker = first.frame!.image;
    first.setKind(VisibleUnitKind.commander);
    await first.load();
    expect(worker.debugDisposed, isFalse);
    expect(second.frame!.image, same(worker));
    second.dispose();
    expect(worker.debugDisposed, isTrue);
    expect(first.frame!.image.debugDisposed, isFalse);
    final commander = first.frame!.image;
    first.dispose();
    expect(commander.debugDisposed, isTrue);
    expect(SpriteFrames.debugAtlasBytes, isEmpty);
  });

  testWithGame<AonwFlameGame>(
    'map layers retain shared atlases until their final presentation ends',
    AonwFlameGame.new,
    (game) async {
      addTearDown(game.clearScene);
      final snapshot = _snapshot();
      final warmup = SpriteFrames.createScope();
      addTearDown(warmup.dispose);
      await warmup.preload([
        MapSpriteCatalog.cityFrame(visualLevel: 0),
        MapSpriteCatalog.improvementFrame(FieldImprovementKind.farm),
      ]);
      game.setMapDisplayOptions(
        const MapDisplayOptions(showTerrainIcons: true),
      );
      game.replaceScene(snapshot);
      await game.ready();
      final world = game.world;
      await world.unitLayer.componentForUnit('worker')!.debugLoadSprite();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      world.cityLayer.debugComponentForCity('city')!.render(canvas);
      world.workerInfrastructureLayer
          .debugImprovementAt((col: 1, row: 1))!
          .render(canvas);
      recorder.endRecording().dispose();
      await world.routeLayer.debugLoadGhost();
      await world.tileDetailsLayer.debugPreloadVisibleFrames();
      await Future<void>.delayed(Duration.zero);
      warmup.dispose();
      final worker = world.unitLayer
          .componentForUnit('worker')!
          .debugSpriteFrame!
          .image;
      final city = world.cityLayer
          .debugComponentForCity('city')!
          .debugSpriteFrame!
          .image;
      final farm = world.workerInfrastructureLayer
          .debugImprovementAt((col: 1, row: 1))!
          .debugSpriteFrame!
          .image;
      expect(world.routeLayer.debugGhostFrameId, contains('unit.worker.'));
      world.unitLayer.clearLayer();
      expect(
        worker.debugDisposed,
        isFalse,
        reason: 'the route still draws this unit',
      );
      world.routeLayer.clearLayer();
      expect(worker.debugDisposed, isTrue);
      world.cityLayer.clearLayer();
      expect(city.debugDisposed, isTrue);
      world.workerInfrastructureLayer.clearLayer();
      expect(
        farm.debugDisposed,
        isFalse,
        reason: 'the action palette still draws this improvement',
      );
      world.actionPaletteLayer.clearLayer();
      expect(farm.debugDisposed, isTrue);
      world.tileDetailsLayer.clearLayer();
      expect(SpriteFrames.debugAtlasBytes, isEmpty);
      await game.ready();
      expect(SpriteFrames.debugAtlasBytes, isEmpty);
    },
  );

  testWithGame<AonwFlameGame>(
    'city and improvement atlases follow the camera without replacing components',
    AonwFlameGame.new,
    (game) async {
      addTearDown(game.clearScene);
      game.replaceScene(_snapshot());
      await game.ready();
      final city = game.world.cityLayer.debugComponentForCity('city')!;
      final farm = game.world.workerInfrastructureLayer.debugImprovementAt((
        col: 1,
        row: 1,
      ))!;
      void render(ui.Rect clip) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder)..clipRect(clip);
        city.render(canvas);
        farm.render(canvas);
        recorder.endRecording().dispose();
      }

      const away = ui.Rect.fromLTWH(1000, 1000, 200, 200);
      const nearby = ui.Rect.fromLTWH(-20, -20, 200, 200);
      render(away);
      expect(city.debugSpriteVisible, isFalse);
      expect(farm.debugSpriteVisible, isFalse);
      expect(city.debugSpriteFrame, isNull);
      expect(farm.debugSpriteFrame, isNull);
      final warmup = SpriteFrames.createScope();
      addTearDown(warmup.dispose);
      await warmup.preload([
        MapSpriteCatalog.cityFrame(visualLevel: 0),
        MapSpriteCatalog.improvementFrame(FieldImprovementKind.farm),
      ]);
      final cityPaints = city.debugPaintCount;
      final farmPaints = farm.debugPaintCount;
      render(const ui.Rect.fromLTWH(180, 0, 20, 20));
      await Future<void>.delayed(Duration.zero);
      expect(city.debugSpriteVisible, isTrue);
      expect(farm.debugSpriteVisible, isTrue);
      expect(city.debugPaintCount, cityPaints);
      expect(farm.debugPaintCount, farmPaints);
      render(nearby);
      await Future<void>.delayed(Duration.zero);
      expect(city.debugSpriteFrame, isNotNull);
      expect(farm.debugSpriteFrame, isNotNull);
      final cityFrame = city.debugSpriteFrame;
      final farmFrame = farm.debugSpriteFrame;
      render(away);
      expect(city.debugSpriteFrame, isNull);
      expect(farm.debugSpriteFrame, isNull);
      render(nearby);
      await Future<void>.delayed(Duration.zero);
      expect(city.debugSpriteFrame, same(cityFrame));
      expect(farm.debugSpriteFrame, same(farmFrame));
      expect(game.world.cityLayer.debugComponentForCity('city'), same(city));
      expect(
        game.world.workerInfrastructureLayer.debugImprovementAt((
          col: 1,
          row: 1,
        )),
        same(farm),
      );
    },
  );

  testWithGame<AonwFlameGame>(
    'clearing a scene also releases units removed before mounting',
    AonwFlameGame.new,
    (game) async {
      game.replaceScene(_snapshot());
      final unit = game.world.unitLayer.componentForUnit('worker')!;
      final loading = unit.debugLoadSprite();
      expect(unit.isMounted, isFalse);
      game.clearScene();
      await loading;
      await game.ready();
      await Future<void>.delayed(Duration.zero);
      expect(unit.debugSpriteFrame, isNull);
      expect(SpriteFrames.debugAtlasBytes, isEmpty);
    },
  );
}

MapRenderSnapshot _snapshot() {
  final scene = testMapScene(
    units: [testVisibleUnit(id: 'worker', kind: VisibleUnitKind.worker)],
    cities: [testCityView(id: 'city')],
    fieldImprovements: const [
      FieldImprovementView(
        coordinate: (col: 1, row: 1),
        improvement: FieldImprovementKind.farm,
        eraColumn: 0,
      ),
    ],
  );
  return MapRenderSnapshot(
    map: scene.map,
    reference: scene.reference,
    player: scene.player,
    interaction: MapInteractionState(
      selectedUnitId: 'worker',
      route: testRoutePlanView(unitId: 'worker'),
    ),
    actionPalette: MapWorkerActionPaletteView(
      coordinate: (col: 1, row: 1),
      enabled: true,
      unitId: 'worker',
      options: const [
        MapWorkerImprovementOptionView(
          improvement: FieldImprovementKind.farm,
          label: 'Farm',
          turnLabel: '2 turns',
        ),
      ],
      previewedImprovement: null,
      confirmLabel: 'Confirm',
    ),
  );
}
