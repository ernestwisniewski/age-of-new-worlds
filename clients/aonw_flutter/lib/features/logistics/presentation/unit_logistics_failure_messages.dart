import '../../../l10n/l10n.dart';
import '../application/unit_logistics_state.dart';
import '../read_model/unit_logistics_view.dart';

String unitLogisticsFailureMessage(
  AonwLocalizations l10n,
  UnitLogisticsFailureView failure,
) => l10n.unitActionFailure(_messageKey(failure));

String _messageKey(UnitLogisticsFailureView failure) => switch (failure.code) {
  UnitLogisticsFailureCode.requestFailed => 'logisticsRequestFailed',
  UnitLogisticsFailureCode.responseIncompatible =>
    'logisticsResponseIncompatible',
  UnitLogisticsFailureCode.sessionUnavailable => 'sessionUnavailable',
  UnitLogisticsFailureCode.rejected => _rejectionKey(failure.rejectionCode!),
};

String _rejectionKey(UnitLogisticsRejectionCodeView code) => switch (code) {
  UnitLogisticsRejectionCodeView.staleRevision => 'stale',
  UnitLogisticsRejectionCodeView.matchFinished => 'matchFinished',
  UnitLogisticsRejectionCodeView.unitBusy => 'unitBusy',
  UnitLogisticsRejectionCodeView.unitNotFound ||
  UnitLogisticsRejectionCodeView.unitNotControlled ||
  UnitLogisticsRejectionCodeView.unitUnavailable ||
  UnitLogisticsRejectionCodeView.unitOutOfBounds ||
  UnitLogisticsRejectionCodeView.invalidUnit => 'unitUnavailable',
  _ => 'logisticsOptionUnavailable',
};
