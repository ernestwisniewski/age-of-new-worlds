import 'dart:math' as math;

const double aonwMapHexRadius = 60;

typedef AonwHexCoordinate = ({int col, int row});
typedef AonwPoint = ({double x, double y});
typedef AonwBounds = ({double x, double y, double width, double height});

/// Presentation geometry for the canonical odd-q, flat-top map layout.
final class AonwOddQFlatTopGeometry {
  const AonwOddQFlatTopGeometry({
    required this.cols,
    required this.rows,
    this.radius = 1,
  }) : assert(cols > 0),
       assert(rows > 0),
       assert(radius > 0);

  static final double sqrt3 = math.sqrt(3);
  static const _distanceTieTolerance = 0.000001;
  static const _cornerOffsets = <(int, int)>[
    (2, 0),
    (1, 1),
    (-1, 1),
    (-2, 0),
    (-1, -1),
    (1, -1),
  ];
  static const _evenNeighborOffsets = <(int, int)>[
    (1, -1),
    (1, 0),
    (0, 1),
    (-1, 0),
    (-1, -1),
    (0, -1),
  ];
  static const _oddNeighborOffsets = <(int, int)>[
    (1, 0),
    (1, 1),
    (0, 1),
    (-1, 1),
    (-1, 0),
    (0, -1),
  ];

  final int cols;
  final int rows;
  final double radius;

  AonwPoint center(AonwHexCoordinate hex) =>
      _latticeToPoint((x: 3 * hex.col, y: 2 * hex.row + (hex.col & 1)));

  AonwPoint corner(AonwHexCoordinate hex, int corner) {
    if (corner < 0 || corner >= _cornerOffsets.length) {
      throw RangeError.range(corner, 0, _cornerOffsets.length - 1, 'corner');
    }
    final centerKey = (x: 3 * hex.col, y: 2 * hex.row + (hex.col & 1));
    final offset = _cornerOffsets[corner];
    return _latticeToPoint((
      x: centerKey.x + offset.$1,
      y: centerKey.y + offset.$2,
    ));
  }

  List<AonwHexCoordinate> neighbors(AonwHexCoordinate hex) {
    final offsets = hex.col.isOdd ? _oddNeighborOffsets : _evenNeighborOffsets;
    return List.unmodifiable([
      for (final offset in offsets)
        (col: hex.col + offset.$1, row: hex.row + offset.$2),
    ]);
  }

  AonwBounds get bounds {
    final minimumY = -sqrt3 * radius * 0.5;
    final maximumX = (cols - 1) * 1.5 * radius + radius;
    final oddColumnShift = cols > 1 ? sqrt3 * radius * 0.5 : 0.0;
    final maximumY =
        (rows - 1) * sqrt3 * radius + oddColumnShift + sqrt3 * radius * 0.5;
    return (
      x: -radius,
      y: minimumY,
      width: maximumX + radius,
      height: maximumY - minimumY,
    );
  }

  AonwHexCoordinate hexAt(AonwPoint point) {
    final approximateCol = (point.x / (1.5 * radius)).round();
    final approximateRow =
        ((point.y - (approximateCol & 1) * sqrt3 * radius * 0.5) /
                (sqrt3 * radius))
            .round();
    var best = (col: approximateCol, row: approximateRow);
    var bestDistance = _distanceSquared(point, center(best));
    final tieTolerance = radius * radius * _distanceTieTolerance;
    for (var colOffset = -1; colOffset <= 1; colOffset++) {
      for (var rowOffset = -1; rowOffset <= 1; rowOffset++) {
        final candidate = (
          col: approximateCol + colOffset,
          row: approximateRow + rowOffset,
        );
        final distance = _distanceSquared(point, center(candidate));
        if (distance < bestDistance - tieTolerance ||
            ((distance - bestDistance).abs() <= tieTolerance &&
                _comesBefore(candidate, best))) {
          best = candidate;
          bestDistance = distance;
        }
      }
    }
    return best;
  }

  AonwPoint normalizedUv(AonwPoint point) {
    final area = bounds;
    return (
      x: (point.x - area.x) / area.width,
      y: (point.y - area.y) / area.height,
    );
  }

  AonwPoint _latticeToPoint(({int x, int y}) key) =>
      (x: key.x * radius * 0.5, y: key.y * sqrt3 * radius * 0.5);

  static double _distanceSquared(AonwPoint left, AonwPoint right) {
    final dx = left.x - right.x;
    final dy = left.y - right.y;
    return dx * dx + dy * dy;
  }

  static bool _comesBefore(
    AonwHexCoordinate candidate,
    AonwHexCoordinate current,
  ) =>
      candidate.col < current.col ||
      (candidate.col == current.col && candidate.row < current.row);
}
