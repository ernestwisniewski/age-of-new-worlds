import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_panel.dart';
import '../../../l10n/l10n.dart';
import '../../local_game/application/local_ai_turn_state.dart';
import '../application/turn_action_state.dart';
import '../application/turn_presentation_queue.dart';
import '../read_model/recipient_turn_view.dart';
import '../read_model/turn_activity_view.dart';

final class TurnPresentationOverlays extends StatelessWidget {
  const TurnPresentationOverlays({
    required this.turn,
    required this.action,
    required this.presentations,
    required this.onEndTurn,
    required this.localAiTurn,
    super.key,
  });

  final RecipientTurnView turn;
  final TurnActionState action;
  final TurnPresentationQueue presentations;
  final VoidCallback onEndTurn;
  final LocalAiTurnState localAiTurn;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(
        top: AonwSpacing.md,
        left: 72,
        right: 72,
        child: _TurnHud(
          turn: turn,
          action: action,
          localAiTurn: localAiTurn,
          onEndTurn: onEndTurn,
        ),
      ),
      Positioned(
        right: AonwSpacing.md,
        bottom: AonwSpacing.md,
        child: _ActivityPanel(activities: presentations.activities),
      ),
      _TurnNotification(activity: presentations.latestActivity),
    ],
  );
}

final class _TurnHud extends StatelessWidget {
  const _TurnHud({
    required this.turn,
    required this.action,
    required this.onEndTurn,
    required this.localAiTurn,
  });

  final RecipientTurnView turn;
  final TurnActionState action;
  final VoidCallback onEndTurn;
  final LocalAiTurnState localAiTurn;

  @override
  Widget build(BuildContext context) {
    final failure = _turnFailure(context.aonwL10n, action.failure);
    final aiFailure = localAiTurn.failure == null
        ? null
        : context.aonwL10n.aiTurnFailure(localAiTurn.failure!.name);
    return SafeArea(
      child: Center(
        child: AonwPanel(
          maxWidth: 720,
          padding: const EdgeInsets.symmetric(
            horizontal: AonwSpacing.md,
            vertical: AonwSpacing.sm,
          ),
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AonwSpacing.md,
              runSpacing: AonwSpacing.xs,
              children: [
                _TurnSummary(turn: turn),
                _EndTurnAction(
                  turn: turn,
                  action: action,
                  aiTurn: localAiTurn,
                  onPressed: onEndTurn,
                ),
                if (localAiTurn.inFlight)
                  Semantics(
                    liveRegion: true,
                    child: Text(context.aonwL10n.aiTurnRunning),
                  ),
                if (failure != null) _TurnFailure(message: failure),
                if (aiFailure != null) _TurnFailure(message: aiFailure),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _TurnSummary extends StatelessWidget {
  const _TurnSummary({required this.turn});

  final RecipientTurnView turn;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: AonwSpacing.md,
    runSpacing: AonwSpacing.xs,
    children: [
      Text(
        context.aonwL10n.turnSummary('label', turn.number, 0, 0),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      Text(_turnStatus(context.aonwL10n, turn)),
      Text(
        context.aonwL10n.turnSummary(
          'progress',
          turn.number,
          turn.submittedCount,
          turn.requiredSubmissionCount,
        ),
      ),
    ],
  );
}

final class _EndTurnAction extends StatelessWidget {
  const _EndTurnAction({
    required this.turn,
    required this.action,
    required this.onPressed,
    required this.aiTurn,
  });

  final RecipientTurnView turn;
  final TurnActionState action;
  final VoidCallback onPressed;
  final LocalAiTurnState aiTurn;

  @override
  Widget build(BuildContext context) => FocusTraversalOrder(
    order: const NumericFocusOrder(3),
    child: FilledButton.icon(
      key: const ValueKey('end-turn'),
      onPressed: turn.canEndTurn && !action.inFlight && !aiTurn.blocksGameplay
          ? onPressed
          : null,
      icon: action.inFlight || aiTurn.inFlight
          ? const Icon(Icons.hourglass_top)
          : const Icon(Icons.skip_next),
      label: Text(
        action.inFlight || aiTurn.inFlight
            ? context.aonwL10n.turnText('actionEnding')
            : context.aonwL10n.turnText('actionEnd'),
      ),
    ),
  );
}

final class _TurnFailure extends StatelessWidget {
  const _TurnFailure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}

final class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({required this.activities});

  final List<TurnActivityView> activities;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) return const SizedBox.shrink();
    final start = activities.length > 4 ? activities.length - 4 : 0;
    return SafeArea(
      child: AonwPanel(
        maxWidth: 320,
        semanticLabel: context.aonwL10n.turnText('activityTitle'),
        padding: const EdgeInsets.all(AonwSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.aonwL10n.turnText('activityTitle'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AonwSpacing.xs),
            for (final activity in activities.skip(start))
              Text('• ${_activityLabel(context, activity.kind)}'),
          ],
        ),
      ),
    );
  }
}

final class _TurnNotification extends StatelessWidget {
  const _TurnNotification({required this.activity});

  final TurnActivityView? activity;

  @override
  Widget build(BuildContext context) {
    final current = activity;
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: const Alignment(0, 0.74),
          child: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            child: current == null
                ? const SizedBox.shrink()
                : Semantics(
                    key: ValueKey(current.identity),
                    liveRegion: true,
                    child: AonwPanel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AonwSpacing.md,
                        vertical: AonwSpacing.xs,
                      ),
                      child: Text(_activityLabel(context, current.kind)),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

String _turnStatus(AonwLocalizations l10n, RecipientTurnView turn) {
  if (turn.outcome.isTerminal) {
    return l10n.turnText('outcome${_titleCase(turn.outcome.condition.name)}');
  }
  final status = turn.pendingAction != null
      ? 'pendingAction'
      : turn.ownSubmitted
      ? 'submitted'
      : turn.ownState?.name ?? 'waiting';
  return l10n.turnText('status${_titleCase(status)}');
}

String? _turnFailure(AonwLocalizations l10n, TurnActionFailureView? failure) {
  if (failure == null) return null;
  final code = failure.rejectionCode?.wireCode ?? failure.code?.name ?? 'other';
  return l10n.turnFailure(code);
}

String _activityLabel(BuildContext context, TurnActivityKindView kind) =>
    context.aonwL10n.turnText(
      'activity${_titleCase(_activityCategories[kind] ?? 'other')}',
    );

String _titleCase(String value) =>
    '${value.substring(0, 1).toUpperCase()}${value.substring(1)}';

const _activityCategories = <TurnActivityKindView, String>{
  TurnActivityKindView.artifactExcavationStarted: 'artifact',
  TurnActivityKindView.artifactCarried: 'artifact',
  TurnActivityKindView.artifactStored: 'artifact',
  TurnActivityKindView.cityFounded: 'city',
  TurnActivityKindView.cityBuiltBuilding: 'city',
  TurnActivityKindView.cityProducedUnit: 'city',
  TurnActivityKindView.cityBuiltWonder: 'city',
  TurnActivityKindView.wonderProductionRefunded: 'city',
  TurnActivityKindView.cityClaimedHex: 'city',
  TurnActivityKindView.technologyResearched: 'research',
  TurnActivityKindView.researchPointsGained: 'research',
  TurnActivityKindView.stabilityBandChanged: 'objective',
  TurnActivityKindView.mapObjectiveSecured: 'objective',
  TurnActivityKindView.dominationThresholdReached: 'objective',
  TurnActivityKindView.matchEnded: 'outcome',
  TurnActivityKindView.unitAttacked: 'combat',
  TurnActivityKindView.cityAttacked: 'combat',
  TurnActivityKindView.combatResolved: 'combat',
  TurnActivityKindView.unitGainedExperience: 'combat',
  TurnActivityKindView.unitKilled: 'combat',
  TurnActivityKindView.unitRetreated: 'combat',
  TurnActivityKindView.cityCaptured: 'combat',
  TurnActivityKindView.cityDestroyed: 'combat',
  TurnActivityKindView.diplomaticScoreChanged: 'diplomacy',
  TurnActivityKindView.diplomaticProposalSent: 'diplomacy',
  TurnActivityKindView.diplomaticProposalResponded: 'diplomacy',
  TurnActivityKindView.diplomaticProposalExpired: 'diplomacy',
  TurnActivityKindView.diplomaticMessageSent: 'diplomacy',
  TurnActivityKindView.diplomaticMessageResponded: 'diplomacy',
  TurnActivityKindView.diplomaticPromiseBroken: 'diplomacy',
  TurnActivityKindView.diplomaticRelationChanged: 'diplomacy',
  TurnActivityKindView.unitMoved: 'unit',
  TurnActivityKindView.autoExplorePlanned: 'unit',
  TurnActivityKindView.merchantRouteAssigned: 'unit',
  TurnActivityKindView.merchantTravelQueued: 'unit',
  TurnActivityKindView.troopDetached: 'unit',
  TurnActivityKindView.turnEnded: 'turn',
  TurnActivityKindView.allPlayersSubmitted: 'turn',
  TurnActivityKindView.playerTimedOut: 'turn',
  TurnActivityKindView.playerKicked: 'turn',
  TurnActivityKindView.workerCompletedJob: 'worker',
};
