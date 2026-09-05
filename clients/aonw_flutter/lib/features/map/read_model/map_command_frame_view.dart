import 'map_command_animation_view.dart';
import 'player_map_view.dart';

/// The recipient view after one observed command, including ordered feedback.
final class MapCommandFrameView {
  MapCommandFrameView({
    required this.player,
    List<MapCommandAnimationView> animations = const [],
  }) : animations = List.unmodifiable(animations);

  final PlayerMapView player;
  final List<MapCommandAnimationView> animations;
}
