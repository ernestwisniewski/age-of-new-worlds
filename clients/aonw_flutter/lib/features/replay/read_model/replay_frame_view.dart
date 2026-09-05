import '../../map/read_model/map_command_frame_view.dart';
import '../../map/read_model/map_scene.dart';

final class ReplayFrameView {
  const ReplayFrameView({
    required this.position,
    required this.entryCount,
    required this.scene,
    this.command,
  });

  final int position;
  final int entryCount;
  final MapScene scene;

  /// Present only when advancing exactly one command from the previous frame.
  /// Opening, repeating or jumping to a position starts a fresh feedback history.
  final MapCommandFrameView? command;

  bool get isComplete => position >= entryCount;
}
