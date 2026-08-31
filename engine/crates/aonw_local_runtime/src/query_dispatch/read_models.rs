use aonw_domain::{CityId, HexCoord};
use aonw_engine::{
    CityYieldQuery, CombatPreviewQuery, GameEngine, GameQuery, MovementSearchWorkspace,
    ProductionOptionsQuery, QueryResult, StrategicResourceProjectionQuery,
};

use crate::session::Session;
use crate::{RuntimeError, RuntimeQueryResult};

/// Current engine-owned city-yield request.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CityYieldRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Controlled city.
    pub city_id: CityId,
}

/// Current actor-owned strategic resource projection request.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct StrategicResourceProjectionRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
}

/// Current engine-owned city-production-options request.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ProductionOptionsRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Controlled city.
    pub city_id: CityId,
}

/// Current recipient-safe combat preview request.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CombatPreviewRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Controlled attacking unit.
    pub attacker_unit_id: aonw_domain::UnitId,
    /// Visible target coordinate.
    pub defender: HexCoord,
}

pub(super) fn dispatch_combat_preview_query(
    session: &Session,
    request: &CombatPreviewRequest,
    workspace: &mut MovementSearchWorkspace,
) -> Result<RuntimeQueryResult, RuntimeError> {
    let result = GameEngine::query_with_workspace(
        session.state(),
        session.context(),
        GameQuery::CombatPreview(CombatPreviewQuery::new(
            request.expected_revision,
            &request.attacker_unit_id,
            request.defender,
        )),
        workspace,
    )
    .map_err(RuntimeError::Query)?;
    let QueryResult::CombatPreview(preview) = result else {
        unreachable!("combat preview returns combat response")
    };
    Ok(RuntimeQueryResult::CombatPreview {
        stamp: session.stamp(),
        preview,
    })
}

pub(super) fn dispatch_city_yield_query(
    session: &Session,
    request: &CityYieldRequest,
    workspace: &mut MovementSearchWorkspace,
) -> Result<RuntimeQueryResult, RuntimeError> {
    let result = GameEngine::query_with_workspace(
        session.state(),
        session.context(),
        GameQuery::CityYield(CityYieldQuery::new(
            request.expected_revision,
            &request.city_id,
        )),
        workspace,
    )
    .map_err(RuntimeError::Query)?;
    let QueryResult::CityYield(breakdown) = result else {
        unreachable!("city yield query returns city yield")
    };
    Ok(RuntimeQueryResult::CityYield {
        stamp: session.stamp(),
        breakdown,
    })
}

pub(super) fn dispatch_strategic_resource_query(
    session: &Session,
    request: StrategicResourceProjectionRequest,
    workspace: &mut MovementSearchWorkspace,
) -> Result<RuntimeQueryResult, RuntimeError> {
    let result = GameEngine::query_with_workspace(
        session.state(),
        session.context(),
        GameQuery::StrategicResourceProjection(StrategicResourceProjectionQuery::new(
            request.expected_revision,
        )),
        workspace,
    )
    .map_err(RuntimeError::Query)?;
    let QueryResult::StrategicResourceProjection(projection) = result else {
        unreachable!("strategic resource query returns projection")
    };
    Ok(RuntimeQueryResult::StrategicResourceProjection {
        stamp: session.stamp(),
        projection,
    })
}

pub(super) fn dispatch_production_options_query(
    session: &Session,
    request: &ProductionOptionsRequest,
    workspace: &mut MovementSearchWorkspace,
) -> Result<RuntimeQueryResult, RuntimeError> {
    let result = GameEngine::query_with_workspace(
        session.state(),
        session.context(),
        GameQuery::ProductionOptions(ProductionOptionsQuery::new(
            request.expected_revision,
            &request.city_id,
        )),
        workspace,
    )
    .map_err(RuntimeError::Query)?;
    let QueryResult::ProductionOptions(options) = result else {
        unreachable!("production options query returns production options")
    };
    Ok(RuntimeQueryResult::ProductionOptions {
        stamp: session.stamp(),
        options,
    })
}
