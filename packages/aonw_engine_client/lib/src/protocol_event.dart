import 'package:aonw_engine_client/src/protocol_city_view.dart';
import 'package:aonw_engine_client/src/protocol_coordinate.dart';
import 'package:aonw_engine_client/src/protocol_diplomacy.dart';
import 'package:aonw_engine_client/src/protocol_evidence.dart';
import 'package:aonw_engine_client/src/protocol_json.dart';
import 'package:aonw_engine_client/src/protocol_map.dart';
import 'package:aonw_engine_client/src/protocol_outcome.dart';
import 'package:aonw_engine_client/src/protocol_pending_action.dart';
import 'package:aonw_engine_client/src/protocol_player_view.dart';
import 'package:aonw_engine_client/src/protocol_query.dart';
import 'package:aonw_engine_client/src/protocol_research_values.dart';
import 'package:aonw_engine_client/src/protocol_values.dart';

part 'protocol_artifact_event.dart';
part 'protocol_city_event.dart';
part 'protocol_event_schema.dart';
part 'protocol_research_event.dart';
part 'protocol_unit_status_event.dart';
part 'protocol_worker_event.dart';

enum AonwClientEventKind {
  artifactExcavationStarted,
  artifactCarried,
  artifactStored,
  cityFounded,
  cityBuiltBuilding,
  cityProducedUnit,
  cityBuiltWonder,
  wonderProductionRefunded,
  technologyResearched,
  researchPointsGained,
  cityClaimedHex,
  stabilityBandChanged,
  mapObjectiveSecured,
  dominationThresholdReached,
  matchEnded,
  unitAttacked,
  cityAttacked,
  combatResolved,
  diplomaticScoreChanged,
  diplomaticProposalSent,
  diplomaticProposalResponded,
  diplomaticProposalExpired,
  diplomaticMessageSent,
  diplomaticMessageResponded,
  diplomaticPromiseBroken,
  diplomaticRelationChanged,
  unitGainedExperience,
  unitKilled,
  unitRetreated,
  cityCaptured,
  cityDestroyed,
  unitMoved,
  autoExplorePlanned,
  merchantRouteAssigned,
  merchantTravelQueued,
  troopDetached,
  turnEnded,
  allPlayersSubmitted,
  playerTimedOut,
  playerKicked,
  workerCompletedJob,
}

sealed class AonwClientEvent {
  const AonwClientEvent(this.kind);

  factory AonwClientEvent.fromJson(Object? source) {
    final value = readObject(source, 'client event');
    final type = readString(value['type'], 'client event type');
    return switch (type) {
      'unitMoved' => AonwUnitMovedEvent.fromJson(value),
      'turnEnded' => AonwTurnEndedEvent.fromJson(value),
      'allPlayersSubmitted' => AonwAllPlayersSubmittedEvent.fromJson(value),
      'playerTimedOut' => AonwPlayerTimedOutEvent.fromJson(value),
      'playerKicked' => AonwPlayerKickedEvent.fromJson(value),
      'matchEnded' => AonwMatchEndedEvent.fromJson(value),
      _ => _knownEvent(value, type),
    };
  }

  final AonwClientEventKind kind;
}

final class AonwPresentationEvent extends AonwClientEvent {
  const AonwPresentationEvent(super.kind);
}

final class AonwUnitMovedEvent extends AonwClientEvent {
  const AonwUnitMovedEvent({
    required this.unitId,
    required this.from,
    required this.to,
  }) : super(AonwClientEventKind.unitMoved);

  factory AonwUnitMovedEvent.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'unitId',
      'from',
      'to',
    }, 'unit moved event');
    return AonwUnitMovedEvent(
      unitId: readString(value['unitId'], 'moved unit id'),
      from: AonwCoordinate.fromJson(value['from']),
      to: AonwCoordinate.fromJson(value['to']),
    );
  }

  final String unitId;
  final AonwCoordinate from;
  final AonwCoordinate to;
}

final class AonwTurnEndedEvent extends AonwClientEvent {
  const AonwTurnEndedEvent({required this.playerId})
    : super(AonwClientEventKind.turnEnded);

  factory AonwTurnEndedEvent.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'playerId'}, 'turn ended event');
    return AonwTurnEndedEvent(
      playerId: readString(value['playerId'], 'turn player id'),
    );
  }

  final String playerId;
}

final class AonwAllPlayersSubmittedEvent extends AonwClientEvent {
  AonwAllPlayersSubmittedEvent({
    required this.turn,
    required List<String> playerIds,
  }) : playerIds = List.unmodifiable(playerIds),
       super(AonwClientEventKind.allPlayersSubmitted);

  factory AonwAllPlayersSubmittedEvent.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'turn',
      'playerIds',
    }, 'all players submitted event');
    return AonwAllPlayersSubmittedEvent(
      turn: readUnsigned(value['turn'], 'submitted turn'),
      playerIds: _strings(value['playerIds'], 'submitted player ids'),
    );
  }

  final int turn;
  final List<String> playerIds;
}

final class AonwPlayerTimedOutEvent extends AonwClientEvent {
  const AonwPlayerTimedOutEvent({required this.turn, required this.playerId})
    : super(AonwClientEventKind.playerTimedOut);

  factory AonwPlayerTimedOutEvent.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'turn', 'playerId'}, 'timeout event');
    return AonwPlayerTimedOutEvent(
      turn: readUnsigned(value['turn'], 'timeout turn'),
      playerId: readString(value['playerId'], 'timed out player id'),
    );
  }

  final int turn;
  final String playerId;
}

final class AonwPlayerKickedEvent extends AonwClientEvent {
  const AonwPlayerKickedEvent({
    required this.turn,
    required this.playerId,
    required this.reason,
    required this.timeoutStreak,
  }) : super(AonwClientEventKind.playerKicked);

  factory AonwPlayerKickedEvent.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'turn',
      'playerId',
      'reason',
      'timeoutStreak',
    }, 'player kicked event');
    return AonwPlayerKickedEvent(
      turn: readUnsigned(value['turn'], 'kick turn'),
      playerId: readString(value['playerId'], 'kicked player id'),
      reason: readString(value['reason'], 'kick reason'),
      timeoutStreak: readInt(value['timeoutStreak'], 'timeout streak'),
    );
  }

  final int turn;
  final String playerId;
  final String reason;
  final int timeoutStreak;
}

final class AonwMatchEndedEvent extends AonwClientEvent {
  const AonwMatchEndedEvent({required this.turn, required this.outcome})
    : super(AonwClientEventKind.matchEnded);

  factory AonwMatchEndedEvent.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'turn', 'outcome'}, 'match ended event');
    return AonwMatchEndedEvent(
      turn: readUnsigned(value['turn'], 'match end turn'),
      outcome: AonwGameOutcome.fromJson(value['outcome']),
    );
  }

  final int turn;
  final AonwGameOutcome outcome;
}

AonwClientEvent _knownEvent(Map<String, Object?> value, String type) {
  final kind = AonwClientEventKind.values
      .where((candidate) => candidate.name == type)
      .firstOrNull;
  if (kind == null) throw FormatException('Unknown AoNW client event $type.');
  _validatePresentationEvent(value, type);
  return _cityEvent(value, kind) ??
      _researchEvent(value, kind) ??
      _artifactEvent(value, kind) ??
      _workerEvent(value, kind) ??
      _unitStatusEvent(value, kind) ??
      AonwPresentationEvent(kind);
}

List<String> _strings(Object? value, String label) =>
    readList(value, label, (item, _) => readString(item, label));
