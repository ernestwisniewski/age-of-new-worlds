import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_progress_indicator.dart';
import '../../map/read_model/pending_action_view.dart';
import '../../map/read_model/player_map_view.dart';
import '../application/worker_state.dart';
import '../read_model/worker_view.dart';
import 'worker_copy.dart';

part 'worker_improvement_selection.dart';

final class WorkerPanel extends StatelessWidget {
  const WorkerPanel({
    required this.state,
    this.readOnly = false,
    required this.unit,
    required this.onOpenChanged,
    required this.onPreview,
    required this.onAction,
    this.enabled = true,
    super.key,
  });

  final bool readOnly;
  final WorkerState state;
  final VisibleUnitView unit;
  final ValueChanged<bool> onOpenChanged;
  final ValueChanged<FieldImprovementKind> onPreview;
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
              readOnly: readOnly,
              options: options,
              unit: unit,
              state: state,
              onOpenChanged: onOpenChanged,
              onPreview: onPreview,
              enabled: acceptsInput,
              onAction: onAction,
            ),
          if (state.commandPending)
            AonwProgressIndicator(
              semanticLabel: copy.text(WorkerText.executing),
              compact: true,
            ),
          if (state.lastAutomation case final execution?)
            _AutomationPlan(execution: execution),
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
    required this.state,
    this.readOnly = false,
    required this.unit,
    required this.onOpenChanged,
    required this.onPreview,
    required this.enabled,
    required this.onAction,
  });

  final WorkerOptionsView options;
  final bool readOnly;
  final WorkerState state;
  final VisibleUnitView unit;
  final ValueChanged<bool> onOpenChanged;
  final ValueChanged<FieldImprovementKind> onPreview;
  final bool enabled;
  final ValueChanged<WorkerActionView> onAction;

  bool get _commandsEnabled => enabled && !readOnly;

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
            onPressed: _commandsEnabled ? () => onAction(action) : null,
            icon: Icon(icon),
            label: Text(label),
          ),
        ),
      );
    }

    if (unit.workerJob == null && options.improvements.isNotEmpty) {
      buttons.add(_improvementSelection());
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
        '${copy.automationAction(automation.action)}',
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

  Widget _improvementSelection() => _WorkerImprovementSelection(
    readOnly: readOnly,
    state: state,
    options: options,
    enabled: enabled,
    onOpenChanged: onOpenChanged,
    onPreview: onPreview,
    onAction: onAction,
  );
}

final class _AutomationPlan extends StatelessWidget {
  const _AutomationPlan({required this.execution});

  final WorkerAutomationExecutionView execution;

  @override
  Widget build(BuildContext context) {
    final copy = WorkerCopy.of(context);
    final option = execution.option;
    return Text(
      '${copy.text(WorkerText.plannedWork)}: '
      '${copy.automationAction(option.action)} · '
      '${option.target.col}, ${option.target.row}',
      key: const ValueKey('worker-automation-plan'),
    );
  }
}
