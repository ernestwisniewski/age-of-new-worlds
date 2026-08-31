import 'dart:convert';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:test/test.dart';

void main() {
  test('start-match request serializes one strict typed local AI roster', () {
    final identity = AonwMatchIdentity(
      participants: [
        AonwParticipant(
          id: 'player-1',
          name: 'Player 1',
          colorValue: 0xff3d5a80,
          country: AonwPlayerCountry.poland,
          kind: AonwPlayerKind.human,
        ),
        AonwParticipant(
          id: 'player-2',
          name: 'Player 2',
          colorValue: 0xffee6c4d,
          country: AonwPlayerCountry.japan,
          kind: AonwPlayerKind.ai,
          ai: AonwAiPlayer(
            strategyId: AonwAiStrategyId.utility,
            difficulty: AonwAiDifficulty.hard,
            persona: AonwAiPersona.expansive,
            seed: 42,
          ),
        ),
      ],
      gameMode: AonwGameMode.hotSeat,
    );

    final envelope =
        jsonDecode(
              AonwClientRequest.startMatch(
                mapDocument: 'map',
                scenarioDocument: 'scenario',
                actorPlayerId: 'player-1',
                matchIdentity: identity,
                fogEnabled: true,
              ).toJson(),
            )
            as Map<String, Object?>;
    final request = envelope['request']! as Map<String, Object?>;
    final match = request['matchIdentity']! as Map<String, Object?>;
    final participants = match['participants']! as List<Object?>;

    expect(request['type'], 'startMatch');
    expect(match['gameMode'], 'hotSeat');
    expect(match['turnMode'], 'sequential');
    expect((match['matchRules']! as Map<String, Object?>)['balance'], isEmpty);
    expect(participants, hasLength(2));
    expect((participants.last! as Map<String, Object?>)['ai'], {
      'strategyId': 'utility',
      'difficulty': 'hard',
      'persona': 'expansive',
      'seed': 42,
    });
  });

  test('match types reject invalid participant and duration state', () {
    expect(
      () => AonwParticipant(
        id: 'ai',
        name: 'AI',
        colorValue: 0,
        country: AonwPlayerCountry.germany,
        kind: AonwPlayerKind.ai,
      ),
      throwsArgumentError,
    );
    expect(
      () => AonwMatchIdentity(
        participants: const [],
        gameMode: AonwGameMode.hotSeat,
      ),
      throwsArgumentError,
    );
    expect(
      () => AonwGameLength.targetMinutes(
        targetMinutes: 60,
        turnLimit: 0,
        paceProfile: AonwPaceProfile.standard60,
        scoreFallbackEnabled: true,
      ),
      throwsArgumentError,
    );
  });

  test('match identity keeps turn resolution separate from session mode', () {
    final participant = AonwParticipant(
      id: 'player-1',
      name: 'Player 1',
      colorValue: 0xff3d5a80,
      country: AonwPlayerCountry.poland,
      kind: AonwPlayerKind.human,
    );

    expect(
      AonwMatchIdentity(
        participants: [participant],
        gameMode: AonwGameMode.hotSeat,
      ).turnMode,
      AonwTurnMode.sequential,
    );
    expect(
      AonwMatchIdentity(
        participants: [participant],
        gameMode: AonwGameMode.hotSeat,
        turnMode: AonwTurnMode.simultaneous,
      ).toJson()['turnMode'],
      'simultaneous',
    );
  });
}
