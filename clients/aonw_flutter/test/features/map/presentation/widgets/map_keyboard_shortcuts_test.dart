import 'dart:async';

import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/flame_map_viewport.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/features/map/read_model/map_view_mode.dart';
import 'package:aonw_flutter/features/settings/application/client_settings.dart';
import 'package:aonw_flutter/features/settings/application/client_settings_store.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_scope.dart';
import 'package:aonw_flutter/features/turns/application/turn_session_port.dart';
import 'package:aonw_flutter/features/turns/read_model/pending_turn_actions_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/hex_inspection_test_fixture.dart';
import '../../../../support/localized_test_app.dart';
import '../../../../support/map_test_fixture.dart';
import '../../../../support/test_map_input_source.dart';

void main() {
  testWidgets('Space focuses pending work and ends an empty turn only once', (
    tester,
  ) async {
    final h = await _Harness.mount(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(h.ready.interaction.selectedUnitId, 'preview-commander');
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(h.session.pendingTurnActionsRevisions, [0]);
    expect(h.session.endTurnCalls, 0);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    h.session.pendingTurnActionsResult = h.work([]);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(h.session.endTurnCalls, 1);
    expect(h.session.lastEndTurnExpectedRevision, 0);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
  });

  testWidgets('brackets cycle pending work and never end an empty turn', (
    tester,
  ) async {
    final h = await _Harness.mount(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.bracketRight);
    await tester.pumpAndSettle();
    expect(h.ready.interaction.selectedUnitId, 'preview-commander');
    await tester.sendKeyEvent(LogicalKeyboardKey.bracketLeft);
    await tester.pumpAndSettle();
    expect(h.ready.interaction.researchFocused, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(h.session.pendingTurnActionsRevisions, [0, 0]);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(h.ready.interaction.researchFocused, isFalse);
    h.session.pendingTurnActionsResult = h.work([]);
    await tester.sendKeyEvent(LogicalKeyboardKey.bracketRight);
    await tester.pumpAndSettle();
    expect(h.session.pendingTurnActionsRevisions, [0, 0, 0]);
    expect(h.session.endTurnCalls, 0);
  });

  testWidgets('movement and view shortcuts ignore key repeats and modifiers', (
    tester,
  ) async {
    final h = await _Harness.mount(tester);
    h.controller.selectUnit('preview-commander');
    await tester.pumpAndSettle();
    final before = h.ready.interaction.moveTargeting;
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyM);
    await tester.pumpAndSettle();
    expect(h.ready.interaction.moveTargeting, !before);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyM);
    await tester.pumpAndSettle();
    expect(h.ready.interaction.moveTargeting, !before);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyM);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyR);
    await tester.pumpAndSettle();
    expect(h.ready.interaction.viewMode, MapViewMode.tile);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyR);
    await tester.pumpAndSettle();
    expect(h.ready.interaction.viewMode, MapViewMode.tile);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyR);
    for (final key in [
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.altLeft,
      LogicalKeyboardKey.metaLeft,
      LogicalKeyboardKey.shiftLeft,
    ]) {
      await tester.sendKeyDownEvent(key);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyUpEvent(key);
    }
    await tester.pumpAndSettle();
    expect(h.ready.interaction.viewMode, MapViewMode.tile);
    expect(h.session.pendingTurnActionsRevisions, isEmpty);
  });

  testWidgets('I inspects the pointer without changing the selected unit', (
    tester,
  ) async {
    final h = await _Harness.mount(tester);
    h.controller.selectUnit('preview-commander');
    await tester.pumpAndSettle();
    h.controller.hover((col: 2, row: 1));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyI);
    await tester.pumpAndSettle();
    expect(h.inspection.requests.single.coordinate, (col: 2, row: 1));
    expect(h.ready.interaction.selectedUnitId, 'preview-commander');
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyI);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyI);
    await tester.pumpAndSettle();
    expect(h.inspection.requests, hasLength(1));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(h.ready.inspection, isNull);
    expect(h.ready.interaction.selectedUnitId, 'preview-commander');
  });

  testWidgets('text fields keep shortcuts and invalidate late Space', (
    tester,
  ) async {
    final h = await _Harness.mount(tester);
    final response = Completer<PendingTurnActionsView>();
    h.session.pendingTurnActionsHandler = (_) => response.future;
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(h.session.pendingTurnActionsRevisions, [0]);
    h.textFocus.requestFocus();
    await tester.pumpAndSettle();
    for (final key in [
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.keyM,
      LogicalKeyboardKey.keyR,
      LogicalKeyboardKey.keyI,
    ]) {
      await tester.sendKeyEvent(key);
    }
    await tester.pumpAndSettle();
    expect(h.session.pendingTurnActionsRevisions, [0]);
    expect(h.inspection.requests, isEmpty);
    expect(h.ready.interaction.viewMode, MapViewMode.graphic);
    await tester.tap(find.byKey(const ValueKey('open-objectives')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    response.complete(h.work([]));
    await tester.pumpAndSettle();
    expect(h.session.endTurnCalls, 0);
  });

  testWidgets('pan stops on modifiers and when a text field takes focus', (
    tester,
  ) async {
    final h = await _Harness.mount(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyW);
    expect(h.game.keyboardPanDelta(1).y, lessThan(0));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    expect(h.game.keyboardPanDelta(1), (x: 0, y: 0));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyW);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    expect(h.game.keyboardPanDelta(1).x, greaterThan(0));
    h.textFocus.requestFocus();
    await tester.pumpAndSettle();
    expect(h.game.keyboardPanDelta(1), (x: 0, y: 0));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
  });

  testWidgets('a panel blocks shortcuts even after the map regains focus', (
    tester,
  ) async {
    final h = await _Harness.mount(tester);
    final response = Completer<PendingTurnActionsView>();
    h.session.pendingTurnActionsHandler = (_) => response.future;
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('open-objectives')));
    await tester.pumpAndSettle();
    tester
        .widget<FlameMapViewport>(find.byType(FlameMapViewport))
        .focusNode
        .requestFocus();
    await tester.pumpAndSettle();
    for (final key in [
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.keyM,
      LogicalKeyboardKey.keyI,
      LogicalKeyboardKey.keyR,
    ]) {
      await tester.sendKeyEvent(key);
    }
    await tester.pumpAndSettle();
    expect(h.session.pendingTurnActionsRevisions, [0]);
    expect(h.inspection.requests, isEmpty);
    expect(h.ready.interaction.viewMode, MapViewMode.graphic);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyW);
    expect(h.game.keyboardPanDelta(1), (x: 0, y: 0));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyW);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('close-objectives')), findsNothing);
    response.complete(h.work([]));
    await tester.pumpAndSettle();
    expect(h.session.endTurnCalls, 0);
    expect(h.ready.interaction.selected, isNull);
  });

  testWidgets('a failed pending query never falls through to ending the turn', (
    tester,
  ) async {
    final h = await _Harness.mount(tester);
    h.session.pendingTurnActionsFailure = const TurnSessionException(
      code: 'offline',
      message: 'Unavailable',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(h.session.pendingTurnActionsRevisions, [0]);
    expect(h.session.endTurnCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lifecycle interruption invalidates a late primary action', (
    tester,
  ) async {
    final h = await _Harness.mount(tester);
    final response = Completer<PendingTurnActionsView>();
    h.session.pendingTurnActionsHandler = (_) => response.future;
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    response.complete(h.work([]));
    await tester.pumpAndSettle();
    expect(h.session.pendingTurnActionsRevisions, [0]);
    expect(h.session.endTurnCalls, 0);
  });
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
      capabilities: testGameSessionCapabilities(
        session,
        hexInspection: inspection,
      ),
    );
  }
  final scene = testMapScene(cols: 7, rows: 7, units: [testVisibleUnit()]);
  late final inspection = FakeHexInspectionSession(scene: scene);
  final input = TestMapInputSource();
  final settings = ClientSettingsController(store: _SettingsStore());
  final textFocus = FocusNode();
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
    addTearDown(h.settings.dispose);
    addTearDown(h.textFocus.dispose);
    await h.settings.update(
      ClientSettings.defaults.copyWith(
        gamepad: const ClientGamepadSettings(enabled: false),
      ),
    );
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ClientSettingsScope(
        controller: h.settings,
        child: LocalizedTestApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(focusNode: h.textFocus),
                Expanded(
                  child: MapScreen(
                    controller: h.controller,
                    inputSource: h.input,
                    flameGameFactory: () => h.game,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return h;
  }
}

final class _SettingsStore implements ClientSettingsStore {
  @override
  Future<ClientSettings> load() async => ClientSettings.defaults;
  @override
  Future<void> save(ClientSettings settings) async {}
}
