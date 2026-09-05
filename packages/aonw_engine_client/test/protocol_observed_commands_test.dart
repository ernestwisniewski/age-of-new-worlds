import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:test/test.dart';

void main() {
  test('runtime AI and replay fixtures preserve typed recipient commands', () {
    final ai = _parse(
      _document('ai_turn'),
    ).require<AonwAiTurnAdvancedResponse>();
    final replay = _parse(
      _document('replay_frame'),
    ).require<AonwReplayFrameResponse>();
    expect(ai.actorPlayerId, 'ai');
    expect(ai.recipientPlayerId, 'human');
    expect(ai.executedCommands, 3);
    expect(ai.commands, hasLength(3));
    expect(ai.commands.first.events.single, isA<AonwUnitMovedEvent>());
    final movement = ai.commands.first.evidence! as AonwUnitMovementEvidence;
    expect(movement.unitId, 'visible-ai');
    expect(movement.steps.single.coordinate.col, 1);
    expect(ai.commands[1].events, isEmpty);
    expect(ai.commands[1].evidence, isNull);
    expect(ai.commands[2].viewPatch.research, isNull);
    expect(replay.recipientPlayerId, 'human');
    expect(
      replay.command!.stamp.stateDigest,
      ai.commands.first.stamp.stateDigest,
    );
    expect(replay.command!.evidence, isA<AonwUnitMovementEvidence>());
    expect(() => ai.commands.add(ai.commands.first), throwsUnsupportedError);
  });

  test('AI frames require their recipient and command list', () {
    for (final field in ['recipientPlayerId', 'commands']) {
      final value = _document('ai_turn');
      _body(value).remove(field);
      expect(() => _parse(value), throwsFormatException, reason: field);
    }
    final value = _document('ai_turn');
    _command(_body(value), 0)['privateTarget'] = {'col': 9, 'row': 9};
    expect(() => _parse(value), throwsFormatException);
  });

  test('AI frames reject count, identity and revision discontinuities', () {
    for (final (path, replacement) in <(String, Object?)>[
      ('/executedCommands', 2),
      ('/commands', <Object?>[]),
      ('/stamp/stateDigest', 'wrong final digest'),
      ('/commands/0/stamp/revision', 7),
      ('/commands/0/stamp/mapHash', 'another map'),
      ('/commands/1/stamp/rulesetHash', 'another ruleset'),
      ('/commands/1/viewPatch/fromRevision', 0),
      ('/commands/1/viewPatch/toRevision', 8),
      ('/commands/2/viewPatch/fromRevision', 4),
    ]) {
      final value = _document('ai_turn');
      _replace(_body(value), path, replacement);
      expect(() => _parse(value), throwsFormatException, reason: path);
    }
  });

  test('AI response permits empty and bounded unchanged command series', () {
    final value = _document('ai_turn');
    final body = _body(value);
    final command = _command(body, 1);
    _replace(command, '/stamp/revision', 0);
    _replace(command, '/viewPatch/fromRevision', 0);
    _replace(command, '/viewPatch/toRevision', 0);
    body['stamp'] = command['stamp'];
    for (final count in [0, 1024, 1025]) {
      body['executedCommands'] = count;
      body['commands'] = List<Map<String, Object?>>.filled(count, command);
      if (count > 1024) {
        expect(() => _parse(value), throwsFormatException);
      } else {
        expect(
          _parse(value).require<AonwAiTurnAdvancedResponse>().commands,
          hasLength(count),
        );
      }
    }
    body['executedCommands'] = 2;
    body['commands'] = [jsonDecode(jsonEncode(command)), command];
    _replace(
      body,
      '/commands/0/stamp/stateDigest',
      'mutated at the same revision',
    );
    expect(() => _parse(value), throwsFormatException);
  });

  test('replay requires explicit command and matching snapshot boundary', () {
    for (final (path, replacement) in <(String, Object?)>[
      ('/position', 0),
      ('/entryCount', 0),
      ('/command/stamp/stateDigest', 'another state'),
      ('/command/viewPatch/turn', 99),
      ('/command/viewPatch/turnMode', 'simultaneous'),
      ('/command/viewPatch/fromRevision', 3),
    ]) {
      final value = _document('replay_frame');
      _replace(_body(value), path, replacement);
      expect(() => _parse(value), throwsFormatException, reason: path);
    }
    final value = _document('replay_frame');
    _body(value)['command'] = null;
    expect(_parse(value).require<AonwReplayFrameResponse>().command, isNull);
    for (final field in ['command', 'recipientPlayerId']) {
      final missing = _document('replay_frame');
      _body(missing).remove(field);
      expect(() => _parse(missing), throwsFormatException, reason: field);
    }
  });
}

Map<String, Object?> _document(String name) =>
    jsonDecode(
          File(
            '../../tests/fixtures/client_protocol/observed_${name}_response.json',
          ).readAsStringSync(),
        )
        as Map<String, Object?>;

Map<String, Object?> _body(Map<String, Object?> value) =>
    (value['outcome']! as Map<String, Object?>)['response']!
        as Map<String, Object?>;

Map<String, Object?> _command(Map<String, Object?> body, int index) =>
    (body['commands']! as List<Object?>)[index]! as Map<String, Object?>;

AonwClientResponse _parse(Map<String, Object?> value) =>
    AonwClientResponse.parse(jsonEncode(value));

void _replace(Map<String, Object?> value, String pointer, Object? replacement) {
  final segments = pointer.substring(1).split('/');
  Object? cursor = value;
  for (final segment in segments.take(segments.length - 1)) {
    cursor = cursor is List<Object?>
        ? cursor[int.parse(segment)]
        : (cursor! as Map<String, Object?>)[segment];
  }
  (cursor! as Map<String, Object?>)[segments.last] = replacement;
}
