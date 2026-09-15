import '../../../l10n/l10n.dart';
import '../../map/read_model/player_victory_view.dart';

String victoryStatusLabel(
  VictoryStatusView status,
  PlayerVictoryView victory,
  AonwLocalizations l10n, {
  bool compact = false,
}) => switch (status.kind) {
  VictoryStatusKindView.none => compact ? '—' : l10n.resourceText('noVictory'),
  VictoryStatusKindView.conquest => l10n.resourceText(
    compact ? 'goalCompact' : 'conquest',
  ),
  VictoryStatusKindView.culture => l10n.resourceText('culture'),
  VictoryStatusKindView.score =>
    compact
        ? _scoreCompact(victory.remainingTurns, l10n)
        : '${l10n.resourceText('remainingTurns')}: ${victory.remainingTurns}',
  VictoryStatusKindView.domination => _dominationLabel(
    status,
    victory,
    l10n,
    compact,
  ),
};

String _dominationLabel(
  VictoryStatusView status,
  PlayerVictoryView victory,
  AonwLocalizations l10n,
  bool compact,
) {
  final leader = victory.domination
      .where((entry) => entry.playerId == status.leaderPlayerId)
      .firstOrNull;
  if (leader == null || leader.totalPassableHexes == 0) {
    return l10n.resourceText('domination');
  }
  final percent =
      leader.controlledPassableHexes / leader.totalPassableHexes * 100;
  final value = '${percent.toStringAsFixed(0)}%';
  return compact ? value : '${l10n.resourceText('domination')}: $value';
}

String _scoreCompact(int? turns, AonwLocalizations l10n) => switch (turns) {
  null => l10n.resourceText('score'),
  0 => l10n.resourceText('scoreCapCompact'),
  _ => l10n.resourceTurnsCompact(turns),
};
