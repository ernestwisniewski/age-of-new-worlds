import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/app/composition/app_composition.dart';
import 'package:aonw_flutter/app/navigation/aonw_router.dart';
import 'package:aonw_flutter/app/telemetry/client_telemetry.dart';
import 'package:aonw_flutter/features/artifacts/application/artifact_session_port.dart';
import 'package:aonw_flutter/features/artifacts/read_model/artifact_view.dart';
import 'package:aonw_flutter/features/cities/application/city_session_port.dart';
import 'package:aonw_flutter/features/cities/read_model/city_view.dart';
import 'package:aonw_flutter/features/combat/application/combat_session_port.dart';
import 'package:aonw_flutter/features/combat/read_model/combat_view.dart';
import 'package:aonw_flutter/features/diplomacy/application/diplomacy_session_port.dart';
import 'package:aonw_flutter/features/diplomacy/read_model/diplomacy_view.dart';
import 'package:aonw_flutter/features/logistics/application/unit_logistics_session_port.dart';
import 'package:aonw_flutter/features/logistics/read_model/unit_logistics_view.dart';
import 'package:aonw_flutter/features/map/application/game_session_capabilities.dart';
import 'package:aonw_flutter/features/map/application/map_session_port.dart';
import 'package:aonw_flutter/features/map/application/movement_session_port.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_input.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/movement_view.dart';
import 'package:aonw_flutter/features/production/application/production_session_port.dart';
import 'package:aonw_flutter/features/production/read_model/production_view.dart';
import 'package:aonw_flutter/features/research/application/research_session_port.dart';
import 'package:aonw_flutter/features/research/read_model/research_view.dart';
import 'package:aonw_flutter/features/turns/application/turn_session_port.dart';
import 'package:aonw_flutter/features/turns/read_model/turn_command_view.dart';
import 'package:aonw_flutter/features/unit_actions/application/unit_action_session_port.dart';
import 'package:aonw_flutter/features/unit_actions/read_model/unit_action_view.dart';
import 'package:aonw_flutter/features/workers/application/worker_session_port.dart';
import 'package:aonw_flutter/features/workers/read_model/worker_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/map_test_fixture.dart';

void main() {
  final lifecycle = _lifecycleOracle();

  testWidgets('composition owns one controller and closes its session', (
    tester,
  ) async {
    final first = _LifecycleGameSession();
    final second = _LifecycleGameSession();
    final firstInput = _LifecycleMapInputSource();
    final secondInput = _LifecycleMapInputSource();

    await tester.pumpWidget(
      AppComposition(
        capabilities: _capabilities(first),
        mapInputSource: firstInput,
        initialRoute: AonwRoute.map,
      ).root,
    );
    await tester.pump();
    expect(first.loadCalls, 1);
    expect(first.closeCalls, 0);
    expect(firstInput.closeCalls, 0);

    await tester.pumpWidget(
      AppComposition(
        capabilities: _capabilities(second),
        mapInputSource: secondInput,
        initialRoute: AonwRoute.map,
      ).root,
    );
    await tester.pump();
    final expected = lifecycle['routeReplace'] as Map<String, dynamic>;
    expect(first.closeCalls, expected['oldRepositoryCloseCalls']);
    expect(firstInput.closeCalls, expected['oldInputCloseCalls']);
    expect(second.loadCalls, expected['newRepositoryLoadCalls']);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(second.closeCalls, 1);
    expect(secondInput.closeCalls, 1);
  });

  testWidgets('application lifecycle pauses and resumes gamepad input', (
    tester,
  ) async {
    final session = _LifecycleGameSession();
    final input = _LifecycleMapInputSource();
    final telemetry = _RecordingClientTelemetry();
    final games = <AonwFlameGame>[];
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    await tester.pumpWidget(
      AppComposition(
        capabilities: _capabilities(session),
        mapInputSource: input,
        flameGameFactory: () {
          final game = AonwFlameGame();
          games.add(game);
          return game;
        },
        telemetry: telemetry,
        initialRoute: AonwRoute.map,
      ).root,
    );
    await tester.pump();
    expect(input.activeStates, [true]);
    expect(telemetry.events, [ClientTelemetryEvent.appStarted]);
    expect(games.single.debugViewportActive, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(input.activeStates.last, isFalse);
    expect(session.closeCalls, 0);
    expect(telemetry.events.last, ClientTelemetryEvent.appSuspended);
    expect(games.single.debugViewportActive, isFalse);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(input.activeStates.last, isTrue);
    final expected = lifecycle['pauseResume'] as Map<String, dynamic>;
    expect(session.closeCalls, expected['repositoryCloseCallsBeforeUnmount']);
    expect(input.activeStates, expected['inputActiveStates']);
    expect(telemetry.events.map((event) => event.code), expected['telemetry']);
    expect(games.single.debugViewportActive, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(input.activeStates.last, isFalse);
    expect(session.closeCalls, 1);
    expect(games.single.debugDisposed, isTrue);
  });

  testWidgets('route replacement never duplicates game session or input', (
    tester,
  ) async {
    final games = <AonwFlameGame>[];
    final firstSession = _LifecycleGameSession();
    final secondSession = _LifecycleGameSession();
    final firstInput = _LifecycleMapInputSource();
    final secondInput = _LifecycleMapInputSource();

    AonwFlameGame createGame() {
      final game = AonwFlameGame();
      games.add(game);
      return game;
    }

    await tester.pumpWidget(
      AppComposition(
        capabilities: _capabilities(firstSession),
        mapInputSource: firstInput,
        flameGameFactory: createGame,
        initialRoute: AonwRoute.map,
      ).root,
    );
    await tester.pumpAndSettle();

    expect(games, hasLength(1));
    expect(games.single.debugMountCount, 1);
    expect(games.single.debugViewportActive, isTrue);
    expect(firstSession.loadCalls, 1);
    expect(firstInput.listenCalls, 1);

    await tester.tap(find.byKey(const ValueKey('open-settings')));
    await tester.pumpAndSettle();
    expect(games.single.debugViewportActive, isFalse);
    expect(firstSession.closeCalls, 0);
    expect(firstInput.listenCalls, 1);
    expect(firstInput.cancelCalls, 0);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(games.single.debugViewportActive, isTrue);
    expect(firstInput.listenCalls, 1);

    await tester.pumpWidget(
      AppComposition(
        capabilities: _capabilities(secondSession),
        mapInputSource: secondInput,
        flameGameFactory: createGame,
        initialRoute: AonwRoute.map,
      ).root,
    );
    await tester.pumpAndSettle();

    expect(games, hasLength(2));
    expect(games.first.debugDisposed, isTrue);
    expect(firstSession.closeCalls, 1);
    expect(firstInput.listenCalls, 1);
    expect(firstInput.cancelCalls, 1);
    expect(firstInput.closeCalls, 1);
    expect(secondSession.loadCalls, 1);
    expect(secondInput.listenCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(games.last.debugDisposed, isTrue);
    expect(secondSession.closeCalls, 1);
    expect(secondInput.cancelCalls, 1);
    expect(secondInput.closeCalls, 1);
  });
}

Map<String, dynamic> _lifecycleOracle() {
  for (final path in ['test/fixtures/input/viewport_oracle.json']) {
    final file = File(path);
    if (file.existsSync()) {
      final value = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      return value['lifecycle'] as Map<String, dynamic>;
    }
  }
  throw StateError('Flutter viewport oracle fixture not found.');
}

final class _RecordingClientTelemetry implements ClientTelemetry {
  final events = <ClientTelemetryEvent>[];

  @override
  void record(ClientTelemetryEvent event) => events.add(event);
}

GameSessionCapabilities _capabilities(_LifecycleGameSession session) =>
    GameSessionCapabilities(
      map: session,
      movement: session,
      combat: session,
      cities: session,
      logistics: session,
      workers: session,
      production: session,
      artifacts: session,
      research: session,
      diplomacy: session,
      unitActions: session,
      turns: session,
    );

final class _LifecycleMapInputSource
    implements MapInputSource, LifecycleAwareMapInputSource {
  _LifecycleMapInputSource() {
    _commands = StreamController<MapInputCommand>.broadcast(
      onListen: () => listenCalls += 1,
      onCancel: () => cancelCalls += 1,
    );
  }

  var closeCalls = 0;
  var listenCalls = 0;
  var cancelCalls = 0;
  final activeStates = <bool>[];
  late final StreamController<MapInputCommand> _commands;

  @override
  Stream<MapInputCommand> get commands => _commands.stream;

  @override
  Future<void> close() async {
    closeCalls += 1;
    await _commands.close();
  }

  @override
  void setActive(bool active) => activeStates.add(active);
}

final class _LifecycleGameSession
    implements
        MapSessionPort,
        MovementSessionPort,
        CitySessionPort,
        CombatSessionPort,
        UnitLogisticsSessionPort,
        WorkerSessionPort,
        ProductionSessionPort,
        ArtifactSessionPort,
        ResearchSessionPort,
        DiplomacySessionPort,
        TurnSessionPort,
        UnitActionSessionPort {
  var loadCalls = 0;
  var closeCalls = 0;

  @override
  Future<MapScene> load(MapAssetPaths assets) async {
    loadCalls += 1;
    return testMapScene();
  }

  @override
  Future<ReachableView> reachable({
    required int expectedRevision,
    required String unitId,
  }) => throw UnimplementedError();

  @override
  Future<RoutePlanView> routePlan({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  }) => throw UnimplementedError();

  @override
  Future<MoveUnitResultView> moveUnit({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  }) => throw UnimplementedError();

  @override
  Future<CombatPreviewView> combatPreview({
    required int expectedRevision,
    required String attackerUnitId,
    required MapHexCoordinate defender,
  }) => throw UnimplementedError();

  @override
  Future<CombatCommandResultView> attack({
    required int expectedRevision,
    required CombatAttackView attack,
  }) => throw UnimplementedError();

  @override
  Future<CityFoundingOptionsView> cityFoundingOptions({
    required int expectedRevision,
    required String founderUnitId,
  }) => throw UnimplementedError();

  @override
  Future<CityInspectionView> inspectCity({
    required int expectedRevision,
    required String cityId,
  }) => throw UnimplementedError();

  @override
  Future<CityCommandResultView> executeCityAction({
    required int expectedRevision,
    required CityActionView action,
  }) => throw UnimplementedError();

  @override
  Future<UnitLogisticsOptionsView> unitLogisticsOptions({
    required int expectedRevision,
    required String unitId,
  }) => throw UnimplementedError();

  @override
  Future<UnitLogisticsCommandResultView> executeUnitLogistics({
    required int expectedRevision,
    required UnitLogisticsActionView action,
  }) => throw UnimplementedError();

  @override
  Future<WorkerOptionsView> workerOptions({
    required int expectedRevision,
    required String unitId,
  }) => throw UnimplementedError();

  @override
  Future<WorkerCommandResultView> executeWorkerAction({
    required int expectedRevision,
    required WorkerActionView action,
  }) => throw UnimplementedError();

  @override
  Future<
    ({ProductionOptionsView options, StrategicResourceProjectionView resources})
  >
  productionOverview({required int expectedRevision, required String cityId}) =>
      throw UnimplementedError();

  @override
  Future<ProductionCommandResultView> executeProductionAction({
    required int expectedRevision,
    required ProductionActionView action,
  }) => throw UnimplementedError();

  @override
  Future<ArtifactCommandResultView> executeArtifactAction({
    required int expectedRevision,
    required ArtifactActionView action,
  }) => throw UnimplementedError();

  @override
  Future<ResearchOptionsView> researchOptions({
    required int expectedRevision,
  }) async => testResearchOptionsView(revision: expectedRevision);

  @override
  Future<ResearchCommandResultView> selectTechnology({
    required int expectedRevision,
    required TechnologyIdView technology,
  }) => throw UnimplementedError();

  @override
  Future<DiplomacyCommandResultView> executeDiplomacyAction({
    required int expectedRevision,
    required DiplomacyActionView action,
  }) => throw UnimplementedError();

  @override
  Future<UnitActionResultView> executeUnitAction({
    required int expectedRevision,
    required String unitId,
    required UnitActionKindView action,
  }) => throw UnimplementedError();

  @override
  Future<TurnCommandResultView> endTurn({required int expectedRevision}) =>
      throw UnimplementedError();

  @override
  Future<void> close() async {
    closeCalls += 1;
  }
}
