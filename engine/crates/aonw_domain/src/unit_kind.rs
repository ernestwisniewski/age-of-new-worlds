/// Unit traversal category used by movement rules.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub enum UnitMovementDomain {
    Land,
    Naval,
    Air,
}

/// Stable canonical unit type.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub enum UnitKind {
    Commander,
    Warrior,
    Archer,
    Settler,
    Worker,
    Merchant,
    Scout,
    Spearman,
    Cavalry,
    Catapult,
    HeavyInfantry,
    FieldCannon,
    Rifleman,
    Tank,
    ScoutShip,
    Warship,
    ReconPlane,
}
