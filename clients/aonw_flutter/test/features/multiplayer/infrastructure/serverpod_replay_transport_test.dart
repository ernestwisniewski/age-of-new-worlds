import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/multiplayer/infrastructure/serverpod_replay_transport.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as server;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'opens once and exposes effects only for a single forward step',
    () async {
      final calls = <int>[];
      final transport = _transport(
        frame: (position) async {
          calls.add(position);
          return _frame(position);
        },
      );
      addTearDown(transport.close);
      await transport.send(AonwClientRequest.seekReplay(position: 0));
      await transport.send(AonwClientRequest.snapshot());
      expect(calls, [0]);
      final step = await transport.send(
        AonwClientRequest.seekReplay(position: 1),
      );
      expect(step.require<AonwReplayFrameResponse>().command, isNotNull);
      final jump = await transport.send(
        AonwClientRequest.seekReplay(position: 3),
      );
      expect(jump.require<AonwReplayFrameResponse>().command, isNull);
      final repeated = await transport.send(
        AonwClientRequest.seekReplay(position: 3),
      );
      expect(repeated.require<AonwReplayFrameResponse>().command, isNull);
      expect(calls, [0, 1, 3, 3]);
    },
  );

  test('rejects foreign match recipient content and archive length', () async {
    final changes = <void Function(server.GameReplayFrame)>[
      (frame) => frame.matchId = 'foreign',
      (frame) => frame.playerId = 'foreign',
      (frame) =>
          _change(frame, (body) => body['recipientPlayerId'] = 'foreign'),
      (frame) => _change(
        frame,
        (body) => (body['snapshot'] as Map)['stamp']['mapHash'] = 'a' * 64,
      ),
      (frame) => _change(frame, (body) => body['entryCount'] = 4),
      (frame) => _change(frame, (body) => body['position'] = 2),
      (frame) => _change(frame, (body) => body['command'] = null),
    ];
    for (final change in changes) {
      final transport = _transport(
        frame: (position) async {
          final frame = _frame(position);
          if (position > 0) change(frame);
          return frame;
        },
      );
      await transport.send(AonwClientRequest.seekReplay(position: 0));
      await expectLater(
        transport.send(AonwClientRequest.seekReplay(position: 1)),
        throwsFormatException,
      );
      await transport.close();
    }
  });

  test('account change rejects cached and late frames', () async {
    var authorized = true;
    final pending = Completer<server.GameReplayFrame>();
    final transport = _transport(
      requireAuthorized: () {
        if (!authorized) throw StateError('account changed');
      },
      frame: (position) async => position == 0 ? _frame(0) : pending.future,
    );
    await transport.send(AonwClientRequest.seekReplay(position: 0));
    final request = transport.send(AonwClientRequest.seekReplay(position: 1));
    final rejected = expectLater(request, throwsStateError);
    authorized = false;
    pending.complete(_frame(1));
    await rejected;
    await expectLater(
      transport.send(AonwClientRequest.snapshot()),
      throwsStateError,
    );
    await transport.close();
  });

  test('close releases once and prevents accepting a late response', () async {
    final pending = Completer<server.GameReplayFrame>();
    var released = 0;
    final transport = _transport(
      frame: (_) => pending.future,
      release: () => released++,
    );
    final request = transport.send(AonwClientRequest.seekReplay(position: 0));
    final rejected = expectLater(request, throwsStateError);
    await transport.close();
    await transport.close();
    pending.complete(_frame(0));
    await rejected;
    expect(released, 1);
  });

  test('rejects gameplay local persistence and malformed requests', () async {
    final transport = _transport();
    addTearDown(transport.close);
    for (final request in [
      AonwClientRequest.exportReplay(),
      AonwClientRequest.endTurn(expectedRevision: 0),
      AonwClientRequest.seekReplay(position: 1),
    ]) {
      await expectLater(transport.send(request), throwsFormatException);
    }
    await expectLater(
      transport.requestJson(
        jsonEncode({
          'apiVersion': aonwClientApiVersion,
          'request': {'type': 'snapshot', 'actor': 'foreign'},
        }),
      ),
      throwsFormatException,
    );
  });

  test(
    'queries the selected historical position without changing the cursor',
    () async {
      int? capturedPosition;
      server.GamePlayerQueryRequest? captured;
      final transport = _transport(
        query: (request, position) async {
          captured = request;
          capturedPosition = position;
          return server.GamePlayerQueryOutcome(
            matchId: request.matchId,
            outcomeJson: jsonEncode({
              'status': 'failure',
              'error': {'code': 'stale_revision', 'message': 'stale'},
            }),
          );
        },
      );
      addTearDown(transport.close);
      await transport.send(AonwClientRequest.seekReplay(position: 0));
      await transport.send(AonwClientRequest.seekReplay(position: 3));
      final response = await transport.send(
        AonwClientRequest.cityPlanning(expectedRevision: 3),
      );
      expect(response.error?.code, 'stale_revision');
      expect(capturedPosition, 3);
      expect(captured!.matchId, 'match-1');
      expect(jsonDecode(captured!.queryJson), {
        'type': 'cityPlanning',
        'expectedRevision': 3,
      });
    },
  );

  test('concurrent requests cannot race the retained cursor', () async {
    final pending = Completer<server.GameReplayFrame>();
    final transport = _transport(frame: (_) => pending.future);
    final first = transport.send(AonwClientRequest.seekReplay(position: 0));
    await expectLater(
      transport.send(AonwClientRequest.seekReplay(position: 0)),
      throwsStateError,
    );
    pending.complete(_frame(0));
    await first;
    await transport.close();
  });
}

ServerpodReplayTransport _transport({
  ServerpodReplayFrameRead? frame,
  ServerpodReplayQueryRead? query,
  void Function()? requireAuthorized,
  void Function()? release,
}) {
  final body = _body();
  final stamp = (body['snapshot'] as Map)['stamp'] as Map;
  return ServerpodReplayTransport(
    matchId: 'match-1',
    playerId: 'human',
    mapHash: stamp['mapHash'] as String,
    rulesetHash: stamp['rulesetHash'] as String,
    frame: frame ?? (position) async => _frame(position),
    query: query ?? (_, _) => throw UnimplementedError(),
    requireAuthorized: requireAuthorized ?? () {},
    release: release ?? () {},
  );
}

Map<String, Object?> _body() {
  final value =
      jsonDecode(
            File(
              '../../engine/fixtures/client_protocol/observed_replay_frame_response.json',
            ).readAsStringSync(),
          )
          as Map;
  return (value['outcome'] as Map)['response'] as Map<String, Object?>;
}

server.GameReplayFrame _frame(int position) {
  final body = _body();
  body['position'] = position;
  final snapshot = body['snapshot'] as Map;
  snapshot['stamp']['revision'] = position;
  if (position == 0) {
    body['command'] = null;
  } else {
    final command = body['command'] as Map;
    command['stamp']['revision'] = position;
    command['viewPatch']['fromRevision'] = position - 1;
    command['viewPatch']['toRevision'] = position;
  }
  return server.GameReplayFrame(
    matchId: 'match-1',
    playerId: 'human',
    frameJson: jsonEncode(body),
  );
}

void _change(
  server.GameReplayFrame frame,
  void Function(Map<String, Object?>) update,
) {
  final body = jsonDecode(frame.frameJson) as Map<String, Object?>;
  update(body);
  frame.frameJson = jsonEncode(body);
}
