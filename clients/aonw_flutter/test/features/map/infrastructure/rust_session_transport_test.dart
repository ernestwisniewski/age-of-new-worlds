import 'package:aonw_flutter/features/map/application/movement_session_port.dart';
import 'package:aonw_flutter/features/map/infrastructure/recipient_projection_cache.dart';
import 'package:aonw_flutter/features/map/infrastructure/rust_game_session_context.dart';
import 'package:aonw_flutter/features/map/infrastructure/rust_game_session_operations.dart';
import 'package:aonw_flutter/features/map/infrastructure/rust_movement_gateway.dart';
import 'package:aonw_flutter/features/research/application/research_session_port.dart';
import 'package:aonw_flutter/features/research/infrastructure/rust_research_gateway.dart';
import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  final cause = StateError('native request failed');
  late RustGameSessionContext context;

  setUp(() {
    final scene = testMapScene(units: [testVisibleUnit()]);
    final snapshot = _snapshot();
    context = (
      session: _NoopRustSession(),
      map: scene.map,
      player: scene.player,
      cache: RecipientProjectionCache.open(snapshot: snapshot, map: scene.map),
      actorPlayerId: 'preview-player',
    );
  });

  Future<AonwClientResponse> fail(
    AonwRustSession session,
    AonwClientRequest request,
  ) async => throw RustSessionTransportException(
    code: 'rust_session_request_failed',
    message: 'The Rust session request could not be completed.',
    diagnosticCause: cause,
  );

  test('maps shared transport failures to the movement boundary', () async {
    await expectLater(
      const RustMovementGateway().reachable(
        context: context,
        expectedRevision: 0,
        unitId: 'preview-commander',
        send: fail,
      ),
      throwsA(
        isA<MovementSessionException>()
            .having(
              (error) => error.code,
              'code',
              'rust_session_request_failed',
            )
            .having((error) => error.diagnosticCause, 'cause', same(cause)),
      ),
    );
  });

  test('maps shared transport failures to a non-movement boundary', () async {
    await expectLater(
      const RustResearchGateway().options(
        context: context,
        expectedRevision: 0,
        send: fail,
      ),
      throwsA(
        isA<ResearchSessionException>()
            .having(
              (error) => error.code,
              'code',
              'rust_session_request_failed',
            )
            .having((error) => error.diagnosticCause, 'cause', same(cause)),
      ),
    );
  });
}

final class _NoopRustSession implements AonwRustSession {
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
