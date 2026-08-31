import '../../../../l10n/l10n.dart';
import '../../application/game_session_state.dart';
import '../../application/map_interaction_state.dart';
import '../../read_model/movement_view.dart';

String mapFailureMessage(AonwLocalizations l10n, MapLoadFailureViewCode code) =>
    switch (code) {
      MapLoadFailureViewCode.adapterUnavailable => l10n.mapAdapterUnavailable,
      MapLoadFailureViewCode.incompatibleClient => l10n.mapClientIncompatible,
      MapLoadFailureViewCode.loadSuperseded => l10n.mapLoadSuperseded,
      MapLoadFailureViewCode.mapUnavailable => l10n.mapLoadFailure,
    };

String movementFailureMessage(
  AonwLocalizations l10n,
  MapMovementFailure failure,
) => switch (failure.code) {
  MapMovementFailureViewCode.requestFailed => l10n.movementRequestFailed,
  MapMovementFailureViewCode.responseIncompatible =>
    l10n.movementResponseIncompatible,
  MapMovementFailureViewCode.sessionUnavailable =>
    l10n.movementSessionUnavailable,
  MapMovementFailureViewCode.moveRejected => _moveRejectionMessage(
    l10n,
    failure.rejectionCode!,
  ),
};

String _moveRejectionMessage(
  AonwLocalizations l10n,
  CommandRejectionCodeView code,
) {
  final category = _moveRejectionCategories[code];
  if (category == null) throw StateError('Unmapped move rejection: $code');
  return switch (category) {
    _MoveRejectionCategory.stale => l10n.moveRejectedStale,
    _MoveRejectionCategory.unitUnavailable => l10n.moveRejectedUnitUnavailable,
    _MoveRejectionCategory.unitBusy => l10n.moveRejectedUnitBusy,
    _MoveRejectionCategory.targetUnavailable =>
      l10n.moveRejectedTargetUnavailable,
    _MoveRejectionCategory.movementInsufficient =>
      l10n.moveRejectedMovementInsufficient,
    _MoveRejectionCategory.pathUnavailable => l10n.moveRejectedPathUnavailable,
    _MoveRejectionCategory.internal => l10n.moveRejectedInternal,
  };
}

enum _MoveRejectionCategory {
  stale,
  unitUnavailable,
  unitBusy,
  targetUnavailable,
  movementInsufficient,
  pathUnavailable,
  internal,
}

const _moveRejectionCategories =
    <CommandRejectionCodeView, _MoveRejectionCategory>{
      CommandRejectionCodeView.staleRevision: _MoveRejectionCategory.stale,
      CommandRejectionCodeView.unitNotFound:
          _MoveRejectionCategory.unitUnavailable,
      CommandRejectionCodeView.unitNotControlled:
          _MoveRejectionCategory.unitUnavailable,
      CommandRejectionCodeView.unitUnavailable:
          _MoveRejectionCategory.unitUnavailable,
      CommandRejectionCodeView.unitOutOfBounds:
          _MoveRejectionCategory.unitUnavailable,
      CommandRejectionCodeView.unitUsesTradeRoutes:
          _MoveRejectionCategory.unitBusy,
      CommandRejectionCodeView.unitBusy: _MoveRejectionCategory.unitBusy,
      CommandRejectionCodeView.moveTargetOutOfBounds:
          _MoveRejectionCategory.targetUnavailable,
      CommandRejectionCodeView.moveTargetIsCurrentTile:
          _MoveRejectionCategory.targetUnavailable,
      CommandRejectionCodeView.moveTargetIsForeignCityCenter:
          _MoveRejectionCategory.targetUnavailable,
      CommandRejectionCodeView.moveTargetOccupied:
          _MoveRejectionCategory.targetUnavailable,
      CommandRejectionCodeView.unitMovementCapacityInsufficient:
          _MoveRejectionCategory.movementInsufficient,
      CommandRejectionCodeView.movePathNotFound:
          _MoveRejectionCategory.pathUnavailable,
      CommandRejectionCodeView.unitDefinitionMissing:
          _MoveRejectionCategory.internal,
      CommandRejectionCodeView.stateRevisionOverflow:
          _MoveRejectionCategory.internal,
      CommandRejectionCodeView.invalidQueuedMovementPath:
          _MoveRejectionCategory.internal,
      CommandRejectionCodeView.invalidUnit: _MoveRejectionCategory.internal,
      CommandRejectionCodeView.movementUnitUpdateFailed:
          _MoveRejectionCategory.internal,
    };
