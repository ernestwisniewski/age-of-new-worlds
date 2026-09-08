import 'dart:async';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/map/application/hex_inspection_session_port.dart';
import 'package:aonw_flutter/features/map/application/movement_session_port.dart';
import 'package:aonw_flutter/features/map/infrastructure/engine_game_session_context.dart';
import 'package:aonw_flutter/features/map/infrastructure/engine_game_session_operations.dart';
import 'package:aonw_flutter/features/map/infrastructure/engine_hex_inspection_gateway.dart';
import 'package:aonw_flutter/features/map/infrastructure/engine_movement_gateway.dart';
import 'package:aonw_flutter/features/map/infrastructure/recipient_projection_cache.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
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

  test('hex inspection preserves transport diagnostics and resync', () async {
    final stack = StackTrace.current;
    await expectLater(
      const EngineHexInspectionGateway().inspect(
        readContext: () => context,
        expectedRevision: 0,
        coordinate: (col: 0, row: 0),
        send: (_, _) async => throw EngineSessionTransportException(
          code: 'stale_revision',
          message: 'Resynchronized',
          diagnosticCause: cause,
          diagnosticStackTrace: stack,
          resyncedPlayer: context.player,
        ),
      ),
      throwsA(
        isA<HexInspectionSessionException>()
            .having((error) => error.code, 'code', 'stale_revision')
            .having((error) => error.diagnosticCause, 'cause', same(cause))
            .having((error) => error.diagnosticStackTrace, 'stack', same(stack))
            .having(
              (error) => error.resyncedPlayer,
              'recipient',
              same(context.player),
            ),
      ),
    );
  });

  test(
    'hex inspection rechecks the recipient after transport completes',
    () async {
      final original = context;
      final replacementPlayer = PlayerMapView.preview(
        actorPlayerId: original.actorPlayerId,
        turn: 1,
        units: [],
        pendingAction: null,
        stamp: SessionStampView(
          revision: 0,
          stateDigest: 'd' * 64,
          mapHash: original.map.contentHash,
          rulesetHash: original.player.stamp.rulesetHash,
        ),
      );
      final alternatives = [
        (
          session: _NoopEngineSession(),
          actor: original.actorPlayerId,
          generation: original.generation,
          player: original.player,
        ),
        (
          session: original.session,
          actor: 'another-player',
          generation: original.generation,
          player: original.player,
        ),
        (
          session: original.session,
          actor: original.actorPlayerId,
          generation: 2,
          player: original.player,
        ),
        (
          session: original.session,
          actor: original.actorPlayerId,
          generation: original.generation,
          player: replacementPlayer,
        ),
      ];
      for (final next in alternatives) {
        context = original;
        final reply = Completer<AonwClientResponse>();
        final request = const EngineHexInspectionGateway().inspect(
          readContext: () => context,
          expectedRevision: 0,
          coordinate: (col: 0, row: 0),
          send: (_, _) => reply.future,
        );
        final expectation = expectLater(
          request,
          throwsA(
            isA<HexInspectionSessionException>().having(
              (error) => error.code,
              'code',
              'session_superseded',
            ),
          ),
        );
        context = (
          session: next.session,
          actorPlayerId: next.actor,
          generation: next.generation,
          player: next.player,
          map: original.map,
          cache: original.cache,
        );
        reply.complete(_inspectionResponse());
        await expectation;
      }
    },
  );

  test('hex inspection rejects a response for different map facts', () async {
    await expectLater(
      const EngineHexInspectionGateway().inspect(
        readContext: () => context,
        expectedRevision: 0,
        coordinate: (col: 0, row: 0),
        send: (_, _) async => _inspectionResponse(),
      ),
      throwsA(
        isA<HexInspectionSessionException>().having(
          (error) => error.code,
          'code',
          'invalid_session_protocol',
        ),
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
  research: AonwPlayerResearchView.empty(),
  victory: AonwPlayerVictoryView.empty(),
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

AonwClientResponse _inspectionResponse() => AonwClientResponse.parse(
  File(
    '../../tests/fixtures/client_protocol/hex_inspection_response.json',
  ).readAsStringSync(),
);
