import '../../map/application/map_session_port.dart';
import '../../map/read_model/map_scene.dart';
import '../../map/read_model/player_map_view.dart';

enum LocalPlayerControlView { human, ai }

enum LocalPlayerCountryView {
  poland,
  ukraine,
  germany,
  france,
  unitedKingdom,
  italy,
  spain,
  netherlands,
  sweden,
  russia,
  unitedStates,
  canada,
  china,
  korea,
  japan,
  portugal,
  india,
  brazil,
  indonesia,
  mexico,
  turkey,
  saudiArabia,
  egypt,
  greece,
}

enum LocalAiStrategyView { random, basic, scripted, utility, mcts }

enum LocalAiDifficultyView { easy, normal, hard, veryHard }

enum LocalAiPersonaView {
  balanced,
  aggressive,
  expansive,
  economic,
  scientific,
}

final class LocalAiProfileView {
  const LocalAiProfileView({
    this.strategy = LocalAiStrategyView.utility,
    this.difficulty = LocalAiDifficultyView.normal,
    this.persona = LocalAiPersonaView.balanced,
    required this.seed,
  });

  final LocalAiStrategyView strategy;
  final LocalAiDifficultyView difficulty;
  final LocalAiPersonaView persona;
  final int seed;
}

final class LocalParticipantSetupView {
  LocalParticipantSetupView({
    required String id,
    required String name,
    required int colorValue,
    required this.country,
    required this.control,
    this.ai,
  }) : id = _requireIdentifier(id, 'id'),
       name = _requireName(name),
       colorValue = _requireColor(colorValue) {
    if (control == LocalPlayerControlView.ai && ai == null) {
      throw ArgumentError.value(ai, 'ai', 'AI participant requires profile');
    }
    if (control == LocalPlayerControlView.human && ai != null) {
      throw ArgumentError.value(
        ai,
        'ai',
        'human participant forbids AI profile',
      );
    }
  }

  final String id;
  final String name;
  final int colorValue;
  final LocalPlayerCountryView country;
  final LocalPlayerControlView control;
  final LocalAiProfileView? ai;
}

final class LocalMatchSetupView {
  LocalMatchSetupView({
    required this.assets,
    required Iterable<LocalParticipantSetupView> participants,
    required this.fogEnabled,
  }) : participants = _validateParticipants(participants, assets.actorPlayerId);

  final MapAssetPaths assets;
  final List<LocalParticipantSetupView> participants;
  final bool fogEnabled;
}

final class LocalAiTurnRequestView {
  LocalAiTurnRequestView({
    required String aiPlayerId,
    required String humanPlayerId,
    int commandBudget = 256,
  }) : aiPlayerId = _requireIdentifier(aiPlayerId, 'aiPlayerId'),
       humanPlayerId = _requireIdentifier(humanPlayerId, 'humanPlayerId'),
       commandBudget = _requirePositive(commandBudget, 'commandBudget');

  final String aiPlayerId;
  final String humanPlayerId;
  final int commandBudget;
}

final class LocalAiTurnExecutionView {
  const LocalAiTurnExecutionView({
    required this.aiPlayerId,
    required this.executedCommands,
    required this.completedTurn,
    required this.player,
  });

  final String aiPlayerId;
  final int executedCommands;
  final bool completedTurn;
  final PlayerMapView player;
}

abstract interface class LocalGameSessionPort {
  Future<MapScene> startLocalMatch(LocalMatchSetupView setup);

  Future<LocalAiTurnExecutionView> advanceAiTurn(
    LocalAiTurnRequestView request,
  );
}

final class LocalGameSessionException implements Exception {
  const LocalGameSessionException({
    required this.code,
    required this.message,
    this.diagnosticCause,
    this.diagnosticStackTrace,
    this.resyncedPlayer,
  });

  final String code;
  final String message;
  final Object? diagnosticCause;
  final StackTrace? diagnosticStackTrace;
  final PlayerMapView? resyncedPlayer;

  @override
  String toString() => 'LocalGameSessionException($code): $message';
}

List<LocalParticipantSetupView> _validateParticipants(
  Iterable<LocalParticipantSetupView> values,
  String actorPlayerId,
) {
  final participants = List<LocalParticipantSetupView>.unmodifiable(values);
  if (participants.isEmpty) {
    throw ArgumentError.value(values, 'participants', 'must not be empty');
  }
  final ids = <String>{};
  for (final participant in participants) {
    if (!ids.add(participant.id)) {
      throw ArgumentError.value(
        participant.id,
        'participants',
        'participant ids must be unique',
      );
    }
  }
  final actor = participants.where((item) => item.id == actorPlayerId);
  if (actor.length != 1 ||
      actor.single.control != LocalPlayerControlView.human) {
    throw ArgumentError.value(
      actorPlayerId,
      'assets.actorPlayerId',
      'actor must identify exactly one human participant',
    );
  }
  return participants;
}

String _requireIdentifier(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, name, 'must be non-empty and trimmed');
  }
  return value;
}

String _requireName(String value) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, 'name', 'must not be blank');
  }
  return value;
}

int _requireColor(int value) {
  if (value < 0 || value > 0xffffffff) {
    throw ArgumentError.value(value, 'colorValue', 'must fit unsigned 32-bit');
  }
  return value;
}

int _requirePositive(int value, String name) {
  if (value <= 0) {
    throw ArgumentError.value(value, name, 'must be positive');
  }
  return value;
}
