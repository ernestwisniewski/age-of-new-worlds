import 'dart:convert';

import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as server;

import '../read_model/multiplayer_view.dart';

final class ServerProjectionDecoder {
  const ServerProjectionDecoder();

  MultiplayerProjectionView resync(server.GameResync value) {
    _identifier(value.matchId, 'match id');
    _identifier(value.playerId, 'player id');
    _unsigned(value.eventOffset, 'event offset');
    final snapshot = AonwPlayerViewSnapshot.fromJson(
      jsonDecode(value.snapshotJson),
    );
    return _projection(
      matchId: value.matchId,
      playerId: value.playerId,
      eventOffset: value.eventOffset,
      snapshot: snapshot,
    );
  }

  MultiplayerCommandView command(server.GameCommandOutcome value) {
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
    final playerId = _identifier(
      recipient['recipientPlayerId'],
      'recipient player id',
    );
    final rejection = outcome['rejection'];
    if (rejection != null && rejection is! String) {
      throw const FormatException('Command rejection code must be a string.');
    }
    final command = AonwCommandResult.fromJson({
      'stamp': outcome['stamp'],
      'outcome': rejection == null
          ? const {'status': 'accepted'}
          : {'status': 'rejected', 'code': rejection},
      'events': recipient['events'],
      'evidence': recipient['evidence'],
      'viewPatch': recipient['patch'],
    });
    final snapshot = AonwPlayerViewSnapshot.fromJson(recipient['snapshot']);
    if (!_sameStamp(command.stamp, snapshot.stamp) ||
        command.viewPatch.toRevision != snapshot.stamp.revision) {
      throw const FormatException(
        'Command snapshot, patch, and stamp do not identify one revision.',
      );
    }
    final projection = _projection(
      matchId: value.matchId,
      playerId: playerId,
      eventOffset: value.finalEventOffset,
      snapshot: snapshot,
    );
    return MultiplayerCommandView(
      clientCommandId: value.clientCommandId,
      initialEventOffset: value.initialEventOffset,
      finalEventOffset: value.finalEventOffset,
      duplicate: value.duplicate,
      accepted: command.accepted,
      rejectionCode: command.rejection?.wireCode,
      projection: projection,
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
