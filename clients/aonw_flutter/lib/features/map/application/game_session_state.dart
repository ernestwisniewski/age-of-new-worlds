import '../../diplomacy/application/diplomacy_state.dart';
import '../../local_game/application/local_ai_turn_state.dart';
import '../../local_game/application/local_handoff_state.dart';
import '../../research/application/research_state.dart';
import '../../save_game/application/local_save_state.dart';
import '../../turns/application/turn_action_state.dart';
import '../../turns/application/turn_presentation_queue.dart';
import '../read_model/map_command_frame_view.dart';
import '../read_model/map_scene.dart';
import '../read_model/map_view_mode.dart';
import '../read_model/player_map_view.dart';
import 'hex_inspection_state.dart';
import 'map_interaction_state.dart';

sealed class GameSessionState {
  const GameSessionState();
}

final class GameSessionLoading extends GameSessionState {
  const GameSessionLoading();
}

final class GameSessionReady extends GameSessionState {
  const GameSessionReady({
    required this.scene,
    required this.interaction,
    required this.turnPresentations,
    required this.turnAction,
    required this.research,
    required this.diplomacy,
    required this.localAiTurn,
    required this.localHandoff,
    required this.localSave,
    this.commandFrame,
    this.inspection,
  });

  factory GameSessionReady.initial(
    MapScene scene, {
    MapViewMode viewMode = MapViewMode.graphic,
  }) => GameSessionReady(
    scene: scene,
    interaction: MapInteractionState(viewMode: viewMode),
    turnPresentations: TurnPresentationQueue.start(scene.player.turn),
    turnAction: const TurnActionState(),
    research: ResearchState.loading(scene.player.stamp.revision),
    diplomacy: const DiplomacyState(),
    localAiTurn: const LocalAiTurnState.idle(),
    localHandoff: const LocalHandoffState.idle(),
    localSave: const LocalSaveState.idle(),
  );

  final HexInspectionState? inspection;
  final MapScene scene;
  final MapInteractionState interaction;
  final TurnPresentationQueue turnPresentations;
  final TurnActionState turnAction;
  final ResearchState research;
  final DiplomacyState diplomacy;
  final LocalAiTurnState localAiTurn;
  final LocalHandoffState localHandoff;
  final LocalSaveState localSave;
  final MapCommandFrameView? commandFrame;

  PlayerMapView get recipient => scene.player;

  GameSessionReady withInspection(HexInspectionState? value) =>
      GameSessionReady(
        scene: scene,
        interaction: interaction,
        turnPresentations: turnPresentations,
        turnAction: turnAction,
        research: research,
        diplomacy: diplomacy,
        localAiTurn: localAiTurn,
        localHandoff: localHandoff,
        localSave: localSave,
        commandFrame: commandFrame,
        inspection: value,
      );

  GameSessionReady withInteraction(MapInteractionState value) =>
      GameSessionReady(
        scene: scene,
        interaction: value,
        turnPresentations: turnPresentations,
        turnAction: turnAction,
        research: research,
        diplomacy: diplomacy,
        localAiTurn: localAiTurn,
        localHandoff: localHandoff,
        localSave: localSave,
        commandFrame: commandFrame,
        inspection: inspection,
      );

  GameSessionReady withRecipient(
    PlayerMapView value, {
    MapCommandFrameView? commandFrame,
  }) {
    final identityChanged =
        (
          value.actorPlayerId,
          value.stamp.revision,
          value.stamp.stateDigest,
          value.stamp.mapHash,
          value.stamp.rulesetHash,
        ) !=
        (
          recipient.actorPlayerId,
          recipient.stamp.revision,
          recipient.stamp.stateDigest,
          recipient.stamp.mapHash,
          recipient.stamp.rulesetHash,
        );
    return GameSessionReady(
      scene: scene.withPlayer(value),
      interaction: identityChanged
          ? interaction.copyWith(
              production: interaction.production?.invalidateInspection(
                clear:
                    recipient.actorPlayerId != value.actorPlayerId ||
                    value.controlledCityById(interaction.production!.cityId) ==
                        null,
              ),
              moveTargeting: false,
              researchFocused: false,
              worker: interaction.worker?.copyWith(
                actionsOpen: false,
                clearPreview: true,
              ),
            )
          : interaction,
      turnPresentations: turnPresentations.observe(value.turn),
      turnAction: turnAction,
      research: identityChanged
          ? ResearchState.loading(value.stamp.revision)
          : research,
      diplomacy: identityChanged ? const DiplomacyState() : diplomacy,
      localAiTurn: localAiTurn,
      localHandoff: localHandoff,
      localSave: localSave,
      commandFrame: commandFrame,
      inspection: identityChanged ? null : inspection,
    );
  }

  GameSessionReady withTurnPresentations(TurnPresentationQueue value) =>
      GameSessionReady(
        scene: scene,
        interaction: interaction,
        turnPresentations: value,
        turnAction: turnAction,
        research: research,
        diplomacy: diplomacy,
        localAiTurn: localAiTurn,
        localHandoff: localHandoff,
        localSave: localSave,
        commandFrame: commandFrame,
        inspection: inspection,
      );

  GameSessionReady withTurnAction(TurnActionState value) => GameSessionReady(
    scene: scene,
    interaction: interaction,
    turnPresentations: turnPresentations,
    turnAction: value,
    research: research,
    diplomacy: diplomacy,
    localAiTurn: localAiTurn,
    localHandoff: localHandoff,
    localSave: localSave,
    commandFrame: commandFrame,
    inspection: inspection,
  );

  GameSessionReady withResearch(ResearchState value) => GameSessionReady(
    scene: scene,
    interaction: interaction,
    turnPresentations: turnPresentations,
    turnAction: turnAction,
    research: value,
    diplomacy: diplomacy,
    localAiTurn: localAiTurn,
    localHandoff: localHandoff,
    localSave: localSave,
    commandFrame: commandFrame,
    inspection: inspection,
  );

  GameSessionReady withDiplomacy(DiplomacyState value) => GameSessionReady(
    scene: scene,
    interaction: interaction,
    turnPresentations: turnPresentations,
    turnAction: turnAction,
    research: research,
    diplomacy: value,
    localAiTurn: localAiTurn,
    localHandoff: localHandoff,
    localSave: localSave,
    commandFrame: commandFrame,
    inspection: inspection,
  );

  GameSessionReady withLocalAiTurn(LocalAiTurnState value) => GameSessionReady(
    scene: scene,
    interaction: interaction,
    turnPresentations: turnPresentations,
    turnAction: turnAction,
    research: research,
    diplomacy: diplomacy,
    localAiTurn: value,
    localHandoff: localHandoff,
    localSave: localSave,
    commandFrame: commandFrame,
    inspection: value.blocksGameplay ? null : inspection,
  );

  GameSessionReady withLocalHandoff(LocalHandoffState value) =>
      GameSessionReady(
        scene: scene,
        interaction: interaction,
        turnPresentations: turnPresentations,
        turnAction: turnAction,
        research: research,
        diplomacy: diplomacy,
        localAiTurn: localAiTurn,
        localHandoff: value,
        localSave: localSave,
        commandFrame: commandFrame,
        inspection: value.blocksGameplay ? null : inspection,
      );

  GameSessionReady withLocalSave(LocalSaveState value) => GameSessionReady(
    scene: scene,
    interaction: interaction,
    turnPresentations: turnPresentations,
    turnAction: turnAction,
    research: research,
    diplomacy: diplomacy,
    localAiTurn: localAiTurn,
    localHandoff: localHandoff,
    localSave: value,
    commandFrame: commandFrame,
    inspection: inspection,
  );

  GameSessionReady completeTurnPresentation() =>
      withTurnPresentations(turnPresentations.completeActive());
}

enum MapLoadFailureViewCode {
  adapterUnavailable,
  incompatibleClient,
  loadSuperseded,
  mapUnavailable,
}

final class GameSessionFailure extends GameSessionState {
  const GameSessionFailure({required this.code});

  final MapLoadFailureViewCode code;
}
