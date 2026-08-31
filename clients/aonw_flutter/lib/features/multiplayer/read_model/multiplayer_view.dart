enum NetworkSessionPhase { ready, reconnecting, resyncing, failed, closed }

final class MultiplayerAccountView {
  const MultiplayerAccountView({required this.userId});

  final String userId;
}

final class MultiplayerMatchView {
  const MultiplayerMatchView({
    required this.matchId,
    required this.mapId,
    required this.mapHash,
    required this.rulesetId,
    required this.rulesetHash,
    required this.revision,
    required this.eventOffset,
  });

  final String matchId;
  final String mapId;
  final String mapHash;
  final String rulesetId;
  final String rulesetHash;
  final int revision;
  final int eventOffset;
}

enum MultiplayerTurnStateView { active, finished }

final class MultiplayerProjectionView {
  const MultiplayerProjectionView({
    required this.matchId,
    required this.playerId,
    required this.revision,
    required this.stateDigest,
    required this.eventOffset,
    required this.turn,
    required this.ownTurnState,
    required this.ownSubmitted,
    required this.requiredSubmissionCount,
    required this.submittedCount,
    required this.visibleUnitCount,
    required this.outcomeCondition,
    required this.winnerPlayerId,
  });

  final String matchId;
  final String playerId;
  final int revision;
  final String stateDigest;
  final int eventOffset;
  final int turn;
  final MultiplayerTurnStateView? ownTurnState;
  final bool ownSubmitted;
  final int requiredSubmissionCount;
  final int submittedCount;
  final int visibleUnitCount;
  final String outcomeCondition;
  final String? winnerPlayerId;

  bool get canSubmitTurn =>
      outcomeCondition == 'ongoing' &&
      ownTurnState == MultiplayerTurnStateView.active &&
      !ownSubmitted;
}

final class MultiplayerCommandView {
  const MultiplayerCommandView({
    required this.clientCommandId,
    required this.initialEventOffset,
    required this.finalEventOffset,
    required this.duplicate,
    required this.accepted,
    required this.rejectionCode,
    required this.projection,
  });

  final String clientCommandId;
  final int initialEventOffset;
  final int finalEventOffset;
  final bool duplicate;
  final bool accepted;
  final String? rejectionCode;
  final MultiplayerProjectionView projection;
}

final class MultiplayerMatchDocuments {
  const MultiplayerMatchDocuments({
    required this.mapId,
    required this.mapDocument,
    required this.scenarioDocument,
    required this.rulesetId,
    required this.matchIdentityDocument,
    required this.fogEnabled,
    required this.creatorPlayerId,
  });

  final String mapId;
  final String mapDocument;
  final String scenarioDocument;
  final String rulesetId;
  final String matchIdentityDocument;
  final bool fogEnabled;
  final String creatorPlayerId;
}
