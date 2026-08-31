import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_hud_surface.dart';
import '../../../l10n/l10n.dart';
import '../../local_game/application/local_ai_turn_state.dart';
import '../application/turn_action_state.dart';
import '../application/turn_presentation_queue.dart';
import '../read_model/recipient_turn_view.dart';
import '../read_model/turn_activity_view.dart';

part 'turn_end_action.dart';

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
      Positioned.fill(child: _TopTurnStrip(turn: turn)),
      Positioned.fill(
        child: _TurnCommandDeck(
          turn: turn,
          action: action,
          localAiTurn: localAiTurn,
          onEndTurn: onEndTurn,
        ),
      ),
      _TurnNotification(activity: presentations.latestActivity),
    ],
  );
}

final class _TopTurnStrip extends StatelessWidget {
  const _TopTurnStrip({required this.turn});

  final RecipientTurnView turn;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(64, 10, 12, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (turn.requiredSubmissionCount > 1) ...[
                  _TurnResourcePill(
                    key: const ValueKey('turn-progress'),
                    compact: compact,
                    icon: Icons.groups_outlined,
                    label: context.aonwL10n.turnSummary(
                      'progress',
                      turn.number,
                      turn.submittedCount,
                      turn.requiredSubmissionCount,
                    ),
                    tooltip: _turnStatus(context.aonwL10n, turn),
                  ),
                  const SizedBox(width: 6),
                ],
                _TurnResourcePill(
                  key: const ValueKey('turn-number'),
                  compact: compact,
                  label: context.aonwL10n.turnSummary(
                    'label',
                    turn.number,
                    0,
                    0,
                  ),
                  tooltip: _turnStatus(context.aonwL10n, turn),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _TurnResourcePill extends StatelessWidget {
  const _TurnResourcePill({
    required this.compact,
    required this.label,
    required this.tooltip,
    this.icon,
    super.key,
  });

  final bool compact;
  final String label;
  final String tooltip;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    triggerMode: TooltipTriggerMode.manual,
    child: Semantics(
      label: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => _showTurnInfo(context),
        child: AonwHudSurface(
          elevation: AonwHudElevation.floating,
          padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9),
          borderRadius: BorderRadius.circular(AonwRadii.pill),
          child: SizedBox(
            height: 34,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon case final icon?) ...[
                  Icon(
                    icon,
                    size: compact ? 12 : 14,
                    color: AonwColorTokens.brand,
                  ),
                  SizedBox(width: compact ? 4 : 5),
                ],
                Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: AonwColorTokens.brandLight,
                    fontFamily: AonwTypography.bodyFamily,
                    fontSize: compact ? 10.5 : 11,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _showTurnInfo(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: AonwHudSurface(
              elevation: AonwHudElevation.raised,
              maxWidth: 520,
              padding: const EdgeInsets.all(AonwSpacing.lg),
              child: Text(tooltip, textAlign: TextAlign.center),
            ),
          ),
        ),
      );
}

final class _TurnCommandDeck extends StatelessWidget {
  const _TurnCommandDeck({
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
                child: FocusTraversalGroup(
                  policy: OrderedTraversalPolicy(),
                  child: _EndTurnAction(
                    turn: turn,
                    action: action,
                    aiTurn: localAiTurn,
                    onPressed: onEndTurn,
                  ),
                ),
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
