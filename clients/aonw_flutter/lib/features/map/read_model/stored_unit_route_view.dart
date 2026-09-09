import 'map_view.dart';
import 'movement_view.dart';

enum StoredUnitRouteKind { queued, merchant }

/// An immutable itinerary received in the owning recipient's projection.
final class StoredUnitRouteView {
  StoredUnitRouteView({
    required this.kind,
    required this.target,
    required List<MovementStepView> steps,
    this.originCityId,
    this.destinationCityId,
  }) : steps = List.unmodifiable(steps);
  final StoredUnitRouteKind kind;
  final MapHexCoordinate target;
  final List<MovementStepView> steps;
  final String? originCityId;
  final String? destinationCityId;
}
