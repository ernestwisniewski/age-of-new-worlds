import 'dart:async';

import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/hex_inspection_state.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_gamepad_input.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_input.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/features/map/read_model/hex_inspection_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/hex_inspection_test_fixture.dart';
import '../../../../support/localized_test_app.dart';
import '../../../../support/map_test_fixture.dart';
import '../../../../support/test_map_input_source.dart';

void main() {
  testWidgets('Y inspects the independent cursor and B preserves selection', (
    tester,
  ) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    await harness.pump(tester);
    harness.controller.selectUnit('preview-commander');
    await tester.pumpAndSettle();
    harness.input.add(MapInputCommand.cursorRight);
    await tester.pumpAndSettle();
    final before = harness.ready.interaction;
    final viewMode = before.viewMode;
    harness.input.addContinuous(const MapGamepadInput(inspectHex: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(harness.inspection.requests.single.coordinate, (col: 1, row: 0));
    expect(harness.ready.inspection, isA<HexInspectionReady>());
    expect(harness.ready.interaction, same(before));
    expect(harness.ready.interaction.viewMode, viewMode);
    expect(
      find.byKey(const ValueKey('hex-inspection-popover')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(harness.inspection.requests, hasLength(1));
    harness.input.addContinuous(MapGamepadInput.idle);
    await tester.pump();
    harness.input.add(MapInputCommand.cancel);
    await tester.pumpAndSettle();
    expect(harness.ready.inspection, isNull);
    expect(harness.ready.interaction, same(before));
    expect(find.byKey(const ValueKey('hex-inspection-popover')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing a loading popup ignores the late response', (
    tester,
  ) async {
    final result = Completer<HexInspectionView>();
    final harness = _Harness(onInspect: (_, _) => result.future);
    addTearDown(harness.dispose);
    await harness.pump(tester);
    harness.input.add(MapInputCommand.inspectHex);
    await tester.pump();
    expect(harness.ready.inspection, isA<HexInspectionLoading>());
    final coordinate = harness.inspection.requests.single.coordinate;
    harness.input.add(MapInputCommand.cancel);
    await tester.pump();
    expect(harness.ready.inspection, isNull);
    result.complete(
      testHexInspectionView(scene: harness.scene, coordinate: coordinate),
    );
    await tester.pumpAndSettle();
    expect(harness.ready.inspection, isNull);
    expect(find.byKey(const ValueKey('hex-inspection-popover')), findsNothing);
  });
}

final class _Harness {
  _Harness({
    Future<HexInspectionView> Function(int, ({int col, int row}))? onInspect,
  }) {
    inspection = FakeHexInspectionSession(scene: scene, onInspect: onInspect);
    controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(
        FakeGameSession.success(
          scene,
          reachableResult: testReachableView(),
          routeResult: testRoutePlanView(),
        ),
        hexInspection: inspection,
      ),
    );
  }
  final scene = testMapScene(cols: 4, rows: 4, units: [testVisibleUnit()]);
  final input = TestMapInputSource();
  final game = AonwFlameGame();
  late final FakeHexInspectionSession inspection;
  late final MapPresentationController controller;
  GameSessionReady get ready => controller.state as GameSessionReady;

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      LocalizedTestApp(
        home: Scaffold(
          body: MapScreen(
            controller: controller,
            inputSource: input,
            flameGameFactory: () => game,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> dispose() async {
    controller.dispose();
    await input.close();
  }
}
