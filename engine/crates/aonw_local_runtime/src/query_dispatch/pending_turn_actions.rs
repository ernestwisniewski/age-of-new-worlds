use crate::session::Session;
use crate::{RuntimeError, RuntimeQueryResult};
use aonw_engine::{
    GameEngine, GameQuery, MovementSearchWorkspace, PendingTurnActionsQuery, QueryResult,
};

/// Current actor-owned manual-turn-work request.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct PendingTurnActionsRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
}

pub(super) fn dispatch(
    session: &Session,
    request: PendingTurnActionsRequest,
    workspace: &mut MovementSearchWorkspace,
) -> Result<RuntimeQueryResult, RuntimeError> {
    let result = GameEngine::query_with_workspace(
        session.state(),
        session.context(),
        GameQuery::PendingTurnActions(PendingTurnActionsQuery::new(request.expected_revision)),
        workspace,
    )
    .map_err(RuntimeError::Query)?;
    let QueryResult::PendingTurnActions(actions) = result else {
        unreachable!("pending turn actions query returns manual turn work")
    };
    Ok(RuntimeQueryResult::PendingTurnActions {
        stamp: session.stamp(),
        actions,
    })
}
