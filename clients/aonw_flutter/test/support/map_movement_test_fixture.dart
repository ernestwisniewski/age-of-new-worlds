part of 'map_test_fixture.dart';

ReachableView testReachableView({
  String unitId = 'preview-commander',
  int revision = 0,
  String? stateDigest,
  bool canStartTargeting = true,
  bool canRetainTargeting = true,
  int availableMovementUnits = 12,
  List<ReachableTileView> tiles = const [
    ReachableTileView(
      coordinate: (col: 1, row: 0),
      costUnits: 4,
      exhaustsMovement: false,
    ),
  ],
}) => ReachableView(
  canStartTargeting: canStartTargeting,
  canRetainTargeting: canRetainTargeting,
  stamp: testSessionStamp(revision: revision, stateDigest: stateDigest),
  unitId: unitId,
  availableMovementUnits: availableMovementUnits,
  tiles: tiles,
);
