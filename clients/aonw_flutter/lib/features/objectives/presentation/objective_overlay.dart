import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_hud_surface.dart';
import '../../../design_system/widgets/aonw_panel.dart';
import '../../../l10n/l10n.dart';
import '../../map/presentation/input/map_gamepad_navigation.dart';
import '../../map/presentation/widgets/map_gamepad_region.dart';
import '../../map/read_model/map_view.dart';
import '../../map/read_model/player_victory_view.dart';
import '../../turns/read_model/recipient_turn_view.dart';

import 'match_outcome_overlay.dart';

final class ObjectiveOverlay extends StatelessWidget {
  const ObjectiveOverlay({
    required this.objectives,
    required this.progress,
    required this.playerNames,
    required this.outcome,
    required this.open,
    required this.onOpenChanged,
    this.showOutcome = true,
    super.key,
  });

  final List<MapObjectiveView> objectives;
  final List<MapObjectiveProgressView> progress;
  final Map<String, String> playerNames;
  final GameOutcomeView outcome;
  final bool open;
  final bool showOutcome;
  final ValueChanged<bool>? onOpenChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final blockingOutcome = showOutcome && outcome.isTerminal;
    return Stack(
      children: [
        if (!blockingOutcome)
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
        if (open && !blockingOutcome)
          Positioned(
            top: AonwHudSideMenuLayout.top(context),
            left: AonwHudSideMenuLayout.panelLeft(context),
            bottom: AonwSpacing.md,
            width: math.max(
              0,
              math.min(
                520,
                MediaQuery.sizeOf(context).width -
                    MediaQuery.paddingOf(context).right -
                    AonwHudSideMenuLayout.panelLeft(context) -
                    AonwSpacing.md,
              ),
            ),
            child: MapGamepadRegion(
              section: MapHudSection.globalActions,
              priority: MapGamepadPriority.panel,
              onCancel: () => onOpenChanged?.call(false),
              child: SafeArea(
                child: _ObjectivePanel(
                  objectives: objectives,
                  progress: progress,
                  playerNames: playerNames,
                  onClose: () => onOpenChanged?.call(false),
                ),
              ),
            ),
          ),
        if (blockingOutcome)
          Positioned.fill(
            child: MatchOutcomeOverlay(
              outcome: outcome,
              playerNames: playerNames,
            ),
          ),
      ],
    );
  }
}

final class _ObjectivePanel extends StatelessWidget {
  const _ObjectivePanel({
    required this.objectives,
    required this.progress,
    required this.playerNames,
    required this.onClose,
  });

  final List<MapObjectiveView> objectives;
  final List<MapObjectiveProgressView> progress;
  final Map<String, String> playerNames;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return AonwPanel(
      semanticLabel: l10n.objectivesTitle,
      maxWidth: 520,
      child: CustomScrollView(
        key: const ValueKey('objective-list'),
        slivers: [
          SliverToBoxAdapter(
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
              ],
            ),
          ),
          if (objectives.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(l10n.objectivesEmpty)),
            )
          else
            SliverList.builder(
              itemCount: objectives.length,
              itemBuilder: (context, index) => _ObjectiveCard(
                objective: objectives[index],
                progress: progress
                    .where((value) => value.objectiveId == objectives[index].id)
                    .firstOrNull,
                playerNames: playerNames,
              ),
            ),
        ],
      ),
    );
  }
}

final class _ObjectiveCard extends StatelessWidget {
  const _ObjectiveCard({
    required this.objective,
    required this.progress,
    required this.playerNames,
  });

  final MapObjectiveView objective;
  final MapObjectiveProgressView? progress;
  final Map<String, String> playerNames;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final controllerName = playerNames[progress?.controllerPlayerId];
    return Card.outlined(
      key: ValueKey(('objective', objective.id)),
      child: ListTile(
        leading: const Icon(Icons.flag_outlined),
        title: Text(l10n.objectiveType(objective.type.name)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.objectiveDetails(
                objective.coordinate.col,
                objective.coordinate.row,
                objective.requiredHoldTurns,
                objective.victoryPoints,
                objective.goldPerTurn,
              ),
            ),
            if (progress case final current?)
              Padding(
                padding: const EdgeInsets.only(top: AonwSpacing.xs),
                child: Text(
                  controllerName != null
                      ? l10n.objectiveControlProgress(
                          controllerName,
                          current.holdTurns,
                          objective.requiredHoldTurns,
                        )
                      : l10n.objectiveControlUnknown,
                  key: ValueKey(('objective-progress', objective.id)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
