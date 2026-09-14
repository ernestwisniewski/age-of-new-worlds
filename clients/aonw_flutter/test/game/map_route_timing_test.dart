import 'dart:ui' as ui;

import 'package:aonw_flutter/features/map/read_model/movement_view.dart';
import 'package:aonw_flutter/game/map/map_interaction_geometry.dart';
import 'package:aonw_flutter/game/map/map_route_layer.dart';
import 'package:aonw_flutter/game/map/static_map_layers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  testWidgets('engine turns mark rough entry and every future boundary', (
    tester,
  ) async {
    final layer = await _mount(tester, [1, 1, 2, 2, 3, 3]);
    expect(layer.debugCurrentTurnSegmentCount, 1);
    expect(layer.debugFutureTurnSegmentCount, 4);
    expect(layer.debugBoundaryCount, 2);
  });

  testWidgets('a spent current turn leaves every travel segment for later', (
    tester,
  ) async {
    final layer = await _mount(tester, [1, 2, 3, 3, 4, 4], available: 0);
    expect(layer.debugCurrentTurnSegmentCount, 0);
    expect(layer.debugFutureTurnSegmentCount, 5);
    expect(layer.debugBoundaryCount, 2);
  });

  testWidgets('timing changes rebuild geometry while equal refreshes keep it', (
    tester,
  ) async {
    final scene = testMapScene(cols: 6);
    final cache = MapStaticRenderCache.build(scene.map);
    final layer = await _mount(tester, [1, 1, 2, 2, 3, 3]);
    final builds = layer.debugPathBuildCount;
    layer.applyRoute(cache, _plan([1, 1, 2, 2, 3, 3]), scene.player);
    expect(layer.debugPathBuildCount, builds);
    layer.applyRoute(cache, _plan([1, 1, 2, 2, 2, 2]), scene.player);
    expect(layer.debugPathBuildCount, builds + 1);
    expect(layer.debugBoundaryCount, 1);
  });

  testWidgets('draws all turn boundaries with motion disabled', (tester) async {
    final layer = await _mount(tester, [1, 1, 2, 2, 3, 3]);
    layer.setAnimations(false);
    final scene = testMapScene(cols: 6);
    final cache = MapStaticRenderCache.build(scene.map);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawColor(const ui.Color(0xff20313e), ui.BlendMode.src);
    canvas.translate(20, 40);
    layer.render(canvas);
    final picture = recorder.endRecording();
    final image = await tester.runAsync(() => picture.toImage(700, 220));
    picture.dispose();
    final bytes = await tester.runAsync(() => image!.toByteData());
    final pixels = bytes!.buffer.asUint8List();
    for (final col in [1, 3]) {
      final center =
          mapProjectedTopFaceCenter(cache, (col: col, row: 0)) +
          const ui.Offset(20, 40);
      final index = (center.dy.round() * image!.width + center.dx.round()) * 4;
      expect(pixels.sublist(index, index + 3), isNot([0x20, 0x31, 0x3e]));
    }
    await expectLater(image, matchesGoldenFile('goldens/map_route_turns.png'));
    image!.dispose();
  });
}

Future<MapRouteLayerComponent> _mount(
  WidgetTester tester,
  List<int> turns, {
  int available = 3,
}) async {
  final scene = testMapScene(cols: 6);
  final layer = MapRouteLayerComponent();
  addTearDown(layer.clearLayer);
  await tester.runAsync(() async {
    layer.applyRoute(
      MapStaticRenderCache.build(scene.map),
      _plan(turns, available: available),
      scene.player,
    );
    await layer.debugLoadGhost();
  });
  return layer;
}

RoutePlanView _plan(List<int> turns, {int available = 3}) => RoutePlanView(
  roadStepIndices: const [],
  stamp: testSessionStamp(),
  unitId: 'preview-commander',
  target: (col: 5, row: 0),
  destination: (col: 5, row: 0),
  totalCostUnits: 14,
  availableMovementUnits: available,
  remainingMovementUnits: 0,
  estimatedTurns: turns.last,
  stepTurns: turns,
  steps: [
    for (final (col, cost, cumulative) in [
      (0, 0, 0),
      (1, 4, 4),
      (2, 2, 6),
      (3, 4, 10),
      (4, 2, 12),
      (5, 2, 14),
    ])
      MovementStepView(
        coordinate: (col: col, row: 0),
        enterCostUnits: cost,
        cumulativeCostUnits: cumulative,
      ),
  ],
);
