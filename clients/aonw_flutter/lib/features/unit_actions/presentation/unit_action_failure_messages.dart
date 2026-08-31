import '../../../l10n/l10n.dart';
import '../application/action_deck_state.dart';
import '../read_model/unit_action_view.dart';

String unitActionFailureMessage(
  AonwLocalizations l10n,
  UnitActionFailure failure,
) => switch (failure.code) {
  UnitActionFailureViewCode.requestFailed => l10n.unitActionFailure(
    'requestFailed',
  ),
  UnitActionFailureViewCode.responseIncompatible => l10n.unitActionFailure(
    'responseIncompatible',
  ),
  UnitActionFailureViewCode.sessionUnavailable => l10n.unitActionFailure(
    'sessionUnavailable',
  ),
  UnitActionFailureViewCode.rejected => _rejectionMessage(
    l10n,
    failure.rejectionCode!,
  ),
};

String _rejectionMessage(
  AonwLocalizations l10n,
  UnitActionRejectionCodeView code,
) => l10n.unitActionFailure(switch (code) {
  UnitActionRejectionCodeView.staleRevision => 'stale',
  UnitActionRejectionCodeView.matchFinished => 'matchFinished',
  UnitActionRejectionCodeView.unitNotFound ||
  UnitActionRejectionCodeView.unitNotControlled => 'unitUnavailable',
  UnitActionRejectionCodeView.unitBusy => 'unitBusy',
  UnitActionRejectionCodeView.unitDefinitionMissing ||
  UnitActionRejectionCodeView.stateRevisionOverflow => 'internal',
});
