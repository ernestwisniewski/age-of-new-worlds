import '../read_model/city_planning_view.dart';
import '../read_model/player_map_view.dart';

abstract interface class CityPlanningSessionPort {
  Future<CityPlanningView> cityPlanning({required int expectedRevision});
}

final class CityPlanningSessionException implements Exception {
  const CityPlanningSessionException({
    required this.code,
    required this.message,
    this.diagnosticCause,
    this.diagnosticStackTrace,
    this.resyncedPlayer,
  });

  final String code;
  final String message;
  final Object? diagnosticCause;
  final StackTrace? diagnosticStackTrace;
  final PlayerMapView? resyncedPlayer;
}
