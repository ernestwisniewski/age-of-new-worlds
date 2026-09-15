part of 'resource_details.dart';

List<ResourceDetail> _scienceDetails(
  PlayerMapView player,
  AonwLocalizations l10n,
) {
  final research = player.research;
  return [
    _detail(l10n, 'science', signedResourceAmount(research.sciencePerTurn)),
    _detail(l10n, 'overflow', research.scienceOverflow),
    if (research.activeTechnologyId case final technology?) ...[
      _detail(l10n, 'activeResearch', l10n.technologyName(technology)),
      (
        label: l10n.researchText('progress'),
        warning: false,
        value: '${research.activeProgress} / ${research.activeEffectiveCost}',
      ),
    ],
    for (final source in research.scienceSources)
      (
        label:
            '${_cityName(player, source.cityId, l10n)} · ${l10n.resourceText(_scienceSource(source.kind))}',
        warning: false,
        value: signedResourceAmount(source.amount),
      ),
  ];
}

String _scienceSource(PlayerScienceYieldSourceKindView kind) => switch (kind) {
  PlayerScienceYieldSourceKindView.cityScience => 'cities',
  PlayerScienceYieldSourceKindView.cityResearchProject => 'projectIncome',
  PlayerScienceYieldSourceKindView.worldArtifact => 'artifacts',
  PlayerScienceYieldSourceKindView.worldWonder => 'wonders',
};

List<ResourceDetail> _turnDetails(
  PlayerMapView player,
  AonwLocalizations l10n,
) => [
  _detail(l10n, 'turn', player.turnView.number),
  (
    label: l10n.turnModeTitle,
    value: l10n.turnModeName(player.turnMode.name),
    warning: false,
  ),
  _detail(l10n, 'submitted', player.turnView.submittedCount),
  _detail(l10n, 'required', player.turnView.requiredSubmissionCount),
  if (player.victory.remainingTurns case final turns?)
    _detail(l10n, 'remainingTurns', turns),
];

List<ResourceDetail> _victoryDetails(
  PlayerMapView player,
  AonwLocalizations l10n,
) {
  final victory = player.victory;
  return [
    ..._victoryStatusDetails(player, l10n),
    for (final participant in player.participants)
      if (victory.scoreByPlayerId[participant.id] case final score?)
        (
          label: '${participant.name} · ${l10n.resourceText('score')}',
          warning: false,
          value: '$score',
        ),
    if (victory.conquestEnabled) _detail(l10n, 'conquest', '✓'),
    if (victory.dominationEnabled) ...[
      _detail(
        l10n,
        'domination',
        '${victory.dominationRequiredControlPercent}%',
      ),
      for (final progress in victory.domination)
        if (progress.playerId == player.actorPlayerId) ...[
          _detail(
            l10n,
            'domination',
            '${progress.controlledPassableHexes} / ${progress.totalPassableHexes}',
          ),
          _detail(
            l10n,
            'holdTurns',
            '${progress.holdTurns} / ${victory.dominationRequiredHoldTurns}',
          ),
        ],
    ],
    if (victory.culturalEnabled) ...[
      _detail(
        l10n,
        'culture',
        '${victory.ownCultural.uniqueStoredArtifacts} / ${victory.culturalRequiredArtifacts}',
      ),
      _detail(
        l10n,
        'holdTurns',
        '${victory.ownCultural.holdTurns} / ${victory.culturalRequiredHoldTurns}',
      ),
    ],
    if (victory.turnLimit case final turns?) _detail(l10n, 'turnLimit', turns),
    if (victory.remainingTurns case final turns?)
      _detail(l10n, 'remainingTurns', turns),
  ];
}

List<ResourceDetail> _victoryStatusDetails(
  PlayerMapView player,
  AonwLocalizations l10n,
) {
  final victory = player.victory;
  final leader = player.participants
      .where((entry) => entry.id == victory.status.leaderPlayerId)
      .firstOrNull;
  return [
    _detail(l10n, 'victory', victoryStatusLabel(victory.status, victory, l10n)),
    if (victory.status.critical)
      _detail(l10n, 'warning', l10n.resourceText('victoryCritical')),
    if (leader != null) _detail(l10n, 'leader', leader.name),
  ];
}
