enum TreasuryWarningView { none, negativeBalance, deficitWithinThreeTurns }

enum VictoryStatusKindView { none, conquest, domination, culture, score }

final class VictoryStatusView {
  const VictoryStatusView({
    required this.kind,
    required this.critical,
    required this.leaderPlayerId,
  });

  static const empty = VictoryStatusView(
    kind: VictoryStatusKindView.none,
    critical: false,
    leaderPlayerId: null,
  );

  final VictoryStatusKindView kind;
  final bool critical;
  final String? leaderPlayerId;
}
