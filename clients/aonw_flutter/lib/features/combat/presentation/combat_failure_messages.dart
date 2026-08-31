import '../../../l10n/generated/aonw_localizations.dart';
import '../application/combat_state.dart';

String combatFailureMessage(
  AonwLocalizations l10n,
  CombatFailureView failure,
) => l10n.unitActionFailure(
  'combatFailure${_upperFirst(failure.rejectionCode?.name ?? failure.code.name)}',
);

String _upperFirst(String value) =>
    '${value.substring(0, 1).toUpperCase()}${value.substring(1)}';
