import 'dart:async';

import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_gamepad_input.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_input.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/features/turns/application/turn_session_port.dart';
import 'package:aonw_flutter/features/turns/read_model/pending_turn_actions_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';
import '../../../../support/map_test_fixture.dart';
import '../../../../support/test_map_input_source.dart';

void main() {
  testWidgets(
    'bumpers focus map work once per press; research owns Start and B',
    (tester) async {
      final h = await _Harness.mount(tester);
      await h.press(tester, const MapGamepadInput(focusNext: true));
      expect(h.ready.interaction.selectedUnitId, 'preview-commander');
      await tester.pump(const Duration(milliseconds: 300));
      expect(h.session.pendingTurnActionsRevisions, [0]);
      await h.release(tester);
      await h.press(tester, const MapGamepadInput(focusPrevious: true));
      expect(h.ready.interaction.researchFocused, isTrue);
      await tester.pump();
      expect(find.byKey(const ValueKey('close-research')), findsOneWidget);
      await h.release(tester);
      await h.press(tester, const MapGamepadInput(primaryAction: true));
      expect(h.session.pendingTurnActionsRevisions, [0, 0]);
      expect(h.session.endTurnCalls, 0);
      await h.release(tester);
      h.input.add(MapInputCommand.cancel);
      await tester.pumpAndSettle();
      expect(h.ready.interaction.researchFocused, isFalse);
      expect(h.ready.interaction.selectedUnitId, 'preview-commander');
      expect(find.byKey(const ValueKey('close-research')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Start focuses pending work, then ends an empty turn once while held',
    (tester) async {
      final h = await _Harness.mount(tester);
      await h.press(tester, const MapGamepadInput(primaryAction: true));
      expect(h.ready.interaction.selectedUnitId, 'preview-commander');
      expect(h.session.endTurnCalls, 0);
      await h.release(tester);
      h.session.pendingTurnActionsResult = h.work([]);
      await h.press(tester, const MapGamepadInput(primaryAction: true));
      await tester.pump(const Duration(milliseconds: 500));
      expect(h.session.endTurnCalls, 1);
      expect(h.session.lastEndTurnExpectedRevision, 0);
      await h.release(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('opening and closing a panel invalidates a late Start response', (
    tester,
  ) async {
    final h = await _Harness.mount(tester);
    final response = Completer<PendingTurnActionsView>();
    h.session.pendingTurnActionsHandler = (_) => response.future;
    await h.press(tester, const MapGamepadInput(primaryAction: true));
    await h.release(tester);
    expect(h.session.pendingTurnActionsRevisions, [0]);
    await tester.tap(find.byKey(const ValueKey('open-objectives')));
    await tester.pumpAndSettle();
    h.input.add(MapInputCommand.cancel);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('close-objectives')), findsNothing);
    response.complete(h.work([]));
    await tester.pumpAndSettle();
    expect(h.session.endTurnCalls, 0);
    expect(h.ready.interaction.selected, isNull);
  });

  testWidgets(
    'HUD focus and simultaneous activation prevent map turn routing',
    (tester) async {
      final h = await _Harness.mount(tester);
      await h.press(
        tester,
        const MapGamepadInput(primaryAction: true, activate: true),
      );
      await h.release(tester);
      expect(h.session.pendingTurnActionsRevisions, isEmpty);
      await h.press(tester, const MapGamepadInput(hudFocusNext: true));
      await h.release(tester);
      await h.press(tester, const MapGamepadInput(focusNext: true));
      await h.release(tester);
      await h.press(tester, const MapGamepadInput(primaryAction: true));
      await h.release(tester);
      expect(h.session.pendingTurnActionsRevisions, isEmpty);
      expect(h.session.endTurnCalls, 0);
    },
  );
}

final class _Harness {
  _Harness() {
    session = FakeGameSession.success(
      scene,
      reachableResult: testReachableView(),
      turnFailure: const TurnSessionException(
        code: 'offline',
        message: 'Unavailable',
      ),
    );
    session.pendingTurnActionsResult = work([
      const PendingUnitTurnActionView(
        unitId: 'preview-commander',
        coordinate: (col: 0, row: 0),
      ),
      const PendingResearchTurnActionView(),
    ]);
    controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );
  }
  final scene = testMapScene(cols: 7, rows: 7, units: [testVisibleUnit()]);
  final input = TestMapInputSource();
  final game = AonwFlameGame();
  late final FakeGameSession session;
  late final MapPresentationController controller;
  GameSessionReady get ready => controller.state as GameSessionReady;
  PendingTurnActionsView work(List<PendingTurnActionView> actions) =>
      PendingTurnActionsView(
        stamp: scene.player.stamp,
        actorPlayerId: scene.player.actorPlayerId,
        canActivate: true,
        actions: actions,
      );

  static Future<_Harness> mount(WidgetTester tester) async {
    final h = _Harness();
    addTearDown(h.controller.dispose);
    addTearDown(h.input.close);
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      LocalizedTestApp(
        home: Scaffold(
          body: MapScreen(
            controller: h.controller,
            inputSource: h.input,
            flameGameFactory: () => h.game,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return h;
  }

  Future<void> press(WidgetTester tester, MapGamepadInput value) async {
    input.addContinuous(value);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
  }

  Future<void> release(WidgetTester tester) async {
    input.addContinuous(MapGamepadInput.idle);
    await tester.pump();
    await tester.pumpAndSettle();
  }
}
