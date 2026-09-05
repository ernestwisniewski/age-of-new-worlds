import 'package:aonw_engine_client/src/protocol_execution.dart';
import 'package:aonw_engine_client/src/protocol_json.dart';
import 'package:aonw_engine_client/src/protocol_map.dart';
import 'package:aonw_engine_client/src/protocol_match.dart';
import 'package:aonw_engine_client/src/protocol_observed_commands.dart';
import 'package:aonw_engine_client/src/protocol_player_view.dart';
import 'package:aonw_engine_client/src/protocol_query.dart';
import 'package:aonw_engine_client/src/protocol_values.dart';

sealed class AonwClientResponseBody {
  const AonwClientResponseBody();

  factory AonwClientResponseBody.fromJson(Object? source) {
    final value = readObject(source, 'success response');
    final type = readString(value['type'], 'client response type');
    final parser = _responseParsers[type];
    if (parser == null) {
      throw FormatException('Unknown AoNW client response $type.');
    }
    return parser(value);
  }
}

typedef _ResponseParser =
    AonwClientResponseBody Function(Map<String, Object?> value);

final Map<String, _ResponseParser> _responseParsers = {
  'capabilities': AonwCapabilitiesResponse.fromJson,
  'mapInspected': AonwMapInspectedResponse.fromJson,
  'sessionOpened': AonwSessionOpenedResponse.fromJson,
  'actorHandedOff': AonwActorHandedOffResponse.fromJson,
  'aiTurnAdvanced': AonwAiTurnAdvancedResponse.fromJson,
  'sessionClosed': AonwSessionClosedResponse.fromJson,
  'snapshot': AonwSnapshotResponse.fromJson,
  'query': AonwQueryResponse.fromJson,
  'command': AonwCommandResponse.fromJson,
  'saveExported': AonwSaveExportedResponse.fromJson,
  'saveOpened': AonwSaveOpenedResponse.fromJson,
  'replayExported': AonwReplayExportedResponse.fromJson,
  'replayVerified': AonwReplayVerifiedResponse.fromJson,
  'replayFrame': AonwReplayFrameResponse.fromJson,
};

final class AonwMapInspectedResponse extends AonwClientResponseBody {
  const AonwMapInspectedResponse(this.map);

  factory AonwMapInspectedResponse.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'map'}, 'map inspected response');
    return AonwMapInspectedResponse(AonwMapView.fromJson(value['map']));
  }

  final AonwMapView map;
}

final class AonwCapabilitiesResponse extends AonwClientResponseBody {
  const AonwCapabilitiesResponse({required this.features});

  factory AonwCapabilitiesResponse.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'features'}, 'capabilities response');
    return AonwCapabilitiesResponse(
      features: readList(
        value['features'],
        'client features',
        (item, _) => AonwClientFeature.fromJson(item),
      ),
    );
  }

  final List<AonwClientFeature> features;
}

final class AonwSessionOpenedResponse extends AonwClientResponseBody {
  const AonwSessionOpenedResponse(this.stamp);

  factory AonwSessionOpenedResponse.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'stamp'}, 'session opened response');
    return AonwSessionOpenedResponse(AonwSessionStamp.fromJson(value['stamp']));
  }

  final AonwSessionStamp stamp;
}

final class AonwActorHandedOffResponse extends AonwClientResponseBody {
  const AonwActorHandedOffResponse(this.stamp);

  factory AonwActorHandedOffResponse.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'stamp'}, 'actor handed off response');
    return AonwActorHandedOffResponse(
      AonwSessionStamp.fromJson(value['stamp']),
    );
  }

  final AonwSessionStamp stamp;
}

final class AonwAiTurnAdvancedResponse extends AonwClientResponseBody {
  const AonwAiTurnAdvancedResponse({
    required this.stamp,
    required this.actorPlayerId,
    required this.recipientPlayerId,
    required this.executedCommands,
    required this.completedTurn,
    required this.commands,
  });

  factory AonwAiTurnAdvancedResponse.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'stamp',
      'actorPlayerId',
      'recipientPlayerId',
      'executedCommands',
      'completedTurn',
      'commands',
    }, 'AI turn advanced response');
    final completedTurn = value['completedTurn'];
    if (completedTurn is! bool) {
      throw const FormatException('Invalid AI turn completion flag.');
    }
    final stamp = AonwSessionStamp.fromJson(value['stamp']);
    final executedCommands = readUnsigned(
      value['executedCommands'],
      'AI executed command count',
    );
    return AonwAiTurnAdvancedResponse(
      stamp: stamp,
      actorPlayerId: readString(value['actorPlayerId'], 'AI actor player id'),
      recipientPlayerId: readString(
        value['recipientPlayerId'],
        'AI observing player id',
      ),
      executedCommands: executedCommands,
      completedTurn: completedTurn,
      commands: readObservedCommands(
        value['commands'],
        executedCommands,
        stamp,
      ),
    );
  }

  final AonwSessionStamp stamp;
  final String actorPlayerId;
  final String recipientPlayerId;
  final int executedCommands;
  final bool completedTurn;
  final List<AonwCommandResult> commands;
}

final class AonwSessionClosedResponse extends AonwClientResponseBody {
  const AonwSessionClosedResponse();

  factory AonwSessionClosedResponse.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type'}, 'session closed response');
    return const AonwSessionClosedResponse();
  }
}

final class AonwSnapshotResponse extends AonwClientResponseBody {
  const AonwSnapshotResponse(this.snapshot);

  factory AonwSnapshotResponse.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'snapshot'}, 'snapshot response');
    return AonwSnapshotResponse(
      AonwPlayerViewSnapshot.fromJson(value['snapshot']),
    );
  }

  final AonwPlayerViewSnapshot snapshot;
}

final class AonwQueryResponse extends AonwClientResponseBody {
  const AonwQueryResponse(this.result);

  factory AonwQueryResponse.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'result'}, 'query response');
    return AonwQueryResponse(AonwQueryResult.fromJson(value['result']));
  }

  final AonwQueryResult result;
}

final class AonwCommandResponse extends AonwClientResponseBody {
  const AonwCommandResponse(this.result);

  factory AonwCommandResponse.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'result'}, 'command response');
    return AonwCommandResponse(AonwCommandResult.fromJson(value['result']));
  }

  final AonwCommandResult result;
}

final class AonwSaveExportedResponse extends AonwClientResponseBody {
  const AonwSaveExportedResponse(this.document);

  factory AonwSaveExportedResponse.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'document'}, 'save exported response');
    return AonwSaveExportedResponse(
      readString(value['document'], 'save document'),
    );
  }

  final String document;
}

final class AonwSaveOpenedResponse extends AonwClientResponseBody {
  const AonwSaveOpenedResponse({
    required this.stamp,
    required this.actorPlayerId,
    required this.participants,
  });

  factory AonwSaveOpenedResponse.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'stamp',
      'actorPlayerId',
      'participants',
    }, 'save opened response');
    return AonwSaveOpenedResponse(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      actorPlayerId: readString(value['actorPlayerId'], 'restored actor id'),
      participants: readList(
        value['participants'],
        'restored participants',
        (item, _) => AonwParticipantControl.fromJson(item),
      ),
    );
  }

  final AonwSessionStamp stamp;
  final String actorPlayerId;
  final List<AonwParticipantControl> participants;
}

final class AonwParticipantControl {
  const AonwParticipantControl({
    required this.id,
    required this.name,
    required this.kind,
  });

  factory AonwParticipantControl.fromJson(Object? source) {
    final value = readObject(source, 'restored participant');
    requireKeys(value, const {'id', 'name', 'kind'}, 'restored participant');
    final kindName = readString(value['kind'], 'restored participant kind');
    final AonwPlayerKind kind;
    try {
      kind = AonwPlayerKind.values.byName(kindName);
    } on ArgumentError {
      throw FormatException('Unknown restored participant kind $kindName.');
    }
    return AonwParticipantControl(
      id: readString(value['id'], 'restored participant id'),
      name: readString(value['name'], 'restored participant name'),
      kind: kind,
    );
  }

  final String id;
  final String name;
  final AonwPlayerKind kind;
}

final class AonwReplayExportedResponse extends AonwClientResponseBody {
  const AonwReplayExportedResponse(this.document);

  factory AonwReplayExportedResponse.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'document'}, 'replay exported response');
    return AonwReplayExportedResponse(
      readString(value['document'], 'replay document'),
    );
  }

  final String document;
}

final class AonwReplayVerifiedResponse extends AonwClientResponseBody {
  const AonwReplayVerifiedResponse(this.verification);

  factory AonwReplayVerifiedResponse.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'verification',
    }, 'replay verified response');
    return AonwReplayVerifiedResponse(
      AonwReplayVerification.fromJson(value['verification']),
    );
  }

  final AonwReplayVerification verification;
}

final class AonwReplayFrameResponse extends AonwClientResponseBody {
  const AonwReplayFrameResponse({
    required this.position,
    required this.entryCount,
    required this.recipientPlayerId,
    required this.snapshot,
    required this.command,
  });

  factory AonwReplayFrameResponse.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'position',
      'entryCount',
      'recipientPlayerId',
      'snapshot',
      'command',
    }, 'replay frame response');
    final position = readUnsigned(value['position'], 'replay position');
    final entryCount = readUnsigned(value['entryCount'], 'replay entry count');
    final snapshot = AonwPlayerViewSnapshot.fromJson(value['snapshot']);
    final command = value['command'] == null
        ? null
        : AonwCommandResult.fromJson(value['command']);
    validateObservedReplay(position, entryCount, snapshot, command);
    return AonwReplayFrameResponse(
      position: position,
      entryCount: entryCount,
      recipientPlayerId: readString(
        value['recipientPlayerId'],
        'replay recipient player id',
      ),
      snapshot: snapshot,
      command: command,
    );
  }

  final int position;
  final int entryCount;
  final String recipientPlayerId;
  final AonwPlayerViewSnapshot snapshot;
  final AonwCommandResult? command;
}

final class AonwReplayVerification {
  const AonwReplayVerification({
    required this.entryCount,
    required this.finalEventOffset,
    required this.finalStamp,
  });

  factory AonwReplayVerification.fromJson(Object? source) {
    final value = readObject(source, 'replay verification');
    requireKeys(value, const {
      'entryCount',
      'finalEventOffset',
      'finalStamp',
    }, 'replay verification');
    return AonwReplayVerification(
      entryCount: readUnsigned(value['entryCount'], 'verified entry count'),
      finalEventOffset: readUnsigned(
        value['finalEventOffset'],
        'final event offset',
      ),
      finalStamp: AonwSessionStamp.fromJson(value['finalStamp']),
    );
  }

  final int entryCount;
  final int finalEventOffset;
  final AonwSessionStamp finalStamp;
}
