/// Persistent behavior selected for a unit.
#[derive(Clone, Copy, Debug, Default, Eq, Hash, PartialEq)]
pub enum UnitPosture {
    /// Available for direct commands.
    #[default]
    Active,
    /// Fortified until an accepted manual move wakes it.
    Fortified,
    /// Controlled by auto-exploration.
    AutoExploring,
    /// Controlled by worker automation.
    AutoWorking,
}
