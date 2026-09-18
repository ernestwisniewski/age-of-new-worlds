use aonw_domain::{CityId, CityProductionTarget};
use aonw_engine::{
    GameEngine, GameQuery, MovementSearchWorkspace, ProductionDetailsQuery, ProductionOptionsQuery,
    QueryResult,
};

use crate::session::Session;
use crate::{ProductionOptionsRequest, RuntimeError, RuntimeQueryResult};

/// Selected production target for a controlled city.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ProductionDetailsRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Controlled city.
    pub city_id: CityId,
    /// Target whose effects should be projected.
    pub target: CityProductionTarget,
}

pub(super) fn dispatch_details(
    session: &Session,
    request: &ProductionDetailsRequest,
    workspace: &mut MovementSearchWorkspace,
) -> Result<RuntimeQueryResult, RuntimeError> {
    let result = GameEngine::query_with_workspace(
        session.state(),
        session.context(),
        GameQuery::ProductionDetails(ProductionDetailsQuery::new(
            request.expected_revision,
            &request.city_id,
            request.target,
        )),
        workspace,
    )
    .map_err(RuntimeError::Query)?;
    let QueryResult::ProductionDetails(details) = result else {
        unreachable!("production details query returns production details")
    };
    Ok(RuntimeQueryResult::ProductionDetails {
        stamp: session.stamp(),
        details: Box::new(details),
    })
}

pub(super) fn dispatch_ranks(
    session: &Session,
    request: &ProductionOptionsRequest,
    workspace: &mut MovementSearchWorkspace,
) -> Result<RuntimeQueryResult, RuntimeError> {
    let result = GameEngine::query_with_workspace(
        session.state(),
        session.context(),
        GameQuery::ProductionBuildingRanks(ProductionOptionsQuery::new(
            request.expected_revision,
            &request.city_id,
        )),
        workspace,
    )
    .map_err(RuntimeError::Query)?;
    let QueryResult::ProductionBuildingRanks(ranks) = result else {
        unreachable!("production ranks query returns production ranks")
    };
    Ok(RuntimeQueryResult::ProductionBuildingRanks {
        stamp: session.stamp(),
        ranks,
    })
}
