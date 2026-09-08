import 'dart:convert';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/app/navigation/aonw_app.dart';
import 'package:aonw_flutter/app/navigation/aonw_router.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/infrastructure/engine_game_session_gateway.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/flame_map_viewport.dart';
import 'package:aonw_flutter/features/research/read_model/research_view.dart';
import 'package:aonw_flutter/features/settings/application/client_settings.dart';
import 'package:aonw_flutter/features/settings/application/client_settings_store.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_manager/window_manager.dart';

final class NativeTurnAutomationProbe {
  NativeTurnAutomationProbe(this.tester) {
    gateway = EngineGameSessionGateway(
      assets: rootBundle,
      sessionFactory: () async {
        final native = await createAonwEngineSession();
        expect(native, isNotNull);
        return _RecordedSession(native!, requests);
      },
    );
    controller = MapPresentationController(capabilities: gateway.capabilities);
  }

  final WidgetTester tester;
  final requests = <Map<String, Object?>>[];
  final settings = ClientSettingsController(store: _SettingsStore());
  late final EngineGameSessionGateway gateway;
  late final MapPresentationController controller;
  Size? _windowSize;
  String? technology;
  GameSessionReady get ready => controller.state as GameSessionReady;

  Future<void> start(
    LocalTurnModeView mode, {
    LocalPlayerControlView opponent = LocalPlayerControlView.ai,
  }) async {
    expect(aonwEngineClientAvailable, isTrue);
    await windowManager.ensureInitialized();
    _windowSize = await windowManager.getSize();
    await windowManager.setSize(const Size(1280, 900));
    await windowManager.show();
    await windowManager.focus();
    await tester.pumpWidget(
      AonwApp(
        mapController: controller,
        settingsController: settings,
        locale: const Locale('en'),
      ),
    );
    await until(() => settings.isLoaded, 'settings loaded');
    final entry = LocalGameCatalog.entries.first;
    expect(
      await controller.startLocalMatch(entry, _setup(mode, opponent)),
      isTrue,
    );
    Navigator.of(
      tester.element(find.byKey(const ValueKey('single-player'))),
    ).pushNamed(AonwRoute.map.location);
    await until(
      () => ready.interaction.selectedUnitId == 'player-1-commander',
      'automatic unit focus',
    );
    expect(ready.recipient.actorPlayerId, 'player-1');
    expect(ready.recipient.turnView.number, 1);
    expect(ready.recipient.turnMode.name, mode.name);
    expect(count('endTurn'), 0);
    await idle();
  }

  Future<void> skipAndDismissResearch() async {
    await tap(const ValueKey(('unit-action', 'skip')));
    await until(
      () => ready.interaction.researchFocused,
      'research focus after unit skip',
    );
    expect(count('skipUnitTurn'), 1);
    expect(count('endTurn'), 0);
    await tap(const ValueKey('close-research'));
    await until(() => !ready.interaction.researchFocused, 'research dismissal');
    await idle();
    expect(find.byKey(const ValueKey('close-research')), findsNothing);
    expect(count('selectTechnology'), 0);
    expect(count('endTurn'), 0);
  }

  Future<void> selectResearchAndEndTurn() async {
    await selectResearch();
    await enableAutomaticEnds();
    await nextHumanTurn(2);
    expect(count('endTurn'), 1);
    expect(count('advanceAiTurn'), 1);
    expect(count('selectTechnology'), 1);
    await idle();
  }

  Future<void> selectResearch() async {
    if (find.byKey(const ValueKey('close-research')).evaluate().isEmpty) {
      await tap(const ValueKey('open-research'));
    }
    await until(
      () => ready.research.options != null && !ready.research.loading,
      'research options',
    );
    technology = ready.research.options!.options
        .firstWhere(
          (option) =>
              option.availability == TechnologyAvailabilityView.available,
        )
        .technology
        .name;
    await tester.scrollUntilVisible(
      find.byKey(ValueKey(('select-technology', technology!))),
      300,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('research-options')),
        matching: find.byType(Scrollable),
      ),
    );
    await tap(ValueKey(('select-technology', technology!)));
    await until(
      () => ready.recipient.research.activeTechnologyId == technology,
      'native research selection',
    );
    if (find.byKey(const ValueKey('close-research')).evaluate().isNotEmpty) {
      await tap(const ValueKey('close-research'));
    }
  }

  Future<void> enableAutomaticEnds() => settings.update(
    settings.settings.copyWith(
      automation: const ClientAutomationSettings(endTurn: true),
    ),
  );

  Future<void> skipNextTurn() async {
    await tap(const ValueKey(('unit-action', 'skip')));
    await nextHumanTurn(3);
    expect(count('skipUnitTurn'), 2);
    expect(count('endTurn'), 2);
    expect(count('advanceAiTurn'), 2);
    await idle();
  }

  Future<void> nextHumanTurn(int turn) => until(
    () =>
        ready.recipient.turnView.number == turn &&
        !ready.turnAction.inFlight &&
        !ready.localAiTurn.blocksGameplay &&
        ready.interaction.selectedUnitId == 'player-1-commander',
    'human turn $turn after automatic ending and AI',
  );

  Future<void> tap(Key key) async {
    final target = find.byKey(key);
    await until(() => target.evaluate().isNotEmpty, 'visible $key');
    await tester.ensureVisible(target);
    await tester.pump();
    await tester.tap(target);
    await tester.pump();
  }

  Future<void> until(bool Function() complete, String stage) async {
    final timer = Stopwatch()..start();
    do {
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull, reason: stage);
      if (controller.state case GameSessionReady(
        :final turnAction,
        :final localAiTurn,
      )) {
        expect(turnAction.failure, isNull, reason: stage);
        expect(localAiTurn.failure, isNull, reason: stage);
      }
      if (timer.elapsed > const Duration(seconds: 45)) {
        fail('$stage timed out; state: ${_diagnostics()}; requests: $requests');
      }
    } while (!complete());
  }

  Map<String, Object?> _diagnostics() {
    final viewport = find.byType(FlameMapViewport);
    final game = viewport.evaluate().isEmpty
        ? null
        : tester.widget<FlameMapViewport>(viewport).game;
    return {
      'lifecycle': tester.binding.lifecycleState?.name,
      'viewportActive': game?.debugViewportActive,
      'paused': game?.paused,
      'effects': game?.hasActiveUnitEffects,
      if (controller.state case final GameSessionReady state) ...{
        'actor': state.recipient.actorPlayerId,
        'turn': state.recipient.turnView.number,
        'revision': state.recipient.stamp.revision,
        'selectedUnit': state.interaction.selectedUnitId,
        'turnCommand': state.turnAction.inFlight,
        'ai': state.localAiTurn.phase.name,
        'handoff': state.localHandoff.phase.name,
      },
    };
  }

  Future<void> idle() async {
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final before = requests.length;
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      requests.length,
      before,
      reason: 'idle map must not poll or repeat commands',
    );
  }

  int count(String type) =>
      requests.where((request) => request['type'] == type).length;

  Map<String, Object?> report(LocalTurnModeView mode) => {
    'turnMode': mode.name,
    'finalTurn': ready.recipient.turnView.number,
    'finalRevision': ready.recipient.stamp.revision,
    'technology': technology,
    'unitSkips': count('skipUnitTurn'),
    'automaticEnds': count('endTurn'),
    'aiTurns': count('advanceAiTurn'),
    'requests': requests,
  };

  Future<void> close() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await gateway.close();
    if (_windowSize case final original?) await windowManager.setSize(original);
  }
}

final class _RecordedSession implements AonwEngineSession {
  _RecordedSession(this.delegate, this.requests);
  final AonwEngineSession delegate;
  final List<Map<String, Object?>> requests;

  @override
  Future<String> requestJson(String request) {
    final envelope = jsonDecode(request) as Map<String, dynamic>;
    final body = envelope['request'] as Map<String, dynamic>;
    final action =
        (body['command'] ?? body['query'] ?? body) as Map<String, dynamic>;
    requests.add({
      'type': action['type'],
      if (action.containsKey('expectedRevision'))
        'revision': action['expectedRevision'],
    });
    return delegate.requestJson(request);
  }

  @override
  Future<void> close() => delegate.close();
}

final class _SettingsStore implements ClientSettingsStore {
  ClientSettings value = ClientSettings.defaults.copyWith(
    gamepad: const ClientGamepadSettings(enabled: false),
  );
  @override
  Future<ClientSettings> load() async => value;
  @override
  Future<void> save(ClientSettings settings) async => value = settings;
}

LocalMatchSetupView _setup(
  LocalTurnModeView mode,
  LocalPlayerControlView opponent,
) => LocalMatchSetupView(
  assets: LocalGameCatalog.entries.first.assets,
  fogEnabled: opponent == LocalPlayerControlView.human,
  turnMode: mode,
  participants: [
    LocalParticipantSetupView(
      id: 'player-1',
      name: 'Player',
      colorValue: 0xff3d5a80,
      country: LocalPlayerCountryView.poland,
      control: LocalPlayerControlView.human,
    ),
    LocalParticipantSetupView(
      id: 'player-2',
      name: 'Player 2',
      colorValue: 0xffee6c4d,
      country: LocalPlayerCountryView.japan,
      control: opponent,
      ai: opponent == LocalPlayerControlView.ai
          ? const LocalAiProfileView(seed: 42)
          : null,
    ),
  ],
);
