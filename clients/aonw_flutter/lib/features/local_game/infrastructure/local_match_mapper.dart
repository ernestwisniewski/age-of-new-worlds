import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../application/local_game_session_port.dart';

final class LocalMatchMapper {
  const LocalMatchMapper();

  AonwMatchIdentity toWire(LocalMatchSetupView setup) => AonwMatchIdentity(
    participants: setup.participants.map(_participant),
    gameMode: AonwGameMode.hotSeat,
  );

  LocalMatchControlPlanView restoredControlPlan(
    Iterable<AonwParticipantControl> participants,
  ) => LocalMatchControlPlanView(
    participants.map(
      (participant) => LocalParticipantControlView(
        id: participant.id,
        name: participant.name,
        control: LocalPlayerControlView.values.byName(participant.kind.name),
      ),
    ),
  );

  AonwParticipant _participant(LocalParticipantSetupView value) =>
      AonwParticipant(
        id: value.id,
        name: value.name,
        colorValue: value.colorValue,
        country: AonwPlayerCountry.values.byName(value.country.name),
        kind: AonwPlayerKind.values.byName(value.control.name),
        ai: value.ai == null ? null : _ai(value.ai!),
      );

  AonwAiPlayer _ai(LocalAiProfileView value) => AonwAiPlayer(
    strategyId: AonwAiStrategyId.values.byName(value.strategy.name),
    difficulty: AonwAiDifficulty.values.byName(value.difficulty.name),
    persona: AonwAiPersona.values.byName(value.persona.name),
    seed: value.seed,
  );
}
