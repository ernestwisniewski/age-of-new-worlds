import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_hud_surface.dart';
import '../../../l10n/l10n.dart';
import '../../local_game/application/local_ai_turn_state.dart';
import '../../map/presentation/input/map_gamepad_navigation.dart';
import '../../map/presentation/widgets/map_gamepad_region.dart';
import '../../map/read_model/player_map_view.dart';
import '../application/turn_action_state.dart';
import '../application/turn_presentation_queue.dart';
import '../read_model/recipient_turn_view.dart';
import '../read_model/turn_activity_view.dart';

part 'turn_end_action.dart';
part 'turn_navigation_actions.dart';

final class TurnPresentationOverlays extends StatelessWidget {
  const TurnPresentationOverlays({
    required this.turn,
    required this.turnMode,
    required this.action,
    required this.presentations,
    required this.onEndTurn,
    this.onNavigateTurn,
    required this.localAiTurn,
    super.key,
  });

  final RecipientTurnView turn;
  final MatchTurnModeView turnMode;
  final TurnActionState action;
  final TurnPresentationQueue presentations;
  final VoidCallback onEndTurn;
  final ValueChanged<int>? onNavigateTurn;
  final LocalAiTurnState localAiTurn;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: _TurnCommandDeck(
          turn: turn,
          turnMode: turnMode,
          action: action,
          localAiTurn: localAiTurn,
          onEndTurn: onEndTurn,
          onNavigateTurn: onNavigateTurn,
        ),
      ),
      _TurnNotification(activity: presentations.latestActivity),
    ],
  );
}

final class _TurnCommandDeck extends StatelessWidget {
  const _TurnCommandDeck({
    required this.turn,
    required this.turnMode,
    required this.action,
    required this.onEndTurn,
    this.onNavigateTurn,
    required this.localAiTurn,
  });

  final RecipientTurnView turn;
  final MatchTurnModeView turnMode;
  final TurnActionState action;
  final VoidCallback onEndTurn;
  final ValueChanged<int>? onNavigateTurn;
  final LocalAiTurnState localAiTurn;

  @override
  Widget build(BuildContext context) {
    final failure = _turnFailure(context.aonwL10n, action.failure);
    final aiFailure = localAiTurn.failure == null
        ? null
        : context.aonwL10n.aiTurnFailure(localAiTurn.failure!.name);
    final size = MediaQuery.sizeOf(context);
    final compactLandscape = size.height < 520 && size.width > size.height;
    return Stack(
      children: [
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compactLandscape
                  ? 64
                  : size.width >= 900
                  ? 16
                  : 10,
              0,
              compactLandscape
                  ? 8
                  : size.width >= 900
                  ? 16
                  : 10,
              compactLandscape ? 6 : 10,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                key: const ValueKey('turn-hud'),
                height: 48,
                child: _command(context),
              ),
            ),
          ),
        ),
        if (failure != null || aiFailure != null)
          Align(
            alignment: const Alignment(0, 0.78),
            child: AonwHudSurface(
              elevation: AonwHudElevation.flat,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: _TurnFailure(message: failure ?? aiFailure!),
            ),
          ),
      ],
    );
  }

  Widget _command(BuildContext context) => FocusTraversalGroup(
    policy: OrderedTraversalPolicy(),
    child: MapGamepadRegion(
      section: MapHudSection.selectionActions,
      bottomCommand: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (turn.requiredSubmissionCount > 1)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Tooltip(
                message: context.aonwL10n.turnSummary(
                  'progress',
                  turn.number,
                  turn.submittedCount,
                  turn.requiredSubmissionCount,
                ),
                child: Text(
                  '${turn.submittedCount} / ${turn.requiredSubmissionCount}',
                  key: const ValueKey('turn-progress'),
                  style: AonwTextStyles.toolbarLabel,
                ),
              ),
            ),
          _EndTurnAction(
            turn: turn,
            turnMode: turnMode,
            action: action,
            aiTurn: localAiTurn,
            onPressed: onEndTurn,
          ),
          if (onNavigateTurn case final navigate?)
            _TurnNavigationActions(
              enabled:
                  !action.inFlight &&
                  !localAiTurn.blocksGameplay &&
                  !turn.outcome.isTerminal &&
                  !turn.ownSubmitted &&
                  turn.ownState == RecipientTurnStateView.active,
              onNavigate: navigate,
            ),
        ],
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
                    child: AonwHudSurface(
                      elevation: AonwHudElevation.floating,
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
