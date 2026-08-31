import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_hud_surface.dart';
import '../../../design_system/widgets/aonw_panel.dart';
import '../../../l10n/l10n.dart';
import '../../map/read_model/map_view.dart';
import '../../turns/read_model/recipient_turn_view.dart';

final class ObjectiveOverlay extends StatelessWidget {
  const ObjectiveOverlay({
    required this.objectives,
    required this.outcome,
    required this.open,
    required this.onOpenChanged,
    super.key,
  });

  final List<MapObjectiveView> objectives;
  final GameOutcomeView outcome;
  final bool open;
  final ValueChanged<bool>? onOpenChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Stack(
      children: [
        if (!outcome.isTerminal)
          Positioned(
            top: AonwHudSideMenuLayout.actionTop(context, 0),
            left: AonwHudSideMenuLayout.left(context),
            child: AonwHudIconButton(
              key: const ValueKey('open-objectives'),
              tooltip: l10n.openObjectives,
              onPressed: onOpenChanged == null
                  ? null
                  : () => onOpenChanged!(!open),
              active: open,
              icon: const Icon(Icons.flag),
            ),
          ),
        if (open && !outcome.isTerminal)
          Positioned(
            top: AonwHudSideMenuLayout.top(context),
            left: AonwHudSideMenuLayout.panelLeft(context),
            bottom: AonwSpacing.md,
            child: SafeArea(
              child: _ObjectivePanel(
                objectives: objectives,
                onClose: () => onOpenChanged?.call(false),
              ),
            ),
          ),
        if (outcome.isTerminal)
          Positioned.fill(child: _TerminalOutcome(outcome: outcome)),
      ],
    );
  }
}

final class _ObjectivePanel extends StatelessWidget {
  const _ObjectivePanel({required this.objectives, required this.onClose});

  final List<MapObjectiveView> objectives;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return AonwPanel(
      semanticLabel: l10n.objectivesTitle,
      maxWidth: 520,
      child: SizedBox(
        width: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.objectivesTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  key: const ValueKey('close-objectives'),
                  tooltip: l10n.closeObjectives,
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(l10n.objectivesAuthoredRules),
            const SizedBox(height: AonwSpacing.sm),
            Expanded(
              child: objectives.isEmpty
                  ? Center(child: Text(l10n.objectivesEmpty))
                  : ListView.builder(
                      key: const ValueKey('objective-list'),
                      itemCount: objectives.length,
                      itemBuilder: (context, index) =>
                          _ObjectiveCard(objective: objectives[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ObjectiveCard extends StatelessWidget {
  const _ObjectiveCard({required this.objective});

  final MapObjectiveView objective;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Card.outlined(
      key: ValueKey(('objective', objective.id)),
      child: ListTile(
        leading: const Icon(Icons.flag_outlined),
        title: Text(l10n.objectiveType(objective.type.name)),
        subtitle: Text(
          l10n.objectiveDetails(
            objective.coordinate.col,
            objective.coordinate.row,
            objective.requiredHoldTurns,
            objective.victoryPoints,
            objective.goldPerTurn,
          ),
        ),
      ),
    );
  }
}

final class _TerminalOutcome extends StatelessWidget {
  const _TerminalOutcome({required this.outcome});

  final GameOutcomeView outcome;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final scores = outcome.scoreByPlayerId.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return Stack(
      key: const ValueKey('terminal-outcome'),
      children: [
        const ModalBarrier(dismissible: false, color: Color(0xB3000000)),
        Center(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AonwSpacing.lg),
              child: AonwPanel(
                semanticLabel: l10n.matchFinishedTitle,
                liveRegion: true,
                maxWidth: 560,
                padding: const EdgeInsets.all(AonwSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      outcome.winnerPlayerId == null
                          ? Icons.balance
                          : Icons.emoji_events,
                      size: 48,
                    ),
                    const SizedBox(height: AonwSpacing.sm),
                    Text(
                      l10n.matchFinishedTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      l10n.turnText(
                        'outcome${_titleCase(outcome.condition.name)}',
                      ),
                      key: const ValueKey('outcome-condition'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AonwSpacing.md),
                    Text(
                      outcome.winnerPlayerId == null
                          ? l10n.outcomeNoWinner
                          : l10n.outcomeWinner(outcome.winnerPlayerId!),
                      key: const ValueKey('outcome-winner'),
                      textAlign: TextAlign.center,
                    ),
                    if (scores.isNotEmpty) ...[
                      const SizedBox(height: AonwSpacing.lg),
                      Text(
                        l10n.outcomeFinalScore,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      for (final score in scores)
                        Text(
                          l10n.outcomeScoreLine(score.key, score.value),
                          key: ValueKey(('outcome-score', score.key)),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _titleCase(String value) =>
    '${value.substring(0, 1).toUpperCase()}${value.substring(1)}';
