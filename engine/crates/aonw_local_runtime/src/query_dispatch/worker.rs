use aonw_engine::{
    GameEngine, GameQuery, MovementSearchWorkspace, QueryResult, WorkerOptionsQuery,
};

use super::{RuntimeQueryResult, WorkerOptionsRequest};
use crate::RuntimeError;
use crate::session::Session;

pub(super) fn dispatch_worker_query(
    session: &Session,
    request: &WorkerOptionsRequest,
    workspace: &mut MovementSearchWorkspace,
) -> Result<RuntimeQueryResult, RuntimeError> {
    let result = GameEngine::query_with_workspace(
        session.state(),
        session.context(),
        GameQuery::WorkerOptions(WorkerOptionsQuery::new(
            request.expected_revision,
            &request.unit_id,
        )),
        workspace,
    )
    .map_err(RuntimeError::Query)?;
    let QueryResult::WorkerOptions(options) = result else {
        unreachable!("worker options query returns worker options")
    };
    Ok(RuntimeQueryResult::WorkerOptions {
        stamp: session.stamp(),
        options,
    })
}
