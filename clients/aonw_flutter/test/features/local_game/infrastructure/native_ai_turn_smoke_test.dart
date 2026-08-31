import 'dart:async';
import 'dart:io';

import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:aonw_flutter/features/map/infrastructure/rust_game_session_gateway.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'runs a complete strategic AI turn on the retained native isolate',
    () async {
      final gateway = RustGameSessionGateway(assets: _FileAssetBundle());
      addTearDown(gateway.close);
      final scene = await gateway.startLocalMatch(_setup());

      final humanTurn = await gateway.endTurn(
        expectedRevision: scene.player.stamp.revision,
      );
      expect(humanTurn.accepted, isTrue);

      await expectLater(
        gateway.advanceAiTurn(
          LocalAiTurnRequestView(
            aiPlayerId: 'player-2',
            humanPlayerId: 'player-1',
            commandBudget: 1025,
          ),
        ),
        throwsA(
          isA<LocalGameSessionException>()
              .having(
                (error) => error.code,
                'code',
                'invalid_ai_command_budget',
              )
              .having(
                (error) => error.resyncedPlayer?.actorPlayerId,
                'restored actor',
                'player-1',
              ),
        ),
      );

      var eventLoopHeartbeat = false;
      Timer.run(() => eventLoopHeartbeat = true);
      final execution = await gateway.advanceAiTurn(
        LocalAiTurnRequestView(
          aiPlayerId: 'player-2',
          humanPlayerId: 'player-1',
        ),
      );

      expect(eventLoopHeartbeat, isTrue);
      expect(execution.aiPlayerId, 'player-2');
      expect(execution.completedTurn, isTrue);
      expect(execution.executedCommands, greaterThan(0));
      expect(execution.player.actorPlayerId, 'player-1');
      expect(
        execution.player.stamp.revision,
        greaterThan(humanTurn.player!.stamp.revision),
      );
    },
  );

  test(
    'completes a bounded multi-turn AI soak through the native client',
    () async {
      final gateway = RustGameSessionGateway(assets: _FileAssetBundle());
      addTearDown(gateway.close);
      var player = (await gateway.startLocalMatch(_setup())).player;
      var completedTurns = 0;

      for (var turn = 0; turn < 12; turn += 1) {
        if (player.turnView.outcome.isTerminal) break;
        final previousRevision = player.stamp.revision;
        final humanTurn = await gateway.endTurn(
          expectedRevision: previousRevision,
        );
        expect(humanTurn.accepted, isTrue);

        final execution = await gateway.advanceAiTurn(
          LocalAiTurnRequestView(
            aiPlayerId: 'player-2',
            humanPlayerId: 'player-1',
          ),
        );
        expect(execution.completedTurn, isTrue);
        expect(execution.player.actorPlayerId, 'player-1');
        expect(execution.player.stamp.revision, greaterThan(previousRevision));
        player = execution.player;
        completedTurns += 1;
      }

      expect(completedTurns, greaterThanOrEqualTo(4));
    },
  );
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
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}
