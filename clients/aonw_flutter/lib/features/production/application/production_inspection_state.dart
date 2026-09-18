import '../read_model/production_details_view.dart';
import '../read_model/production_view.dart';
import 'production_state.dart';

final class ProductionInspectionState {
  const ProductionInspectionState({
    required this.target,
    required this.correlationId,
    this.loading = true,
    this.details,
    this.failure,
  });

  final ProductionTargetView target;
  final int correlationId;
  final bool loading;
  final ProductionDetailsView? details;
  final ProductionFailureView? failure;
}
