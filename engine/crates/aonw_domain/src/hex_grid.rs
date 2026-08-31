use std::num::NonZeroU16;

use crate::HexCoord;

/// Row-major index into one bounded hex grid.
#[derive(Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub struct HexTileIndex(usize);

impl HexTileIndex {
    /// Wraps a zero-based row-major index.
    #[must_use]
    pub const fn new(value: usize) -> Self {
        Self(value)
    }

    /// Returns the zero-based row-major index.
    #[must_use]
    pub const fn get(self) -> usize {
        self.0
    }
}

/// Non-empty rectangular bounds for an odd-q hex grid.
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub struct HexGridBounds {
    cols: NonZeroU16,
    rows: NonZeroU16,
}

impl HexGridBounds {
    /// Returns `None` when either dimension is zero.
    #[must_use]
    pub const fn new(cols: u16, rows: u16) -> Option<Self> {
        let Some(cols) = NonZeroU16::new(cols) else {
            return None;
        };
        let Some(rows) = NonZeroU16::new(rows) else {
            return None;
        };
        Some(Self { cols, rows })
    }

    /// Returns the grid width.
    #[must_use]
    pub const fn cols(self) -> u16 {
        self.cols.get()
    }

    /// Returns the grid height.
    #[must_use]
    pub const fn rows(self) -> u16 {
        self.rows.get()
    }

    /// Returns the number of coordinates contained by the bounds.
    #[must_use]
    pub fn tile_count(self) -> usize {
        usize::from(self.cols()) * usize::from(self.rows())
    }

    /// Tests whether a coordinate is inside the bounds.
    #[must_use]
    pub fn contains(self, coordinate: HexCoord) -> bool {
        coordinate.col() >= 0
            && coordinate.col() < i32::from(self.cols())
            && coordinate.row() >= 0
            && coordinate.row() < i32::from(self.rows())
    }

    /// Converts an in-bounds coordinate to its row-major index.
    #[must_use]
    pub fn index_of(self, coordinate: HexCoord) -> Option<HexTileIndex> {
        if !self.contains(coordinate) {
            return None;
        }
        let col = usize::try_from(coordinate.col()).ok()?;
        let row = usize::try_from(coordinate.row()).ok()?;
        Some(HexTileIndex::new(row * usize::from(self.cols()) + col))
    }

    /// Converts an in-bounds row-major index to its coordinate.
    #[must_use]
    pub fn coordinate_at(self, index: HexTileIndex) -> Option<HexCoord> {
        if index.get() >= self.tile_count() {
            return None;
        }
        let cols = usize::from(self.cols());
        let col = u16::try_from(index.get() % cols).ok()?;
        let row = u16::try_from(index.get() / cols).ok()?;
        Some(HexCoord::new(i32::from(col), i32::from(row)))
    }

    /// Iterates in-bounds neighbors while preserving canonical odd-q order.
    pub fn neighbors(self, coordinate: HexCoord) -> impl Iterator<Item = HexCoord> {
        let contains_origin = self.contains(coordinate);
        coordinate
            .neighbors()
            .filter(move |neighbor| contains_origin && self.contains(*neighbor))
    }
}

#[cfg(test)]
mod tests {
    use super::{HexGridBounds, HexTileIndex};
    use crate::HexCoord;

    #[test]
    fn one_by_one_grid_has_one_index_and_no_neighbors() {
        let bounds = HexGridBounds::new(1, 1).expect("non-empty bounds");

        assert_eq!(bounds.tile_count(), 1);
        assert!(bounds.contains(HexCoord::new(0, 0)));
        assert_eq!(
            bounds.index_of(HexCoord::new(0, 0)),
            Some(HexTileIndex::new(0))
        );
        assert_eq!(
            bounds.coordinate_at(HexTileIndex::new(0)),
            Some(HexCoord::new(0, 0))
        );
        assert_eq!(bounds.neighbors(HexCoord::new(0, 0)).count(), 0);
    }

    #[test]
    fn three_by_three_grid_uses_row_major_indices() {
        let bounds = HexGridBounds::new(3, 3).expect("non-empty bounds");

        for row in 0..3 {
            for col in 0..3 {
                let coordinate = HexCoord::new(col, row);
                let index = HexTileIndex::new(usize::try_from(row * 3 + col).expect("small index"));
                assert_eq!(bounds.index_of(coordinate), Some(index));
                assert_eq!(bounds.coordinate_at(index), Some(coordinate));
            }
        }
    }

    #[test]
    fn bounded_neighbors_preserve_topology_order() {
        let bounds = HexGridBounds::new(3, 3).expect("non-empty bounds");

        assert_eq!(
            bounds.neighbors(HexCoord::new(1, 1)).collect::<Vec<_>>(),
            [
                HexCoord::new(2, 1),
                HexCoord::new(2, 2),
                HexCoord::new(1, 2),
                HexCoord::new(0, 2),
                HexCoord::new(0, 1),
                HexCoord::new(1, 0),
            ]
        );
        assert_eq!(
            bounds.neighbors(HexCoord::new(0, 0)).collect::<Vec<_>>(),
            [HexCoord::new(1, 0), HexCoord::new(0, 1)]
        );
    }

    #[test]
    fn bounds_reject_zero_dimensions_and_outside_coordinates() {
        assert!(HexGridBounds::new(0, 1).is_none());
        assert!(HexGridBounds::new(1, 0).is_none());

        let bounds = HexGridBounds::new(3, 3).expect("non-empty bounds");
        for coordinate in [
            HexCoord::new(-1, 0),
            HexCoord::new(0, -1),
            HexCoord::new(3, 0),
            HexCoord::new(0, 3),
        ] {
            assert!(!bounds.contains(coordinate));
            assert!(bounds.index_of(coordinate).is_none());
            assert_eq!(bounds.neighbors(coordinate).count(), 0);
        }
        assert!(bounds.coordinate_at(HexTileIndex::new(9)).is_none());
    }
}
