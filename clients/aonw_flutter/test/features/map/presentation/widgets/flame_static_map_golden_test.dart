import 'dart:typed_data';

import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_reference_bundle.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/movement_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/map_test_fixture.dart';
import 'starter_map_golden_support.dart';

void main() {
  final defaultComparator = goldenFileComparator;
  if (defaultComparator is LocalFileComparator) {
    goldenFileComparator = _OnePixelGoldenFileComparator(
      defaultComparator.basedir.resolve('flame_static_map_golden_test.dart'),
    );
  }

  testWidgets('freezes the batched Flame static layers', (tester) async {
    final loaded = await loadStarterMapGoldenFixture(tester);
    final map = loaded.map;
    final reference = loaded.reference;
    final game = AonwFlameGame();
    await tester.binding.setSurfaceSize(const Size(660, 728));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    game.sceneSink.replaceScene(
      _staticSnapshot(map, reference, referenceVisible: false),
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: const ValueKey('flame-starter-golden'),
          child: ColoredBox(
            color: Colors.black,
            child: GameWidget<AonwFlameGame>(
              game: game,
              autofocus: false,
              behavior: HitTestBehavior.deferToChild,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await game.toBeLoaded();
    });
    await tester.pump();
    await tester.pump();
    expect(game.debugMountCount, 1);
    await tester.runAsync(game.ready);
    game.stepEngine(stepTime: 0);
    await tester.pump();
    expect(game.world.referenceLayer.debugDecodedPageCount, 1);
    expect(game.world.referenceLayer.isVisible, isFalse);

    await expectLater(
      find.byKey(const ValueKey('flame-starter-golden')),
      matchesGoldenFile('goldens/flame_starter_map.png'),
    );

    game.sceneSink.replaceScene(
      _staticSnapshot(map, reference, referenceVisible: true),
    );
    await tester.pump();
    expect(game.world.terrainLayer.debugCacheUpdateCount, 1);
    expect(game.world.referenceLayer.debugVisibilityUpdateCount, 2);
    expect(game.world.referenceLayer.isVisible, isTrue);
    expect(game.world.gridLayer.debugCacheUpdateCount, 1);
    await expectLater(
      find.byKey(const ValueKey('flame-starter-golden')),
      matchesGoldenFile('goldens/flame_starter_map_reference.png'),
    );

    game.sceneSink.replaceScene(_gameplaySnapshot(map, reference));
    game.sceneSink.replaceCursor((col: 1, row: 1));
    game.stepEngine(stepTime: 0);
    await tester.pump();
    await expectLater(
      find.byKey(const ValueKey('flame-starter-golden')),
      matchesGoldenFile('goldens/flame_gameplay_map.png'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

final class _OnePixelGoldenFileComparator extends LocalFileComparator {
  _OnePixelGoldenFileComparator(super.testFile);

  static const _goldenPixelCount = 660 * 728;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent * _goldenPixelCount <= 1.000001) {
      result.dispose();
      return true;
    }

    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}

MapRenderSnapshot _staticSnapshot(
  MapView map,
  MapReferenceBundle reference, {
  required bool referenceVisible,
}) => MapRenderSnapshot(
  map: map,
  interaction: MapInteractionState(referenceVisible: referenceVisible),
  reference: reference,
  player: _player(map),
);

MapRenderSnapshot _gameplaySnapshot(
  MapView map,
  MapReferenceBundle reference,
) => MapRenderSnapshot(
  map: map,
  interaction: MapInteractionState(
    selected: (col: 2, row: 1),
    selectedUnitId: 'preview-commander',
    reachable: testReachableView(
      tiles: const [
        ReachableTileView(
          coordinate: (col: 2, row: 1),
          costUnits: 4,
          exhaustsMovement: false,
        ),
        ReachableTileView(
          coordinate: (col: 3, row: 1),
          costUnits: 8,
          exhaustsMovement: false,
        ),
        ReachableTileView(
          coordinate: (col: 2, row: 2),
          costUnits: 8,
          exhaustsMovement: false,
        ),
      ],
    ),
    route: testRoutePlanView(
      origin: (col: 2, row: 1),
      target: (col: 3, row: 1),
    ),
    referenceVisible: false,
  ),
  reference: reference,
  player: _player(
    map,
    units: [
      testVisibleUnit(coordinate: (col: 2, row: 1)),
      testVisibleUnit(id: 'preview-scout', coordinate: (col: 4, row: 2)),
      testVisibleUnit(
        id: 'foreign-warrior',
        ownerPlayerId: 'foreign-player',
        coordinate: (col: 3, row: 3),
      ),
    ],
  ),
);

PlayerMapView _player(MapView map, {List<VisibleUnitView> units = const []}) =>
    PlayerMapView.preview(
      actorPlayerId: 'preview-player',
      stamp: starterMapGoldenStamp(map.contentHash),
      turn: 1,
      pendingAction: null,
      units: units,
    );
