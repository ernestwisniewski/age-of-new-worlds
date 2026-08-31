import '../../map/read_model/player_map_view.dart';
import '../read_model/city_view.dart';

abstract interface class CitySessionPort {
  Future<CityFoundingOptionsView> cityFoundingOptions({
    required int expectedRevision,
    required String founderUnitId,
  });

  Future<CityInspectionView> inspectCity({
    required int expectedRevision,
    required String cityId,
  });

  Future<CityCommandResultView> executeCityAction({
    required int expectedRevision,
    required CityActionView action,
  });
}

final class CitySessionException implements Exception {
  const CitySessionException({
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
