import '../../map/read_model/player_map_view.dart';
import 'turn_activity_view.dart';

enum TurnRejectionCodeView {
  staleRevision('stale_revision'),
  matchFinished('match_finished'),
  playerNotControlled('turn_player_not_controlled'),
  playerNotActive('turn_player_not_active'),
  scopeInvalid('turn_scope_invalid'),
  processorUnsupported('turn_processor_unsupported'),
  numberOverflow('turn_number_overflow'),
  stateRevisionOverflow('state_revision_overflow');

  const TurnRejectionCodeView(this.wireCode);

  final String wireCode;
}

final class TurnCommandResultView {
  TurnCommandResultView.accepted({
    required this.player,
    required List<TurnActivityView> activities,
    required this.evidence,
  }) : accepted = true,
       rejectionCode = null,
       activities = List.unmodifiable(activities);

  const TurnCommandResultView.rejected({required TurnRejectionCodeView code})
    : accepted = false,
      rejectionCode = code,
      player = null,
      activities = const [],
      evidence = null;

  final bool accepted;
  final TurnRejectionCodeView? rejectionCode;
  final PlayerMapView? player;
  final List<TurnActivityView> activities;
  final TurnKernelEvidenceView? evidence;
}
