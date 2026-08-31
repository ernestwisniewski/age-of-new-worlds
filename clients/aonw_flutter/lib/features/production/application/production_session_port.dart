import '../../map/read_model/player_map_view.dart';
import '../read_model/production_view.dart';

abstract interface class ProductionSessionPort {
  Future<
    ({ProductionOptionsView options, StrategicResourceProjectionView resources})
  >
  productionOverview({required int expectedRevision, required String cityId});

  Future<ProductionCommandResultView> executeProductionAction({
    required int expectedRevision,
    required ProductionActionView action,
  });
}

final class ProductionCommandResultView {
  const ProductionCommandResultView.accepted({required this.player})
    : accepted = true,
      rejectionCode = null;

  const ProductionCommandResultView.rejected({required this.rejectionCode})
    : accepted = false,
      player = null;

  final bool accepted;
  final ProductionRejectionCodeView? rejectionCode;
  final PlayerMapView? player;
}

final class ProductionSessionException implements Exception {
  const ProductionSessionException({
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
