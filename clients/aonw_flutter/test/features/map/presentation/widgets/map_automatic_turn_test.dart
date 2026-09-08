import 'dart:async';

import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/settings/application/client_settings.dart';
import 'package:aonw_flutter/features/settings/application/client_settings_store.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_scope.dart';
import 'package:aonw_flutter/features/turns/application/turn_session_port.dart';
import 'package:aonw_flutter/features/turns/read_model/pending_turn_actions_view.dart';
import 'package:aonw_flutter/features/unit_actions/read_model/unit_action_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';
import '../../../../support/map_test_fixture.dart';

const _unit = PendingUnitTurnActionView(
  unitId: 'preview-commander',
  coordinate: (col: 0, row: 0),
);
const _research = PendingResearchTurnActionView();

void main() {
  testWidgets('automatically focuses pending work once without gamepad input', (
    tester,
  ) async {
    final h = _Harness();
    h.store.value = ClientSettings.defaults.copyWith(
      gamepad: const ClientGamepadSettings(enabled: false),
    );
    await h.mount(tester);
    expect(h.ready.interaction.selectedUnitId, 'preview-commander');
    expect(h.session.endTurnCalls, 0);
    final queries = h.session.pendingTurnActionsRevisions.length;
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(h.session.pendingTurnActionsRevisions, hasLength(queries));
    expect(h.ready.interaction.moveTargeting, isTrue);
    h.controller.cancelInteraction();
    await tester.pumpAndSettle();
    expect(h.ready.interaction.moveTargeting, isFalse);
    h.controller.cancelInteraction();
    await tester.pumpAndSettle();
    expect(h.ready.interaction.selectedUnitId, isNull);
    expect(h.session.endTurnCalls, 0);
    await tester.pump(const Duration(seconds: 10));
    expect(h.ready.interaction.selectedUnitId, isNull);
  });

  testWidgets(
    'turn-only automation ends empty work once and stops after a failure',
    (tester) async {
      final h = _Harness(actions: []);
      h.store.value = ClientSettings.defaults.copyWith(
        automation: const ClientAutomationSettings(
          advanceActions: false,
          endTurn: true,
        ),
      );
      await h.mount(tester);
      expect(h.session.endTurnCalls, 1);
      expect(h.ready.turnAction.failure, isNotNull);
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(h.session.endTurnCalls, 1);
    },
  );

  testWidgets('disabling options invalidates an in-flight automatic query', (
    tester,
  ) async {
    final h = _Harness();
    final response = Completer<PendingTurnActionsView>();
    h.session.pendingTurnActionsHandler = (_) => response.future;
    await h.mount(tester);
    expect(h.session.pendingTurnActionsRevisions, isNotEmpty);
    await h.settings.update(
      h.settings.settings.copyWith(
        automation: const ClientAutomationSettings(advanceActions: false),
      ),
    );
    response.complete(h.work([_unit]));
    await tester.pumpAndSettle();
    expect(h.ready.interaction.selectedUnitId, isNull);
    expect(h.session.endTurnCalls, 0);
  });

  testWidgets(
    'lifecycle suspension discards the late result and resumes from fresh work',
    (tester) async {
      final h = _Harness();
      final response = Completer<PendingTurnActionsView>();
      h.session.pendingTurnActionsHandler = (_) => response.future;
      await h.mount(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      response.complete(h.work([_unit]));
      await tester.pumpAndSettle();
      expect(h.ready.interaction.selectedUnitId, isNull);
      h.session.pendingTurnActionsHandler = null;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(h.ready.interaction.selectedUnitId, 'preview-commander');
    },
  );

  testWidgets(
    'closing automatic research pauses reopening until actions are enabled again',
    (tester) async {
      final h = _Harness(actions: [_research]);
      await h.mount(tester);
      expect(h.ready.interaction.researchFocused, isTrue);
      h.controller.closeTurnResearch();
      await tester.pumpAndSettle();
      expect(h.ready.interaction.researchFocused, isFalse);
      await tester.pump(const Duration(seconds: 10));
      expect(h.ready.interaction.researchFocused, isFalse);
      await h.settings.update(
        h.settings.settings.copyWith(
          automation: const ClientAutomationSettings(advanceActions: false),
        ),
      );
      await tester.pumpAndSettle();
      await h.settings.update(
        h.settings.settings.copyWith(
          automation: const ClientAutomationSettings(),
        ),
      );
      await tester.pumpAndSettle();
      expect(h.ready.interaction.researchFocused, isTrue);
    },
  );

  testWidgets('saved disabled options load before any automatic query', (
    tester,
  ) async {
    final h = _Harness();
    final loading = Completer<ClientSettings>();
    h.store.loading = loading;
    await h.mount(tester, waitForSettings: false);
    expect(h.session.pendingTurnActionsRevisions, isEmpty);
    loading.complete(
      ClientSettings.defaults.copyWith(
        automation: const ClientAutomationSettings(advanceActions: false),
      ),
    );
    await tester.pumpAndSettle();
    expect(h.settings.isLoaded, isTrue);
    expect(h.session.pendingTurnActionsRevisions, isEmpty);
    expect(h.ready.interaction.selectedUnitId, isNull);
  });

  testWidgets('completing an authoritative unit action advances to research', (
    tester,
  ) async {
    final player = PlayerMapView.preview(
      actorPlayerId: 'preview-player',
      stamp: testSessionStamp(revision: 1),
      turn: 1,
      pendingAction: null,
      units: [testVisibleUnit(movementUnits: 0)],
    );
    final h = _Harness(
      unitResult: UnitActionResultView.accepted(
        action: UnitActionKindView.skip,
        unitId: 'preview-commander',
        player: player,
      ),
    );
    h.session.pendingTurnActionsHandler = (revision) async =>
        PendingTurnActionsView(
          stamp: revision == 0 ? h.scene.player.stamp : player.stamp,
          actorPlayerId: player.actorPlayerId,
          canActivate: true,
          actions: revision == 0 ? [_unit, _research] : [_research],
        );
    await h.mount(tester);
    expect(h.ready.interaction.selectedUnitId, 'preview-commander');
    h.controller.executeUnitAction(UnitActionKindView.skip);
    await tester.pumpAndSettle();
    expect(h.session.unitActionCalls, 1);
    expect(h.ready.recipient.stamp.revision, 1);
    expect(h.ready.interaction.researchFocused, isTrue);
    expect(h.session.endTurnCalls, 0);
  });

  testWidgets(
    'opening a panel suppresses a late result and closing it resumes navigation',
    (tester) async {
      final h = _Harness();
      final response = Completer<PendingTurnActionsView>();
      h.session.pendingTurnActionsHandler = (_) => response.future;
      await h.mount(tester);
      await tester.tap(find.byKey(const ValueKey('open-objectives')));
      await tester.pumpAndSettle();
      response.complete(h.work([_unit]));
      await tester.pumpAndSettle();
      expect(h.ready.interaction.selectedUnitId, isNull);
      expect(find.byKey(const ValueKey('close-objectives')), findsOneWidget);
      h.session.pendingTurnActionsHandler = null;
      await tester.tap(find.byKey(const ValueKey('close-objectives')));
      await tester.pumpAndSettle();
      expect(h.ready.interaction.selectedUnitId, 'preview-commander');
    },
  );

  testWidgets('a covered map ignores late work and refreshes after returning', (
    tester,
  ) async {
    final h = _Harness();
    final response = Completer<PendingTurnActionsView>();
    h.session.pendingTurnActionsHandler = (_) => response.future;
    await h.mount(tester);
    final navigator = Navigator.of(tester.element(find.byType(MapScreen)));
    unawaited(
      navigator.push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(body: Text('Other route')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    response.complete(h.work([_unit]));
    await tester.pumpAndSettle();
    expect(h.ready.interaction.selectedUnitId, isNull);
    h.session.pendingTurnActionsHandler = null;
    navigator.pop();
    await tester.pumpAndSettle();
    expect(h.ready.interaction.selectedUnitId, 'preview-commander');
  });

  testWidgets(
    'a new controller advances without waiting for an old session query',
    (tester) async {
      final old = _Harness();
      final response = Completer<PendingTurnActionsView>();
      old.session.pendingTurnActionsHandler = (_) => response.future;
      await old.mount(tester);
      final current = _Harness(actions: [_research]);
      await current.mount(tester);
      expect(current.ready.interaction.researchFocused, isTrue);
      response.complete(old.work([_unit]));
      await tester.pumpAndSettle();
      expect(old.ready.interaction.selectedUnitId, isNull);
      expect(current.ready.interaction.researchFocused, isTrue);
      expect(old.session.endTurnCalls, 0);
    },
  );
}

final class _Harness {
  _Harness({
    List<PendingTurnActionView> actions = const [_unit, _research],
    UnitActionResultView? unitResult,
  }) {
    session = FakeGameSession.success(
      scene,
      reachableResult: testReachableView(),
      unitActionResult: unitResult,
      turnFailure: const TurnSessionException(
        code: 'offline',
        message: 'Unavailable',
      ),
    );
    session.pendingTurnActionsResult = work(actions);
    controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );
  }
  final scene = testMapScene(cols: 7, rows: 7, units: [testVisibleUnit()]);
  final store = _Store();
  late final settings = ClientSettingsController(store: store);
  final game = AonwFlameGame();
  final routes = RouteObserver<ModalRoute<void>>();
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

  Future<void> mount(WidgetTester tester, {bool waitForSettings = true}) async {
    addTearDown(controller.dispose);
    addTearDown(settings.dispose);
    final loading = settings.load();
    if (waitForSettings) await loading;
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ClientSettingsScope(
        controller: settings,
        child: LocalizedTestApp(
          navigatorObservers: [routes],
          home: MapScreen(
            routeObserver: routes,
            controller: controller,
            flameGameFactory: () => game,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

final class _Store implements ClientSettingsStore {
  ClientSettings value = ClientSettings.defaults;
  Completer<ClientSettings>? loading;
  @override
  Future<ClientSettings> load() async =>
      loading == null ? value : loading!.future;
  @override
  Future<void> save(ClientSettings settings) async {
    value = settings;
  }
}
