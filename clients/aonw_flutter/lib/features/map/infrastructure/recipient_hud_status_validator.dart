import 'package:aonw_engine_client/aonw_engine_client.dart';

void validateVictoryStatus(
  AonwPlayerVictoryView victory,
  Set<String> participants,
) {
  final status = victory.status;
  final leader = status.leaderPlayerId;
  if (leader != null && !participants.contains(leader)) {
    throw const FormatException('Victory status leader is not a participant.');
  }
  if (!_statusEnabled(victory) || !_statusLeaderValid(victory)) {
    throw const FormatException('Victory status disclosure is inconsistent.');
  }
}

bool _statusEnabled(AonwPlayerVictoryView victory) =>
    switch (victory.status.kind) {
      AonwVictoryStatusKind.culture => victory.culturalEnabled,
      AonwVictoryStatusKind.domination => victory.dominationEnabled,
      AonwVictoryStatusKind.score => victory.remainingTurns != null,
      AonwVictoryStatusKind.conquest => victory.conquestEnabled,
      _ => true,
    };

bool _statusLeaderValid(AonwPlayerVictoryView victory) {
  final status = victory.status;
  final leader = status.leaderPlayerId;
  return switch (status.kind) {
    AonwVictoryStatusKind.none ||
    AonwVictoryStatusKind.conquest => leader == null && !status.critical,
    AonwVictoryStatusKind.culture => leader != null,
    AonwVictoryStatusKind.domination => victory.domination.any(
      (entry) => entry.playerId == leader,
    ),
    AonwVictoryStatusKind.score =>
      leader == null || victory.scoreByPlayerId.containsKey(leader),
  };
}

void validateStrategicShortages(List<AonwResourceType> resources) {
  var previous = -1;
  for (final resource in resources) {
    if ((resource != AonwResourceType.oil &&
            resource != AonwResourceType.aluminium) ||
        resource.index <= previous) {
      throw const FormatException('Strategic resource shortages are invalid.');
    }
    previous = resource.index;
  }
}

void validateVictoryStatusRecipient(AonwVictoryStatus status, String actor) {
  if (status.kind == AonwVictoryStatusKind.culture &&
      status.leaderPlayerId != actor) {
    throw const FormatException(
      'Cultural status must belong to the recipient.',
    );
  }
}
