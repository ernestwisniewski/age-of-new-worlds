import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:aonw_flutter/features/map/infrastructure/engine_game_session_gateway.dart';
import 'package:aonw_flutter/features/replay/application/replay_session_port.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final field in ['actor', 'recipient', 'stamp']) {
    test('rejects AI $field mismatch after restoring the human view', () async {
      final fixture = _Fixture();
      addTearDown(fixture.gateway.close);
      await fixture.startAndEndHumanTurn();
      String? expectedDigest;
      fixture.mutate = (request, body) {
        if (request != 'advanceAiTurn') return;
        expectedDigest =
            (body['stamp'] as Map<String, dynamic>)['stateDigest'] as String;
        switch (field) {
          case 'actor':
            body['actorPlayerId'] = 'player-1';
          case 'recipient':
            body['recipientPlayerId'] = 'player-2';
          case 'stamp':
            (body['stamp'] as Map<String, dynamic>)['stateDigest'] = 'a' * 64;
            for (final command in body['commands'] as List<dynamic>) {
              ((command as Map<String, dynamic>)['stamp']
                      as Map<String, dynamic>)['stateDigest'] =
                  'a' * 64;
            }
        }
      };
      await expectLater(
        fixture.advanceAi(),
        throwsA(
          isA<LocalGameSessionException>()
              .having((error) => error.code, 'code', 'invalid_ai_turn_protocol')
              .having(
                (error) => error.resyncedPlayer?.actorPlayerId,
                'recipient',
                'player-1',
              )
              .having(
                (error) => error.resyncedPlayer?.stamp.stateDigest,
                'restored digest',
                predicate<String?>(
                  (value) => expectedDigest != null && value == expectedDigest,
                ),
              ),
        ),
      );
      expect(fixture.requests.skip(fixture.requests.indexOf('advanceAiTurn')), [
        'advanceAiTurn',
        'handoffActor',
        'snapshot',
      ]);
    });
  }

  for (final field in ['recipient', 'position']) {
    test(
      'rejects a replay initial $field mismatch and closes the candidate',
      () async {
        final fixture = _Fixture();
        addTearDown(fixture.gateway.close);
        final document = await fixture.record();
        fixture.mutate = (request, body) {
          if (request != 'openReplay') return;
          if (field == 'recipient') {
            body['recipientPlayerId'] = 'player-2';
          } else {
            body['position'] = 1;
          }
        };
        await expectLater(
          fixture.open(document),
          throwsA(
            isA<ReplaySessionException>().having(
              (error) => error.code,
              'code',
              'invalid_replay_protocol',
            ),
          ),
        );
        expect(fixture.sessions.last.closeCalls, 1);
        expect(fixture.sessions.first.closeCalls, 0);
        expect(
          await fixture.gateway.replaySession.exportReplayDocument(),
          document,
        );
      },
    );
  }

  for (final field in ['recipient', 'command']) {
    test('rejects a replay step with an incompatible $field', () async {
      final fixture = _Fixture();
      addTearDown(fixture.gateway.close);
      await fixture.open(await fixture.record());
      fixture.mutate = (request, body) {
        if (request != 'seekReplay') return;
        if (field == 'recipient') {
          body['recipientPlayerId'] = 'player-2';
        } else {
          body['command'] = null;
        }
      };
      await expectLater(
        fixture.gateway.replaySession.seekReplay(1),
        _invalidFrame,
      );
    });
  }

  test(
    'rejects command feedback attached to a repeated replay position',
    () async {
      final fixture = _Fixture();
      addTearDown(fixture.gateway.close);
      await fixture.open(await fixture.record());
      Object? command;
      fixture.mutate = (request, body) {
        if (request != 'seekReplay') return;
        command = body['command'];
      };
      await fixture.gateway.replaySession.seekReplay(1);
      expect(command, isNotNull);
      fixture.mutate = (request, body) {
        if (request == 'seekReplay') body['command'] = command;
      };
      await expectLater(
        fixture.gateway.replaySession.seekReplay(1),
        _invalidFrame,
      );
    },
  );
}

final _invalidFrame = throwsA(
  isA<ReplaySessionException>().having(
    (error) => error.code,
    'code',
    'invalid_replay_frame',
  ),
);

typedef _Mutation = void Function(String request, Map<String, dynamic> body);

final class _Fixture {
  _Fixture() {
    gateway = EngineGameSessionGateway(
      assets: _FileAssetBundle(),
      sessionFactory: () async {
        final native = await createAonwEngineSession();
        if (native == null) throw StateError('Native session unavailable.');
        final session = _InterceptingSession(native, (request, body) {
          requests.add(request);
          mutate?.call(request, body);
        });
        sessions.add(session);
        return session;
      },
    );
  }

  late final EngineGameSessionGateway gateway;
  final sessions = <_InterceptingSession>[];
  final requests = <String>[];
  _Mutation? mutate;

  Future<void> startAndEndHumanTurn() async {
    final scene = await gateway.startLocalMatch(_setup());
    final result = await gateway.endTurn(
      expectedRevision: scene.player.stamp.revision,
    );
    expect(result.accepted, isTrue);
  }

  Future<LocalAiTurnExecutionView> advanceAi() => gateway.advanceAiTurn(
    LocalAiTurnRequestView(aiPlayerId: 'player-2', humanPlayerId: 'player-1'),
  );

  Future<String> record() async {
    await startAndEndHumanTurn();
    await advanceAi();
    return gateway.replaySession.exportReplayDocument();
  }

  Future<void> open(String document) async {
    await gateway.replaySession.openReplayDocument(
      assets: LocalGameCatalog.entries.first.assets,
      document: document,
    );
  }
}

final class _InterceptingSession implements AonwEngineSession {
  _InterceptingSession(this.native, this.mutate);
  final AonwEngineSession native;
  final _Mutation mutate;
  var closeCalls = 0;

  @override
  Future<String> requestJson(String request) async {
    final requestBody =
        (jsonDecode(request) as Map<String, dynamic>)['request']
            as Map<String, dynamic>;
    final result =
        jsonDecode(await native.requestJson(request)) as Map<String, dynamic>;
    final outcome = result['outcome'] as Map<String, dynamic>;
    if (outcome['status'] == 'success') {
      mutate(
        requestBody['type'] as String,
        outcome['response'] as Map<String, dynamic>,
      );
    }
    return jsonEncode(result);
  }

  @override
  Future<void> close() async {
    closeCalls++;
    await native.close();
  }
}

LocalMatchSetupView _setup() => LocalMatchSetupView(
  assets: LocalGameCatalog.entries.first.assets,
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
      name: 'AI',
      colorValue: 0xffee6c4d,
      country: LocalPlayerCountryView.japan,
      control: LocalPlayerControlView.ai,
      ai: const LocalAiProfileView(seed: 42),
    ),
  ],
  fogEnabled: false,
);

final class _FileAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(await File(key).readAsBytes()));
}
