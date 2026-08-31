use aonw_domain::{GameState, UnitKind, UnitPosture};

use super::MovementSearchWorkspace;
use super::auto_explore::{plan_auto_explore, validate_revision};
use super::detachment::detachment_options;
use super::logistics::{MovementLogisticsError, UnitLogisticsOptions, UnitLogisticsOptionsQuery};
use super::merchant::{route_destinations, travel_destinations};
use crate::{CommandRejectionCode, EngineContext};

pub(crate) fn query_logistics_options(
    state: &GameState,
    context: EngineContext<'_>,
    query: UnitLogisticsOptionsQuery<'_>,
    workspace: &mut MovementSearchWorkspace,
) -> Result<UnitLogisticsOptions, MovementLogisticsError> {
    validate_revision(state, query.expected_revision())?;
    let unit = state
        .unit(query.unit_id())
        .ok_or_else(|| MovementLogisticsError::new(CommandRejectionCode::UnitNotFound))?;
    if !context.can_act() || unit.owner_player_id() != context.actor_player_id() {
        return Err(MovementLogisticsError::new(
            CommandRejectionCode::UnitNotControlled,
        ));
    }
    let auto_explore = (unit.kind() == UnitKind::Scout)
        .then(|| plan_auto_explore(state, context, unit, workspace).ok())
        .flatten()
        .map(|planned| planned.option);
    let merchant_available = unit.kind() == UnitKind::Merchant
        && !unit.activity().blocks_manual_movement()
        && unit.posture() != UnitPosture::Fortified;
    let merchant_route_destinations = if merchant_available {
        route_destinations(state, context, unit)
    } else {
        Vec::new()
    };
    let merchant_travel_destinations =
        if merchant_available && unit.merchant_trade_route().is_none() {
            travel_destinations(state, context, unit)
        } else {
            Vec::new()
        };
    let detachments = if context.map().tile_at(unit.position()).is_some() {
        detachment_options(state, context, unit)
    } else {
        Vec::new()
    };
    Ok(UnitLogisticsOptions {
        revision: state.revision().get(),
        unit_id: unit.id().clone(),
        auto_explore,
        merchant_route_destinations: merchant_route_destinations.into_boxed_slice(),
        merchant_travel_destinations: merchant_travel_destinations.into_boxed_slice(),
        detachments: detachments.into_boxed_slice(),
    })
}
