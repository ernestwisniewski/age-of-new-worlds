import 'player_map_view.dart';

/// The recipient view after one observed command, including ordered feedback.
final class MapCommandFrameView {
  const MapCommandFrameView({required this.player});

  final PlayerMapView player;
}
