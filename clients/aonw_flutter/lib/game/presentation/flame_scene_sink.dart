import '../../features/map/presentation/map_render_snapshot.dart';
import '../../features/map/read_model/map_view.dart';

/// Narrow presentation boundary used to push immutable state into Flame.
///
/// Implementations must not use this interface to reach repositories, native
/// sessions, wire DTOs, or canonical game rules.
abstract interface class FlameSceneSink {
  void replaceScene(MapRenderSnapshot snapshot);

  void replaceCursor(MapHexCoordinate? coordinate);

  void clearScene();
}
