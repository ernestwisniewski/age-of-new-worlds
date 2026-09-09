import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../read_model/map_view.dart';
import '../read_model/movement_view.dart';
import '../read_model/stored_unit_route_view.dart';

StoredUnitRouteView? mapQueuedUnitRoute(AonwPlayerUnitView unit, MapView map) {
  final route = unit.ownedDetails?.queuedPath;
  if (route == null) return null;
  final steps = _steps(route.steps, map);
  final target = (col: route.target.col, row: route.target.row);
  if (steps.first.coordinate != _position(unit) ||
      steps.last.coordinate != target) {
    throw const FormatException('Queued route endpoints are inconsistent.');
  }
  return StoredUnitRouteView(
    kind: StoredUnitRouteKind.queued,
    target: target,
    steps: steps,
  );
}

StoredUnitRouteView? mapMerchantUnitRoute(
  AonwPlayerUnitView unit,
  MapView map,
) {
  final route = unit.ownedDetails?.merchantTradeRoute;
  if (route == null) return null;
  final steps = _steps(route.steps, map);
  if (route.originCityId.isEmpty ||
      route.destinationCityId.isEmpty ||
      route.originCityId == route.destinationCityId ||
      !steps.any((step) => step.coordinate == _position(unit))) {
    throw const FormatException('Merchant route identity is inconsistent.');
  }
  return StoredUnitRouteView(
    kind: StoredUnitRouteKind.merchant,
    target: steps.last.coordinate,
    steps: steps,
    originCityId: route.originCityId,
    destinationCityId: route.destinationCityId,
  );
}

MapHexCoordinate _position(AonwPlayerUnitView unit) =>
    (col: unit.coordinate.col, row: unit.coordinate.row);

List<MovementStepView> _steps(
  List<AonwPersistedMovementStep> source,
  MapView map,
) {
  if (source.length < 2 ||
      source.first.enterCostUnits != 0 ||
      source.first.cumulativeCostUnits != 0) {
    throw const FormatException(
      'Stored route has no valid origin and travel step.',
    );
  }
  final result = <MovementStepView>[];
  var cumulative = 0;
  for (var index = 0; index < source.length; index++) {
    final step = source[index];
    final coordinate = (col: step.coordinate.col, row: step.coordinate.row);
    if (!map.contains(coordinate) ||
        (index > 0 && step.enterCostUnits <= 0) ||
        step.cumulativeCostUnits != cumulative + step.enterCostUnits) {
      throw const FormatException(
        'Stored route coordinates or costs are inconsistent.',
      );
    }
    cumulative = step.cumulativeCostUnits;
    result.add(
      MovementStepView(
        coordinate: coordinate,
        enterCostUnits: step.enterCostUnits,
        cumulativeCostUnits: step.cumulativeCostUnits,
      ),
    );
  }
  return result;
}
