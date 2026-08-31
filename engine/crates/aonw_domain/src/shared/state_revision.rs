/// Monotonic revision of one canonical game state.
#[derive(Clone, Copy, Debug, Default, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub struct StateRevision(u64);

impl StateRevision {
    /// Initial revision of a newly bootstrapped simulation.
    pub const INITIAL: Self = Self(0);

    /// Constructs a revision from its wire representation.
    #[must_use]
    pub const fn new(value: u64) -> Self {
        Self(value)
    }

    /// Returns the wire representation.
    #[must_use]
    pub const fn get(self) -> u64 {
        self.0
    }

    /// Returns the next revision without wrapping.
    #[must_use]
    pub const fn checked_next(self) -> Option<Self> {
        match self.0.checked_add(1) {
            Some(value) => Some(Self(value)),
            None => None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::StateRevision;

    #[test]
    fn revision_never_wraps() {
        assert_eq!(
            StateRevision::new(9).checked_next(),
            Some(StateRevision::new(10))
        );
        assert_eq!(StateRevision::new(u64::MAX).checked_next(), None);
    }
}
