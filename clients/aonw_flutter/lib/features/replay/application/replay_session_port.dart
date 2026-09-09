import '../../map/application/city_planning_session_port.dart';
import '../../map/application/map_session_port.dart';
import '../read_model/replay_frame_view.dart';

abstract interface class ReplaySessionPort implements CityPlanningSessionPort {
  Future<String> exportReplayDocument();

  Future<ReplayFrameView> openReplayDocument({
    required MapAssetPaths assets,
    required String document,
  });

  Future<ReplayFrameView> seekReplay(int position);
}

final class ReplaySessionException implements Exception {
  const ReplaySessionException({
    required this.code,
    required this.message,
    this.diagnosticCause,
    this.diagnosticStackTrace,
  });

  final String code;
  final String message;
  final Object? diagnosticCause;
  final StackTrace? diagnosticStackTrace;

  @override
  String toString() => 'ReplaySessionException($code): $message';
}
