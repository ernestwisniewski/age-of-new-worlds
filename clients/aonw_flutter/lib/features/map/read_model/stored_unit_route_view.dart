import 'map_view.dart';
import 'movement_view.dart';

enum StoredUnitRouteKind { queued, merchant }

/// An immutable itinerary received in the owning recipient's projection.
final class StoredUnitRouteView {
  StoredUnitRouteView({
    required this.kind,
    required this.target,
    required List<MovementStepView> steps,
    required Iterable<int> roadStepIndices,
    required List<int> stepTurns,
    this.originCityId,
    this.destinationCityId,
  }) : steps = List.unmodifiable(steps),
       stepTurns = List.unmodifiable(stepTurns),
       roadStepIndices = Set.unmodifiable(roadStepIndices);
  final StoredUnitRouteKind kind;
  final MapHexCoordinate target;
  final List<MovementStepView> steps;
  final List<int> stepTurns;
  final Set<int> roadStepIndices;
  final String? originCityId;
  final String? destinationCityId;
}
