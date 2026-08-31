import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/map/application/movement_session_port.dart';
import 'package:aonw_flutter/features/map/infrastructure/engine_game_session_context.dart';
import 'package:aonw_flutter/features/map/infrastructure/engine_game_session_operations.dart';
import 'package:aonw_flutter/features/map/infrastructure/engine_movement_gateway.dart';
import 'package:aonw_flutter/features/map/infrastructure/recipient_projection_cache.dart';
import 'package:aonw_flutter/features/research/application/research_session_port.dart';
import 'package:aonw_flutter/features/research/infrastructure/engine_research_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  final cause = StateError('native request failed');
  late EngineGameSessionContext context;

  setUp(() {
    final scene = testMapScene(units: [testVisibleUnit()]);
    final snapshot = _snapshot();
    context = (
      session: _NoopEngineSession(),
      map: scene.map,
      player: scene.player,
      cache: RecipientProjectionCache.open(snapshot: snapshot, map: scene.map),
      actorPlayerId: 'preview-player',
      generation: 1,
    );
  });

  Future<AonwClientResponse> fail(
    EngineGameSessionContext context,
    AonwClientRequest request,
  ) async => throw EngineSessionTransportException(
    code: 'engine_session_request_failed',
    message: 'The engine session request could not be completed.',
    diagnosticCause: cause,
  );

  test('maps shared transport failures to the movement boundary', () async {
    await expectLater(
      const EngineMovementGateway().reachable(
        readContext: () => context,
        expectedRevision: 0,
        unitId: 'preview-commander',
        send: fail,
      ),
      throwsA(
        isA<MovementSessionException>()
            .having(
              (error) => error.code,
              'code',
              'engine_session_request_failed',
            )
            .having((error) => error.diagnosticCause, 'cause', same(cause)),
      ),
    );
  });

  test('maps shared transport failures to a non-movement boundary', () async {
    await expectLater(
      const EngineResearchGateway().options(
        readContext: () => context,
        expectedRevision: 0,
        send: fail,
      ),
      throwsA(
        isA<ResearchSessionException>()
            .having(
              (error) => error.code,
              'code',
              'engine_session_request_failed',
            )
            .having((error) => error.diagnosticCause, 'cause', same(cause)),
      ),
    );
  });
}

final class _NoopEngineSession implements AonwEngineSession {
  @override
  Future<void> close() async {}

  @override
  Future<String> requestJson(String request) => throw UnimplementedError();
}

AonwPlayerViewSnapshot _snapshot() => AonwPlayerViewSnapshot(
  stamp: AonwSessionStamp(
    revision: 0,
    stateDigest: 'b' * 64,
    mapHash: 'a' * 64,
    rulesetHash: 'c' * 64,
  ),
  turn: 1,
  turnMode: AonwTurnMode.sequential,
  participants: const [
    AonwPlayerParticipantView(
      id: 'player-1',
      name: 'Player One',
      colorValue: 0xff000000,
      country: AonwPlayerCountry.poland,
      kind: AonwPlayerKind.human,
    ),
  ],
  fog: const AonwPlayerFogView(
    enabled: false,
    discoveredHexes: [],
    visibleHexes: [],
  ),
  economy: AonwPlayerEconomyView.empty(),
  outcome: AonwGameOutcome(
    condition: AonwGameOutcomeCondition.ongoing,
    winnerPlayerId: null,
    scoreByPlayerId: const {'preview-player': 0},
  ),
  turnLifecycle: const AonwPlayerTurnLifecycle(
    ownState: AonwPlayerTurnState.active,
    ownSubmitted: false,
    requiredSubmissionCount: 1,
    submittedCount: 0,
  ),
  pendingAction: null,
  cityFoundingDraft: null,
  diplomacy: const AonwPlayerDiplomacyView(
    relations: [],
    proposals: [],
    messages: [],
    resourceTradeAgreements: [],
  ),
  units: const [],
  cities: const [],
  artifacts: const [],
  fieldImprovements: const [],
  roads: const [],
);
