import '../read_model/hex_inspection_view.dart';
import '../read_model/map_view.dart';

sealed class HexInspectionState {
  const HexInspectionState(this.coordinate);
  final MapHexCoordinate coordinate;
}

final class HexInspectionLoading extends HexInspectionState {
  const HexInspectionLoading(super.coordinate);
}

final class HexInspectionReady extends HexInspectionState {
  HexInspectionReady(this.view) : super(view.coordinate);
  final HexInspectionView view;
}

final class HexInspectionFailure extends HexInspectionState {
  const HexInspectionFailure(super.coordinate, this.code);
  final HexInspectionFailureCode code;
}

enum HexInspectionFailureCode {
  requestFailed,
  responseIncompatible,
  sessionUnavailable,
}
