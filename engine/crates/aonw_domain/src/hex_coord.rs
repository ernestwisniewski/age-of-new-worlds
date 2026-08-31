/// Offset coordinate on the canonical odd-q, flat-top hex grid.
#[derive(Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub struct HexCoord {
    col: i32,
    row: i32,
}

impl HexCoord {
    /// Constructs a coordinate without imposing map-specific bounds.
    #[must_use]
    pub const fn new(col: i32, row: i32) -> Self {
        Self { col, row }
    }

    /// Returns the offset-grid column.
    #[must_use]
    pub const fn col(self) -> i32 {
        self.col
    }

    /// Returns the offset-grid row.
    #[must_use]
    pub const fn row(self) -> i32 {
        self.row
    }

    /// Iterates adjacent coordinates in canonical odd-q order.
    ///
    /// Coordinates that would overflow the `i32` representation are omitted.
    pub fn neighbors(self) -> impl Iterator<Item = Self> {
        const EVEN_COLUMN_OFFSETS: [(i32, i32); 6] =
            [(1, -1), (1, 0), (0, 1), (-1, 0), (-1, -1), (0, -1)];
        const ODD_COLUMN_OFFSETS: [(i32, i32); 6] =
            [(1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (0, -1)];

        let offsets = if self.col & 1 == 0 {
            EVEN_COLUMN_OFFSETS
        } else {
            ODD_COLUMN_OFFSETS
        };
        offsets.into_iter().filter_map(move |(col, row)| {
            Some(Self::new(
                self.col.checked_add(col)?,
                self.row.checked_add(row)?,
            ))
        })
    }

    /// Computes exact odd-q hex distance using widened integer arithmetic.
    #[must_use]
    pub fn distance_to(self, other: Self) -> u64 {
        let (self_x, self_y, self_z) = self.to_cube();
        let (other_x, other_y, other_z) = other.to_cube();
        (self_x - other_x)
            .unsigned_abs()
            .max((self_y - other_y).unsigned_abs())
            .max((self_z - other_z).unsigned_abs())
    }

    fn to_cube(self) -> (i64, i64, i64) {
        let x = i64::from(self.col);
        let z = i64::from(self.row) - (x - (x & 1)) / 2;
        let y = -x - z;
        (x, y, z)
    }
}

#[cfg(test)]
mod tests {
    use super::HexCoord;

    #[test]
    fn hex_distance_is_symmetric_and_exact() {
        let origin = HexCoord::new(0, 0);
        let target = HexCoord::new(3, 1);

        assert_eq!(origin.distance_to(target), 3);
        assert_eq!(target.distance_to(origin), 3);
    }

    #[test]
    fn hex_distance_does_not_overflow_for_extreme_i32_coordinates() {
        let minimum = HexCoord::new(i32::MIN, i32::MIN);
        let maximum = HexCoord::new(i32::MAX, i32::MAX);

        assert_eq!(minimum.distance_to(maximum), 6_442_450_943);
    }

    #[test]
    fn even_column_neighbors_match_canonical_order() {
        let neighbors = HexCoord::new(0, 1).neighbors().collect::<Vec<_>>();

        assert_eq!(
            neighbors,
            [
                HexCoord::new(1, 0),
                HexCoord::new(1, 1),
                HexCoord::new(0, 2),
                HexCoord::new(-1, 1),
                HexCoord::new(-1, 0),
                HexCoord::new(0, 0),
            ]
        );
    }

    #[test]
    fn odd_column_neighbors_match_canonical_order() {
        let neighbors = HexCoord::new(1, 1).neighbors().collect::<Vec<_>>();

        assert_eq!(
            neighbors,
            [
                HexCoord::new(2, 1),
                HexCoord::new(2, 2),
                HexCoord::new(1, 2),
                HexCoord::new(0, 2),
                HexCoord::new(0, 1),
                HexCoord::new(1, 0),
            ]
        );
    }
}
