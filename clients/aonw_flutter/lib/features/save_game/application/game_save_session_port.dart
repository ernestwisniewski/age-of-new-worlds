import '../../local_game/application/local_game_session_port.dart';
import '../../map/application/map_session_port.dart';
import '../../map/read_model/map_scene.dart';
import '../../map/read_model/player_map_view.dart';

final class OpenedGameSaveView {
  const OpenedGameSaveView({required this.scene, required this.controlPlan});

  final MapScene scene;
  final LocalMatchControlPlanView controlPlan;

  PlayerMapView get player => scene.player;
}

abstract interface class GameSaveSessionPort {
  Future<String> exportSaveDocument();

  Future<OpenedGameSaveView> openSaveDocument({
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
