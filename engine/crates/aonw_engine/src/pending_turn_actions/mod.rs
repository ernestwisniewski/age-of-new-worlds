use aonw_domain::{CityId, HexCoord, UnitId};

mod query;
pub use query::PendingTurnActionsError;

/// Revision-bound request for the authenticated actor's manual turn work.
#[derive(Clone, Copy, Debug)]
pub struct PendingTurnActionsQuery {
    expected_revision: u64,
}
impl PendingTurnActionsQuery {
    /// Creates a request against the current canonical revision.
    #[must_use]
    pub const fn new(expected_revision: u64) -> Self {
        Self { expected_revision }
    }
}

/// A focus target; selecting it does not execute its gameplay command.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum PendingTurnAction {
    Unit {
        unit_id: UnitId,
        coordinate: HexCoord,
    },
    CityProduction {
        city_id: CityId,
        coordinate: HexCoord,
    },
    Research,
}

/// Authoritative manual work in navigation order, scoped to one recipient.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PendingTurnActions {
    /// Whether the current actor may activate a target or the normal turn action.
    /// An empty list does not bypass end/submit-turn command validation.
    pub can_activate: bool,
    /// Combat units first, then workers/settlers, other units, idle cities, research.
    /// Within a unit category, units seeing disclosed foreign units come first;
    /// ties retain canonical unit order. City ties retain canonical city order.
    pub actions: Vec<PendingTurnAction>,
}

impl crate::GameEngine {
    /// Lists manual work without modifying selection, pending interaction or state.
    ///
    /// # Errors
    /// Rejects a stale revision, unknown actor or invalid authoritative definitions.
    pub fn pending_turn_actions(
        state: &aonw_domain::GameState,
        context: crate::EngineContext<'_>,
        query: PendingTurnActionsQuery,
    ) -> Result<PendingTurnActions, PendingTurnActionsError> {
        query::pending(state, context, query)
    }
}
