import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:test/test.dart';

void main() {
  test('AI request carries the explicit standard profile by default', () {
    final request = AonwClientRequest.advanceAiTurn(
      actorPlayerId: 'ai',
      commandBudget: 256,
    );
    expect(jsonDecode(request.toJson()), {
      'apiVersion': aonwClientApiVersion,
      'request': {
        'type': 'advanceAiTurn',
        'actorPlayerId': 'ai',
        'commandBudget': 256,
        'runtimeProfile': 'standard',
      },
    });
  });
  test('battery saver request matches the shared Rust fixture', () {
    final source = File(
      '../../tests/fixtures/client_protocol/advance_ai_turn_request.json',
    ).readAsStringSync();
    final request = AonwClientRequest.advanceAiTurn(
      actorPlayerId: 'player-2',
      commandBudget: 64,
      runtimeProfile: AonwAiRuntimeProfile.batterySaver,
    );
    expect(jsonDecode(request.toJson()), jsonDecode(source));
  });
}
