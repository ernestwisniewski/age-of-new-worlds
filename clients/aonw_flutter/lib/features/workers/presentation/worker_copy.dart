import 'package:flutter/widgets.dart';

import '../../../l10n/l10n.dart';
import '../application/worker_state.dart';
import '../read_model/worker_view.dart';

enum WorkerText {
  title,
  loading,
  empty,
  executing,
  buildCharges,
  progress,
  assigned,
  selectImprovement,
  confirmImprovement,
  cancelJob,
  assign,
  cancelAssignment,
  buildRoad,
  automate,
  automationEvidence,
}

final class WorkerCopy {
  const WorkerCopy._(this._l10n);

  factory WorkerCopy.of(BuildContext context) => WorkerCopy._(context.aonwL10n);

  final AonwLocalizations _l10n;

  String text(WorkerText key) => _l10n.workerText(key.name);

  String failure(WorkerFailureView failure) {
    final key = failure.rejectionCode?.name ?? failure.code.name;
    return _l10n.workerFailure(key);
  }

  String improvement(String name) => _l10n.presentationName(name);

  String automationAction(WorkerAutomationActionView action) =>
      switch (action) {
        ImproveWorkerAutomationActionView(improvement: final kind) =>
          improvement(kind.name),
        AssignWorkerAutomationActionView() => text(WorkerText.assign),
      };
}
