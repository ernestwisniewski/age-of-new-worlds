import '../../map/application/map_session_port.dart';
import '../../map/read_model/map_scene.dart';

abstract interface class GameSaveSessionPort {
  Future<String> exportSaveDocument();

  Future<MapScene> openSaveDocument({
    required MapAssetPaths assets,
    required String document,
  });
}

final class GameSaveSessionException implements Exception {
  const GameSaveSessionException({
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
  String toString() => 'GameSaveSessionException($code): $message';
}
