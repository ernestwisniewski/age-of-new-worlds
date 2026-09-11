import 'dart:convert';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:aonw_flutter/features/map/infrastructure/engine_game_session_gateway.dart';
import 'package:aonw_flutter/features/replay/application/local_replay_store.dart';

LocalMatchSetupView nativeReplaySetup() => LocalMatchSetupView(
  assets: LocalGameCatalog.entries.first.assets,
  fogEnabled: true,
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
);

final class NativeReplayStore implements LocalReplayStore {
  NativeReplayStore(this.document);
  String document;
  @override
  Future<bool> contains(LocalGameScenarioView scenario) async => true;
  @override
  Future<String?> read(
    LocalGameScenarioView scenario,
    LocalReplayCopyView copy,
  ) async => document;
  @override
  Future<void> write(LocalGameScenarioView scenario, String document) async {
    this.document = document;
  }
}

final class ReplayRecordingSession implements AonwEngineSession {
  ReplayRecordingSession(this.delegate, this.requests);
  final AonwEngineSession delegate;
  final List<String> requests;
  @override
  Future<String> requestJson(String request) {
    final envelope = jsonDecode(request) as Map<String, dynamic>;
    final body = envelope['request'] as Map<String, dynamic>;
    final action =
        (body['command'] ?? body['query'] ?? body) as Map<String, dynamic>;
    requests.add(action['type'] as String);
    return delegate.requestJson(request);
  }

  @override
  Future<void> close() => delegate.close();
}

Future<({String document, String finalDigest})> recordNativeReplay(
  EngineGameSessionGateway gateway,
) async {
  final initial = await gateway.startLocalMatch(nativeReplaySetup());
  final turn = await gateway.capabilities.turns.endTurn(
    expectedRevision: initial.player.stamp.revision,
  );
  if (!turn.accepted) throw StateError('The initial native turn was rejected.');
  final ai = await gateway.advanceAiTurn(
    LocalAiTurnRequestView(aiPlayerId: 'player-2', humanPlayerId: 'player-1'),
  );
  return (
    document: await gateway.replaySession.exportReplayDocument(),
    finalDigest: ai.player.stamp.stateDigest,
  );
}
