use crate::session::Session;
use crate::{
    CityExpansionOptionsRequest, CityFoundingOptionsRequest, CityWorkedHexOptionsRequest,
    RuntimeError, RuntimeQueryResult,
};
use aonw_engine::{
    CityExpansionOptionsQuery, CityFoundingOptionsQuery, CityWorkedHexOptionsQuery, GameEngine,
    GameQuery, MovementSearchWorkspace, QueryResult,
};

pub(super) fn dispatch_city_founding_query(
    session: &Session,
    request: &CityFoundingOptionsRequest,
    workspace: &mut MovementSearchWorkspace,
) -> Result<RuntimeQueryResult, RuntimeError> {
    let result = GameEngine::query_with_workspace(
        session.state(),
        session.context(),
        GameQuery::CityFoundingOptions(CityFoundingOptionsQuery::new(
            request.expected_revision,
            &request.founder_unit_id,
        )),
        workspace,
    )
    .map_err(RuntimeError::Query)?;
    let QueryResult::CityFoundingOptions(options) = result else {
        unreachable!("city founding query returns founding options")
    };
    Ok(RuntimeQueryResult::CityFoundingOptions {
        stamp: session.stamp(),
        options,
    })
}

pub(super) fn dispatch_city_worked_query(
    session: &Session,
    request: &CityWorkedHexOptionsRequest,
    workspace: &mut MovementSearchWorkspace,
) -> Result<RuntimeQueryResult, RuntimeError> {
    let result = GameEngine::query_with_workspace(
        session.state(),
        session.context(),
        GameQuery::CityWorkedHexOptions(CityWorkedHexOptionsQuery::new(
            request.expected_revision,
            &request.city_id,
        )),
        workspace,
    )
    .map_err(RuntimeError::Query)?;
    let QueryResult::CityWorkedHexOptions(options) = result else {
        unreachable!("city worked query returns worked options")
    };
    Ok(RuntimeQueryResult::CityWorkedHexOptions {
        stamp: session.stamp(),
        options,
    })
}

pub(super) fn dispatch_city_expansion_query(
    session: &Session,
    request: &CityExpansionOptionsRequest,
    workspace: &mut MovementSearchWorkspace,
) -> Result<RuntimeQueryResult, RuntimeError> {
    let result = GameEngine::query_with_workspace(
        session.state(),
        session.context(),
        GameQuery::CityExpansionOptions(CityExpansionOptionsQuery::new(
            request.expected_revision,
            &request.city_id,
        )),
        workspace,
    )
    .map_err(RuntimeError::Query)?;
    let QueryResult::CityExpansionOptions(options) = result else {
        unreachable!("city expansion query returns expansion options")
    };
    Ok(RuntimeQueryResult::CityExpansionOptions {
        stamp: session.stamp(),
        options,
    })
}
