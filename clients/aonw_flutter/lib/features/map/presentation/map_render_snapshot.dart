import '../application/map_interaction_state.dart';
import '../read_model/map_command_frame_view.dart';
import '../read_model/map_reference_bundle.dart';
import '../read_model/map_view.dart';
import '../read_model/map_view_mode.dart';
import '../read_model/player_map_view.dart';
import 'map_action_palette_view.dart';
import 'map_feedback_labels.dart';

final class MapRenderSnapshot {
  const MapRenderSnapshot({
    required this.map,
    required this.interaction,
    required this.reference,
    required this.player,
    this.actionPalette,
    this.feedbackLabels = const MapFeedbackLabels.empty(),
    this.commandFrame,
    this.effectEpoch = 0,
  });

  final MapView map;
  final MapInteractionState interaction;
  final MapReferenceBundle reference;
  final PlayerMapView player;
  final MapActionPaletteView? actionPalette;
  final MapFeedbackLabels feedbackLabels;
  final MapCommandFrameView? commandFrame;
  final int effectEpoch;

  MapViewMode get effectiveViewMode => interaction.viewMode.effectiveFor(
    hasReference: reference.pages.isNotEmpty,
  );
}
