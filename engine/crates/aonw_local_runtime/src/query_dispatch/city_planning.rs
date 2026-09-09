use crate::session::Session;
use crate::{RuntimeError, RuntimeQueryResult};
use aonw_engine::{CityPlanningQuery, GameEngine, GameQuery, MovementSearchWorkspace, QueryResult};

/// Current recipient-safe city planning request.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct CityPlanningRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
}

pub(super) fn dispatch(
    session: &Session,
    request: CityPlanningRequest,
    workspace: &mut MovementSearchWorkspace,
) -> Result<RuntimeQueryResult, RuntimeError> {
    let result = GameEngine::query_with_workspace(
        session.state(),
        session.context(),
        GameQuery::CityPlanning(CityPlanningQuery::new(request.expected_revision)),
        workspace,
    )
    .map_err(RuntimeError::Query)?;
    let QueryResult::CityPlanning(planning) = result else {
        unreachable!("pending turn planning query returns city planning")
    };
    Ok(RuntimeQueryResult::CityPlanning {
        stamp: session.stamp(),
        planning,
    })
}
