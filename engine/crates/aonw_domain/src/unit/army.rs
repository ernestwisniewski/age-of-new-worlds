/// Troop carried by a commander army.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub enum TroopKind {
    Warrior,
    Archer,
    Settler,
}

/// Count of one troop kind in an army.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ArmyTroop {
    kind: TroopKind,
    count: u32,
}

impl ArmyTroop {
    /// Constructs a troop count. Zero is rejected by [`super::UnitBuilder`].
    #[must_use]
    pub const fn new(kind: TroopKind, count: u32) -> Self {
        Self { kind, count }
    }

    /// Returns the troop kind.
    #[must_use]
    pub const fn kind(self) -> TroopKind {
        self.kind
    }

    /// Returns the troop count.
    #[must_use]
    pub const fn count(self) -> u32 {
        self.count
    }
}
