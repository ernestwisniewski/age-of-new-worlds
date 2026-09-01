import 'dart:convert';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as server;

import '../read_model/multiplayer_view.dart';

final class ServerProjectionDecoder {
  const ServerProjectionDecoder();

  MultiplayerProjectionView resync(server.GameResync value) {
    final snapshot = snapshotFromResync(value);
    return _projection(
      matchId: value.matchId,
      playerId: value.playerId,
      eventOffset: value.eventOffset,
      snapshot: snapshot,
    );
  }

  AonwPlayerViewSnapshot snapshotFromResync(server.GameResync value) {
    _identifier(value.matchId, 'match id');
    _identifier(value.playerId, 'player id');
    _unsigned(value.eventOffset, 'event offset');
    return AonwPlayerViewSnapshot.fromJson(jsonDecode(value.snapshotJson));
  }

  String snapshotResponseJson(server.GameResync value) {
    snapshotFromResync(value);
    return _successResponseJson({
      'type': 'snapshot',
      'snapshot': jsonDecode(value.snapshotJson),
    });
  }

  AonwClientResponse snapshotResponse(server.GameResync value) =>
      AonwClientResponse.parse(snapshotResponseJson(value));

  String queryResponseJson(server.GamePlayerQueryOutcome value) {
    _identifier(value.matchId, 'match id');
    final outcome = _object(jsonDecode(value.outcomeJson), 'query outcome');
    return switch (outcome['status']) {
      'success' => _querySuccessJson(outcome),
      'failure' => _queryFailureJson(outcome),
      _ => throw const FormatException('Unknown query outcome status.'),
    };
  }

  AonwClientResponse queryResponse(server.GamePlayerQueryOutcome value) =>
      AonwClientResponse.parse(queryResponseJson(value));

  MultiplayerCommandView command(server.GameCommandOutcome value) =>
      _decodeCommand(value).view;

  String commandResponseJson(server.GameCommandOutcome value) {
    final decoded = _decodeCommand(value);
    return _successResponseJson({'type': 'command', 'result': decoded.result});
  }

  AonwClientResponse commandResponse(server.GameCommandOutcome value) =>
      AonwClientResponse.parse(commandResponseJson(value));

  _DecodedServerCommand _decodeCommand(server.GameCommandOutcome value) {
    final decoded = _commandEnvelope(value);
    final outcome = decoded.outcome;
    final recipient = decoded.recipient;
    final rejection = decoded.rejection;
    final commandResult = <String, Object?>{
      'stamp': outcome['stamp'],
      'outcome': rejection == null
          ? const {'status': 'accepted'}
          : {'status': 'rejected', 'code': rejection},
      'events': recipient['events'],
      'evidence': recipient['evidence'],
      'viewPatch': recipient['patch'],
    };
    final command = AonwCommandResult.fromJson(commandResult);
    final snapshot = AonwPlayerViewSnapshot.fromJson(recipient['snapshot']);
    if (!_sameStamp(command.stamp, snapshot.stamp) ||
        command.viewPatch.toRevision != snapshot.stamp.revision) {
      throw const FormatException(
        'Command snapshot, patch, and stamp do not identify one revision.',
      );
    }
    final projection = _projection(
      matchId: value.matchId,
      playerId: decoded.playerId,
      eventOffset: value.finalEventOffset,
      snapshot: snapshot,
    );
    return (
      result: commandResult,
      view: MultiplayerCommandView(
        clientCommandId: value.clientCommandId,
        initialEventOffset: value.initialEventOffset,
        finalEventOffset: value.finalEventOffset,
        duplicate: value.duplicate,
        accepted: command.accepted,
        rejectionCode: command.rejection?.wireCode,
        projection: projection,
      ),
    );
  }

  static MultiplayerProjectionView _projection({
    required String matchId,
    required String playerId,
    required int eventOffset,
    required AonwPlayerViewSnapshot snapshot,
  }) {
    final stamp = snapshot.stamp;
    _unsigned(stamp.revision, 'revision');
    _identifier(stamp.stateDigest, 'state digest');
    _identifier(stamp.mapHash, 'map hash');
    _identifier(stamp.rulesetHash, 'ruleset hash');
    final lifecycle = snapshot.turnLifecycle;
    if (lifecycle.submittedCount > lifecycle.requiredSubmissionCount) {
      throw const FormatException(
        'Submitted player count exceeds the required count.',
      );
    }
    return MultiplayerProjectionView(
      matchId: matchId,
      playerId: playerId,
      revision: stamp.revision,
      stateDigest: stamp.stateDigest,
      eventOffset: eventOffset,
      turn: snapshot.turn,
      ownTurnState: switch (lifecycle.ownState) {
        AonwPlayerTurnState.active => MultiplayerTurnStateView.active,
        AonwPlayerTurnState.finished => MultiplayerTurnStateView.finished,
        null => null,
      },
      ownSubmitted: lifecycle.ownSubmitted,
      requiredSubmissionCount: lifecycle.requiredSubmissionCount,
      submittedCount: lifecycle.submittedCount,
      visibleUnitCount: snapshot.units.length,
      outcomeCondition: snapshot.outcome.condition.name,
      winnerPlayerId: snapshot.outcome.winnerPlayerId,
    );
  }
}

typedef _DecodedServerCommand = ({
  Map<String, Object?> result,
  MultiplayerCommandView view,
});

typedef _ServerCommandEnvelope = ({
  Map<String, Object?> outcome,
  Map<String, Object?> recipient,
  String playerId,
  String? rejection,
});

_ServerCommandEnvelope _commandEnvelope(server.GameCommandOutcome value) {
  _identifier(value.matchId, 'match id');
  _identifier(value.clientCommandId, 'client command id');
  _unsigned(value.initialEventOffset, 'initial event offset');
  _unsigned(value.finalEventOffset, 'final event offset');
  if (value.finalEventOffset < value.initialEventOffset) {
    throw const FormatException('Command event offsets are reversed.');
  }
  final outcome = _object(jsonDecode(value.outcomeJson), 'command outcome');
  _requireKeys(outcome, const {
    'stamp',
    'rejection',
    'recipient',
  }, 'command outcome');
  final recipient = _object(outcome['recipient'], 'recipient outcome');
  _requireKeys(recipient, const {
    'recipientPlayerId',
    'snapshot',
    'patch',
    'events',
    'evidence',
  }, 'recipient outcome');
  final rejection = outcome['rejection'];
  if (rejection != null && rejection is! String) {
    throw const FormatException('Command rejection code must be a string.');
  }
  return (
    outcome: outcome,
    recipient: recipient,
    playerId: _identifier(
      recipient['recipientPlayerId'],
      'recipient player id',
    ),
    rejection: rejection as String?,
  );
}

String _querySuccessJson(Map<String, Object?> outcome) {
  _requireKeys(outcome, const {'status', 'result'}, 'successful query outcome');
  return _successResponseJson({
    'type': 'query',
    'result': _object(outcome['result'], 'query result'),
  });
}

String _queryFailureJson(Map<String, Object?> outcome) {
  _requireKeys(outcome, const {'status', 'error'}, 'failed query outcome');
  return _clientResponseJson({'status': 'failure', 'error': outcome['error']});
}

String _successResponseJson(Map<String, Object?> response) =>
    _clientResponseJson({'status': 'success', 'response': response});

String _clientResponseJson(Map<String, Object?> outcome) {
  final response = jsonEncode({
    'apiVersion': aonwClientApiVersion,
    'outcome': outcome,
  });
  AonwClientResponse.parse(response);
  return response;
}

Map<String, Object?> _object(Object? value, String label) {
  if (value is Map<String, Object?>) return value;
  throw FormatException('$label must be an object.');
}

void _requireKeys(
  Map<String, Object?> value,
  Set<String> expected,
  String label,
) {
  if (value.keys.toSet().length != expected.length ||
      !value.keys.every(expected.contains)) {
    throw FormatException('$label has an invalid field set.');
  }
}

String _identifier(Object? value, String label) {
  if (value is! String || value.isEmpty || value.length > 256) {
    throw FormatException('$label is invalid.');
  }
  return value;
}

void _unsigned(int value, String label) {
  if (value < 0) throw FormatException('$label must be non-negative.');
}

bool _sameStamp(AonwSessionStamp left, AonwSessionStamp right) =>
    left.revision == right.revision &&
    left.stateDigest == right.stateDigest &&
    left.mapHash == right.mapHash &&
    left.rulesetHash == right.rulesetHash;
