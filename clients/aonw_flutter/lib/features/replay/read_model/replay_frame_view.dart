import '../../map/read_model/map_scene.dart';

final class ReplayFrameView {
  const ReplayFrameView({
    required this.position,
    required this.entryCount,
    required this.scene,
  });

  final int position;
  final int entryCount;
  final MapScene scene;

  bool get isComplete => position >= entryCount;
}
