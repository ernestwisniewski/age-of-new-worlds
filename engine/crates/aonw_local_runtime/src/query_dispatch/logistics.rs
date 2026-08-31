use aonw_domain::MovementUnits;
use aonw_engine::{
    GameEngine, GameQuery, MovementSearchWorkspace, QueryResult, UnitLogisticsOptionsQuery,
};

use super::{
    AutoExploreOptionView, DetachmentOptionView, MerchantDestinationView, RuntimeQueryResult,
    UnitLogisticsOptionsRequest, UnitLogisticsOptionsResult,
};
use crate::RuntimeError;
use crate::session::Session;

pub(super) fn dispatch_logistics_query(
    session: &Session,
    request: &UnitLogisticsOptionsRequest,
    workspace: &mut MovementSearchWorkspace,
) -> Result<RuntimeQueryResult, RuntimeError> {
    let result = GameEngine::query_with_workspace(
        session.state(),
        session.context(),
        GameQuery::UnitLogisticsOptions(UnitLogisticsOptionsQuery::new(
            request.expected_revision,
            &request.unit_id,
        )),
        workspace,
    )
    .map_err(RuntimeError::Query)?;
    let QueryResult::UnitLogisticsOptions(result) = result else {
        unreachable!("logistics query returns logistics options")
    };
    Ok(RuntimeQueryResult::UnitLogisticsOptions(
        UnitLogisticsOptionsResult {
            stamp: session.stamp(),
            unit_id: result.unit_id().clone(),
            auto_explore: result.auto_explore().map(|option| AutoExploreOptionView {
                target: option.target(),
                total_cost: MovementUnits::new(option.total_cost_units()),
                search_metrics: option.search_metrics(),
            }),
            merchant_route_destinations: result
                .merchant_route_destinations()
                .iter()
                .map(merchant_destination)
                .collect(),
            merchant_travel_destinations: result
                .merchant_travel_destinations()
                .iter()
                .map(merchant_destination)
                .collect(),
            detachments: result
                .detachments()
                .iter()
                .map(|option| DetachmentOptionView {
                    troop_kind: option.troop_kind(),
                    destination: option.destination(),
                })
                .collect(),
        },
    ))
}

fn merchant_destination(
    option: &aonw_engine::MerchantDestinationOption,
) -> MerchantDestinationView {
    MerchantDestinationView {
        city_id: option.city_id().clone(),
        total_cost: MovementUnits::new(option.total_cost_units()),
    }
}
