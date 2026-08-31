import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:aonw_flutter/features/local_game/infrastructure/local_match_mapper.dart';
import 'package:aonw_flutter/features/map/application/map_session_port.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps the pure client setup to the strict current Rust contract', () {
    final setup = _setup();
    final wire = const LocalMatchMapper().toWire(setup).toJson();
    final participants = wire['participants']! as List<Object?>;
    final ai =
        (participants.last! as Map<String, Object?>)['ai']!
            as Map<String, Object?>;

    expect(wire['gameMode'], 'hotSeat');
    expect(participants, hasLength(2));
    expect(ai, {
      'strategyId': 'utility',
      'difficulty': 'hard',
      'persona': 'expansive',
      'seed': 42,
    });
  });

  test('requires the retained actor to identify a human participant', () {
    expect(
      () => LocalMatchSetupView(
        assets: MapAssetPaths.starter,
        participants: [
          LocalParticipantSetupView(
            id: 'preview-player',
            name: 'AI',
            colorValue: 0xff3d5a80,
            country: LocalPlayerCountryView.poland,
            control: LocalPlayerControlView.ai,
            ai: const LocalAiProfileView(seed: 1),
          ),
        ],
        fogEnabled: true,
      ),
      throwsArgumentError,
    );
  });
}

LocalMatchSetupView _setup() => LocalMatchSetupView(
  assets: MapAssetPaths.starter,
  participants: [
    LocalParticipantSetupView(
      id: 'preview-player',
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
      ai: const LocalAiProfileView(
        difficulty: LocalAiDifficultyView.hard,
        persona: LocalAiPersonaView.expansive,
        seed: 42,
      ),
    ),
  ],
  fogEnabled: true,
);
