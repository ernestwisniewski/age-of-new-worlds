import '../../map/read_model/player_map_view.dart';

enum UnitActionKindView { cancel, skip, fortify }

enum UnitActionRejectionCodeView {
  staleRevision('stale_revision'),
  matchFinished('match_finished'),
  unitNotFound('unit_not_found'),
  unitNotControlled('unit_not_controlled'),
  unitBusy('unit_busy'),
  unitDefinitionMissing('unit_definition_missing'),
  stateRevisionOverflow('state_revision_overflow');

  const UnitActionRejectionCodeView(this.wireCode);

  final String wireCode;
}

final class UnitActionResultView {
  const UnitActionResultView.accepted({
    required this.action,
    required this.unitId,
    required this.player,
  }) : accepted = true,
       rejectionCode = null;

  const UnitActionResultView.rejected({
    required this.action,
    required this.unitId,
    required UnitActionRejectionCodeView code,
  }) : accepted = false,
       rejectionCode = code,
       player = null;

  final UnitActionKindView action;
  final String unitId;
  final bool accepted;
  final UnitActionRejectionCodeView? rejectionCode;
  final PlayerMapView? player;
}
