import '../../features/map/presentation/map_render_snapshot.dart';

/// Narrow presentation boundary used to push immutable state into Flame.
///
/// Implementations must not use this interface to reach repositories, native
/// sessions, wire DTOs, or canonical game rules.
abstract interface class FlameSceneSink {
  void replaceScene(MapRenderSnapshot snapshot);

  void clearScene();
}
