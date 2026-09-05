import 'package:aonw_engine_client/src/protocol_execution.dart';
import 'package:aonw_engine_client/src/protocol_json.dart';
import 'package:aonw_engine_client/src/protocol_player_view.dart';
import 'package:aonw_engine_client/src/protocol_values.dart';

List<AonwCommandResult> readObservedCommands(
  Object? source,
  int count,
  AonwSessionStamp stamp,
) {
  if (source is! List || source.length != count || source.length > 1024) {
    throw const FormatException('Invalid observed command count.');
  }
  final commands = readList(
    source,
    'observed commands',
    (item, _) => AonwCommandResult.fromJson(item),
  );
  AonwSessionStamp? previous;
  for (final command in commands) {
    _validateCommand(command, stamp);
    if (previous != null) _validateNextCommand(command, previous);
    previous = command.stamp;
  }
  if (previous != null && !_sameStamp(previous, stamp)) {
    throw const FormatException(
      'Observed commands do not reach the final stamp.',
    );
  }
  return commands;
}

void _validateNextCommand(
  AonwCommandResult command,
  AonwSessionStamp previous,
) {
  if (command.viewPatch.fromRevision != previous.revision ||
      (command.stamp.revision == previous.revision &&
          !_sameStamp(command.stamp, previous))) {
    throw const FormatException('Discontinuous observed command frames.');
  }
}

void validateObservedReplay(
  int position,
  int entryCount,
  AonwPlayerViewSnapshot snapshot,
  AonwCommandResult? command,
) {
  if (position > entryCount) {
    throw const FormatException('Replay position exceeds the archive.');
  }
  if (command == null) return;
  _validateCommand(command, snapshot.stamp);
  if (position == 0 ||
      !_sameStamp(command.stamp, snapshot.stamp) ||
      command.viewPatch.turn != snapshot.turn ||
      command.viewPatch.turnMode != snapshot.turnMode) {
    throw const FormatException('Replay command does not match its snapshot.');
  }
}

void _validateCommand(AonwCommandResult command, AonwSessionStamp stamp) {
  final patch = command.viewPatch;
  final difference = patch.toRevision - patch.fromRevision;
  if (command.stamp.revision != patch.toRevision ||
      (difference != 0 && difference != 1) ||
      command.stamp.mapHash != stamp.mapHash ||
      command.stamp.rulesetHash != stamp.rulesetHash) {
    throw const FormatException('Invalid observed command boundary.');
  }
}

bool _sameStamp(AonwSessionStamp left, AonwSessionStamp right) =>
    left.revision == right.revision &&
    left.stateDigest == right.stateDigest &&
    left.mapHash == right.mapHash &&
    left.rulesetHash == right.rulesetHash;
