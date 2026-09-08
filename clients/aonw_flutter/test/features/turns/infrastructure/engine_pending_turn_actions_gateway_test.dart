import 'dart:async';
import 'dart:convert';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/map/infrastructure/engine_game_session_context.dart';
import 'package:aonw_flutter/features/map/infrastructure/engine_game_session_operations.dart';
import 'package:aonw_flutter/features/map/infrastructure/recipient_projection_cache.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/turns/application/turn_session_port.dart';
import 'package:aonw_flutter/features/turns/infrastructure/engine_pending_turn_actions_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  const gateway = EnginePendingTurnActionsGateway();
  test('sends only revision and returns the current recipient work', () async {
    final context = _context();
    final result = await gateway.query(
      readContext: () => context,
      expectedRevision: 0,
      send: (received, request) async {
        expect(received, same(context));
        expect(jsonDecode(request.toJson()), {
          'apiVersion': aonwClientApiVersion,
          'request': {
            'type': 'query',
            'query': {'type': 'pendingTurnActions', 'expectedRevision': 0},
          },
        });
        return _response();
      },
    );
    expect(result.actorPlayerId, context.actorPlayerId);
    expect(result.actions.length, 1);
  });

  test('preserves typed transport diagnostics and resync', () async {
    final context = _context();
    final cause = StateError('transport failure');
    final stack = StackTrace.current;
    await expectLater(
      gateway.query(
        readContext: () => context,
        expectedRevision: 0,
        send: (_, _) async => throw EngineSessionTransportException(
          code: 'stale_revision',
          message: 'stale',
          diagnosticCause: cause,
          diagnosticStackTrace: stack,
          resyncedPlayer: context.player,
        ),
      ),
      throwsA(
        isA<TurnSessionException>()
            .having((error) => error.code, 'code', 'stale_revision')
            .having((error) => error.diagnosticCause, 'cause', same(cause))
            .having((error) => error.diagnosticStackTrace, 'stack', same(stack))
            .having(
              (error) => error.resyncedPlayer,
              'resync',
              same(context.player),
            ),
      ),
    );
  });

  for (final field in [
    'session',
    'generation',
    'actor',
    'recipient',
    'mapId',
    'mapHash',
    'revision',
    'stateDigest',
    'stampMapHash',
    'rulesetHash',
  ]) {
    test('rejects a reply after replacing $field', () async {
      var context = _context();
      final response = Completer<AonwClientResponse>();
      final pending = gateway.query(
        readContext: () => context,
        expectedRevision: 0,
        send: (_, _) => response.future,
      );
      final assertion = expectLater(
        pending,
        throwsA(
          isA<TurnSessionException>().having(
            (error) => error.code,
            'code',
            'session_superseded',
          ),
        ),
      );
      context = _changed(context, field);
      response.complete(_response());
      await assertion;
    });
  }

  test('rejects an inconsistent initial recipient before transport', () async {
    final context = _changed(_context(), 'recipient');
    await expectLater(
      gateway.query(
        readContext: () => context,
        expectedRevision: 0,
        send: (_, _) async {
          fail('No request may escape an inconsistent recipient.');
        },
      ),
      throwsA(
        isA<TurnSessionException>().having(
          (error) => error.code,
          'code',
          'invalid_session_protocol',
        ),
      ),
    );
  });

  test(
    'rejects a wrong response type or stale stamp as protocol errors',
    () async {
      final context = _context();
      for (final response in [
        _response(revision: 1),
        AonwClientResponse.parse(
          jsonEncode({
            'apiVersion': aonwClientApiVersion,
            'outcome': {
              'status': 'success',
              'response': {'type': 'sessionClosed'},
            },
          }),
        ),
      ]) {
        await expectLater(
          gateway.query(
            readContext: () => context,
            expectedRevision: 0,
            send: (_, _) async => response,
          ),
          throwsA(
            isA<TurnSessionException>().having(
              (error) => error.code,
              'code',
              'invalid_session_protocol',
            ),
          ),
        );
      }
    },
  );
}

EngineGameSessionContext _context() {
  final scene = testMapScene();
  return (
    session: _NoopEngineSession(),
    generation: 1,
    map: scene.map,
    player: scene.player,
    actorPlayerId: scene.player.actorPlayerId,
    cache: RecipientProjectionCache.open(snapshot: _snapshot(), map: scene.map),
  );
}

EngineGameSessionContext _changed(
  EngineGameSessionContext context,
  String field,
) {
  final before = context.player.stamp;
  final player = PlayerMapView.preview(
    actorPlayerId: field == 'recipient' ? 'other' : context.actorPlayerId,
    turn: 1,
    units: [],
    pendingAction: null,
    stamp: SessionStampView(
      revision: field == 'revision' ? 1 : before.revision,
      stateDigest: field == 'stateDigest' ? 'd' * 64 : before.stateDigest,
      mapHash: field == 'stampMapHash' ? 'd' * 64 : before.mapHash,
      rulesetHash: field == 'rulesetHash' ? 'd' * 64 : before.rulesetHash,
    ),
  );
  return (
    session: field == 'session' ? _NoopEngineSession() : context.session,
    generation: field == 'generation' ? 2 : context.generation,
    actorPlayerId: field == 'actor' ? 'other' : context.actorPlayerId,
    map: testMapScene(
      mapId: field == 'mapId' ? 'changed' : context.map.mapId,
      contentHash: field == 'mapHash' ? 'd' * 64 : context.map.contentHash,
    ).map,
    player: player,
    cache: context.cache,
  );
}

AonwClientResponse _response({int revision = 0}) => AonwClientResponse.parse(
  jsonEncode({
    'apiVersion': aonwClientApiVersion,
    'outcome': {
      'status': 'success',
      'response': {
        'type': 'query',
        'result': {
          'type': 'pendingTurnActions',
          'stamp': {
            'revision': revision,
            'stateDigest': 'b' * 64,
            'mapHash': 'a' * 64,
            'rulesetHash': 'c' * 64,
          },
          'canActivate': true,
          'actions': [
            {'type': 'research'},
          ],
        },
      },
    },
  }),
);

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
      id: 'preview-player',
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
