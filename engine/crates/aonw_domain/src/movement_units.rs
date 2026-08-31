/// Fixed-point movement balance used by deterministic rules.
#[derive(Clone, Copy, Debug, Default, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub struct MovementUnits(u32);

impl MovementUnits {
    /// Number of movement units represented by one displayed point.
    pub const PER_POINT: u32 = 2;

    /// Zero movement balance.
    pub const ZERO: Self = Self(0);

    /// Constructs a balance from its canonical fixed-point value.
    #[must_use]
    pub const fn new(value: u32) -> Self {
        Self(value)
    }

    /// Converts whole display points without integer wrapping.
    #[must_use]
    pub const fn checked_from_whole_points(points: u32) -> Option<Self> {
        match points.checked_mul(Self::PER_POINT) {
            Some(value) => Some(Self(value)),
            None => None,
        }
    }

    /// Returns the canonical fixed-point value.
    #[must_use]
    pub const fn get(self) -> u32 {
        self.0
    }

    /// Returns whether any movement remains.
    #[must_use]
    pub const fn is_positive(self) -> bool {
        self.0 > 0
    }

    /// Adds two balances without integer wrapping.
    #[must_use]
    pub const fn checked_add(self, other: Self) -> Option<Self> {
        match self.0.checked_add(other.0) {
            Some(value) => Some(Self(value)),
            None => None,
        }
    }

    /// Subtracts a cost when the complete cost fits the current balance.
    #[must_use]
    pub const fn checked_sub(self, cost: Self) -> Option<Self> {
        match self.0.checked_sub(cost.0) {
            Some(value) => Some(Self(value)),
            None => None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::MovementUnits;

    #[test]
    fn movement_points_use_the_fixed_point_scale() {
        assert_eq!(
            MovementUnits::checked_from_whole_points(3),
            Some(MovementUnits::new(6))
        );
    }

    #[test]
    fn whole_point_conversion_cannot_wrap() {
        assert_eq!(MovementUnits::checked_from_whole_points(u32::MAX), None);
    }

    #[test]
    fn arithmetic_cannot_wrap_or_underflow() {
        assert_eq!(
            MovementUnits::new(3).checked_add(MovementUnits::new(4)),
            Some(MovementUnits::new(7))
        );
        assert_eq!(
            MovementUnits::new(u32::MAX).checked_add(MovementUnits::new(1)),
            None
        );
        assert_eq!(
            MovementUnits::new(3).checked_sub(MovementUnits::new(4)),
            None
        );
    }
}
