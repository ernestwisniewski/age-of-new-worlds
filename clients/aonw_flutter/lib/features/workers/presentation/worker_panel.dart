import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_progress_indicator.dart';
import '../../map/read_model/pending_action_view.dart';
import '../../map/read_model/player_map_view.dart';
import '../application/worker_state.dart';
import '../read_model/worker_view.dart';
import 'worker_copy.dart';

final class WorkerPanel extends StatelessWidget {
  const WorkerPanel({
    required this.state,
    required this.unit,
    required this.pendingAction,
    required this.onAction,
    this.enabled = true,
    super.key,
  });

  final WorkerState state;
  final VisibleUnitView unit;
  final PendingWorkerActionSelectionView? pendingAction;
  final ValueChanged<WorkerActionView> onAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final copy = WorkerCopy.of(context);
    final acceptsInput = enabled && !state.loading && !state.commandPending;
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AonwSpacing.md),
          Text(
            copy.text(WorkerText.title),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Text(
            '${copy.text(WorkerText.buildCharges)}: ${unit.workerBuildCharges}',
          ),
          if (unit.workerJob case final job?) _WorkerJobProgress(job: job),
          if (unit.workerAssignment case final assignment?)
            Text(
              '${copy.text(WorkerText.assigned)}: ${assignment.col}, ${assignment.row}',
            ),
          if (state.loading)
            AonwProgressIndicator(
              semanticLabel: copy.text(WorkerText.loading),
              compact: true,
            )
          else if (state.options case final options?)
            _WorkerActions(
              options: options,
              unit: unit,
              pendingAction: pendingAction,
              enabled: acceptsInput,
              onAction: onAction,
            ),
          if (state.commandPending)
            AonwProgressIndicator(
              semanticLabel: copy.text(WorkerText.executing),
              compact: true,
            ),
          if (state.lastAutomation case final execution?)
            _AutomationEvidence(execution: execution),
          if (state.failure case final failure?)
            Text(
              copy.failure(failure),
              key: const ValueKey('worker-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}

final class _WorkerJobProgress extends StatelessWidget {
  const _WorkerJobProgress({required this.job});

  final WorkerJobView job;

  @override
  Widget build(BuildContext context) {
    final copy = WorkerCopy.of(context);
    final complete = job.totalTurns - job.remainingTurns;
    return Semantics(
      label: copy.text(WorkerText.progress),
      value: '$complete / ${job.totalTurns}',
      child: Text(
        '${copy.text(WorkerText.progress)}: $complete / ${job.totalTurns}',
        key: const ValueKey('worker-job-progress'),
      ),
    );
  }
}

final class _WorkerActions extends StatelessWidget {
  const _WorkerActions({
    required this.options,
    required this.unit,
    required this.pendingAction,
    required this.enabled,
    required this.onAction,
  });

  final WorkerOptionsView options;
  final VisibleUnitView unit;
  final PendingWorkerActionSelectionView? pendingAction;
  final bool enabled;
  final ValueChanged<WorkerActionView> onAction;

  @override
  Widget build(BuildContext context) {
    final copy = WorkerCopy.of(context);
    final buttons = <Widget>[];
    var order = 20.0;
    void add(WorkerActionView action, String label, IconData icon) {
      buttons.add(
        FocusTraversalOrder(
          order: NumericFocusOrder(order++),
          child: OutlinedButton.icon(
            key: ValueKey(('worker-action', action.runtimeType, label)),
            onPressed: enabled ? () => onAction(action) : null,
            icon: Icon(icon),
            label: Text(label),
          ),
        ),
      );
    }

    final pending = pendingAction;
    if (pending?.unitId == options.unitId && pending?.improvement != null) {
      add(
        ConfirmWorkerImprovementActionView(
          unitId: options.unitId,
          improvement: pending!.improvement!,
        ),
        '${copy.text(WorkerText.confirmImprovement)} · '
        '${copy.improvement(pending.improvement!.name)}',
        Icons.check_circle_outline,
      );
    } else {
      for (final option in options.improvements) {
        add(
          SelectWorkerImprovementActionView(
            unitId: options.unitId,
            improvement: option.improvement,
          ),
          '${copy.text(WorkerText.selectImprovement)} '
          '${copy.improvement(option.improvement.name)} '
          '(${option.buildTurns})',
          Icons.handyman_outlined,
        );
      }
    }
    if (unit.workerJob != null) {
      add(
        CancelWorkerJobActionView(unitId: options.unitId),
        copy.text(WorkerText.cancelJob),
        Icons.cancel_outlined,
      );
    }
    if (options.canAssign) {
      add(
        AssignWorkerToHexActionView(unitId: options.unitId),
        copy.text(WorkerText.assign),
        Icons.person_pin_circle_outlined,
      );
    }
    if (unit.workerAssignment != null) {
      add(
        CancelWorkerAssignmentActionView(unitId: options.unitId),
        copy.text(WorkerText.cancelAssignment),
        Icons.person_off_outlined,
      );
    }
    if (options.canBuildRoad) {
      add(
        BuildRoadActionView(unitId: options.unitId),
        copy.text(WorkerText.buildRoad),
        Icons.add_road,
      );
    }
    if (options.automation case final automation?) {
      add(
        AutomateWorkerActionView(unitId: options.unitId, option: automation),
        '${copy.text(WorkerText.automate)} · '
        '${automation.target.col}, ${automation.target.row} · '
        '${copy.automationAction(automation.action)} '
        '(${automation.movementCostUnits})',
        Icons.auto_fix_high_outlined,
      );
    }
    return buttons.isEmpty
        ? Text(copy.text(WorkerText.empty))
        : Wrap(
            spacing: AonwSpacing.xs,
            runSpacing: AonwSpacing.xs,
            children: buttons,
          );
  }
}

final class _AutomationEvidence extends StatelessWidget {
  const _AutomationEvidence({required this.execution});

  final WorkerAutomationExecutionView execution;

  @override
  Widget build(BuildContext context) {
    final copy = WorkerCopy.of(context);
    final metrics = execution.option.metrics;
    return Text(
      '${copy.text(WorkerText.automationEvidence)}: '
      '${metrics.tilesExamined} / ${metrics.legalityEvaluations} / '
      '${metrics.routesPlanned}',
      key: const ValueKey('worker-automation-evidence'),
    );
  }
}
