import 'package:aonw_rust_client/aonw_rust_client.dart';

AonwMatchIdentity testMatchIdentity({
  int playerCount = 2,
  String firstPlayerId = 'player-1',
  Set<String> aiPlayerIds = const {},
  AonwAiDifficulty aiDifficulty = AonwAiDifficulty.normal,
}) {
  if (playerCount < 1 || playerCount > _countries.length) {
    throw ArgumentError.value(playerCount, 'playerCount');
  }
  final ids = <String>[
    firstPlayerId,
    for (var index = 1; index < playerCount; index++) 'player-${index + 1}',
  ];
  return AonwMatchIdentity(
    participants: [
      for (var index = 0; index < ids.length; index++)
        AonwParticipant(
          id: ids[index],
          name: index == 0 ? 'Player 1' : 'Player ${index + 1}',
          colorValue: _colors[index],
          country: _countries[index],
          kind: aiPlayerIds.contains(ids[index])
              ? AonwPlayerKind.ai
              : AonwPlayerKind.human,
          ai: aiPlayerIds.contains(ids[index])
              ? AonwAiPlayer(
                  strategyId: AonwAiStrategyId.utility,
                  difficulty: aiDifficulty,
                  persona: AonwAiPersona.balanced,
                  seed: 1000 + index,
                )
              : null,
        ),
    ],
    gameMode: AonwGameMode.hotSeat,
  );
}

const _colors = <int>[0xff3d5a80, 0xffee6c4d, 0xff2a9d8f, 0xfff4a261];

const _countries = <AonwPlayerCountry>[
  AonwPlayerCountry.poland,
  AonwPlayerCountry.japan,
  AonwPlayerCountry.egypt,
  AonwPlayerCountry.brazil,
];
