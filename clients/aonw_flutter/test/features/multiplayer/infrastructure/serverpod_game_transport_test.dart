import 'dart:convert';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/multiplayer/application/multiplayer_session_port.dart';
import 'package:aonw_flutter/features/multiplayer/infrastructure/serverpod_game_transport.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as server;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('forwards the exact closed player query and maps its failure', () async {
    server.GamePlayerQueryRequest? captured;
    final transport = ServerpodGameTransport(
      matchId: 'match-1',
      resync: (_) => throw UnimplementedError(),
      query: (request) async {
        captured = request;
        return server.GamePlayerQueryOutcome(
          matchId: request.matchId,
          outcomeJson: jsonEncode({
            'status': 'failure',
            'error': {'code': 'stale_revision', 'message': 'stale'},
          }),
        );
      },
      command: (_) => throw UnimplementedError(),
      reconnect: () => throw UnimplementedError(),
      commandIdFactory: () => 'command-1',
    );
    addTearDown(transport.close);

    final response = await transport.send(
      AonwClientRequest.reachable(expectedRevision: 7, unitId: 'unit-1'),
    );

    expect(response.error?.code, 'stale_revision');
    expect(captured?.matchId, 'match-1');
    expect(jsonDecode(captured!.queryJson), {
      'type': 'reachable',
      'expectedRevision': 7,
      'unitId': 'unit-1',
    });
  });

  test('adds one idempotency identity to the exact player command', () async {
    server.GamePlayerCommandRequest? captured;
    final failure = StateError('stop after capture');
    final transport = ServerpodGameTransport(
      matchId: 'match-1',
      resync: (_) => throw UnimplementedError(),
      query: (_) => throw UnimplementedError(),
      command: (request) async {
        captured = request;
        throw failure;
      },
      reconnect: () => throw UnimplementedError(),
      commandIdFactory: () => 'command-1',
    );
    addTearDown(transport.close);

    await expectLater(
      transport.send(AonwClientRequest.endTurn(expectedRevision: 7)),
      throwsA(same(failure)),
    );

    expect(captured?.matchId, 'match-1');
    expect(captured?.clientCommandId, 'command-1');
    expect(jsonDecode(captured!.commandJson), {
      'type': 'endTurn',
      'expectedRevision': 7,
    });
  });

  test('rejects local-only requests and requests after close', () async {
    final transport = ServerpodGameTransport(
      matchId: 'match-1',
      resync: (_) => throw UnimplementedError(),
      query: (_) => throw UnimplementedError(),
      command: (_) => throw UnimplementedError(),
      reconnect: () => throw UnimplementedError(),
      commandIdFactory: () => 'command-1',
    );

    await expectLater(
      transport.send(AonwClientRequest.capabilities()),
      throwsFormatException,
    );
    await transport.close();
    await expectLater(
      transport.send(AonwClientRequest.snapshot()),
      throwsStateError,
    );
  });

  test('retries an interrupted command with the same identity', () async {
    final commandIds = <String>[];
    var reconnectCalls = 0;
    final retryFailure = StateError('retry reached');
    final transport = ServerpodGameTransport(
      matchId: 'match-1',
      resync: (_) => throw UnimplementedError(),
      query: (_) => throw UnimplementedError(),
      command: (request) async {
        commandIds.add(request.clientCommandId);
        if (commandIds.length == 1) {
          throw const MultiplayerSessionException(
            code: 'connection_interrupted',
            message: 'Connection interrupted.',
            retryable: true,
          );
        }
        throw retryFailure;
      },
      reconnect: () async => reconnectCalls += 1,
      commandIdFactory: () => 'command-1',
    );
    addTearDown(transport.close);

    await expectLater(
      transport.send(AonwClientRequest.endTurn(expectedRevision: 7)),
      throwsA(same(retryFailure)),
    );

    expect(reconnectCalls, 1);
    expect(commandIds, ['command-1', 'command-1']);
  });
}
