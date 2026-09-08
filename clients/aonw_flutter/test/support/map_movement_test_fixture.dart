part of 'map_test_fixture.dart';

ReachableView testReachableView({
  String unitId = 'preview-commander',
  List<ReachableTileView> tiles = const [
    ReachableTileView(
      coordinate: (col: 1, row: 0),
      costUnits: 4,
      exhaustsMovement: false,
    ),
  ],
}) => ReachableView(
  canStartTargeting: true,
  canRetainTargeting: true,
  stamp: testSessionStamp(),
  unitId: unitId,
  availableMovementUnits: 12,
  tiles: tiles,
);
