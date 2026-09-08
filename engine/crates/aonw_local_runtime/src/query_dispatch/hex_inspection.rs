use crate::session::Session;
use crate::{RuntimeError, RuntimeQueryResult};
use aonw_domain::HexCoord;
use aonw_engine::{
    GameEngine, GameQuery, HexInspectionQuery, MovementSearchWorkspace, QueryResult,
};

/// Current actor-filtered hex-inspection request.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct HexInspectionRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Requested map coordinate.
    pub coordinate: HexCoord,
}

pub(super) fn dispatch_hex_inspection(
    session: &Session,
    request: HexInspectionRequest,
    workspace: &mut MovementSearchWorkspace,
) -> Result<RuntimeQueryResult, RuntimeError> {
    let result = GameEngine::query_with_workspace(
        session.state(),
        session.context(),
        GameQuery::HexInspection(HexInspectionQuery::new(
            request.expected_revision,
            request.coordinate,
        )),
        workspace,
    )
    .map_err(RuntimeError::Query)?;
    let QueryResult::HexInspection(inspection) = result else {
        unreachable!("hex inspection query returns a hex profile")
    };
    Ok(RuntimeQueryResult::HexInspection {
        stamp: session.stamp(),
        inspection,
    })
}
