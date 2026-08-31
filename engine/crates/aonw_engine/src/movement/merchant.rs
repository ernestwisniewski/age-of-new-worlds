use aonw_domain::{
    City, CityId, GameState, MerchantTradeRoute, QueuedMovePath, Unit, UnitKind, UnitPosture,
};

use super::TerrainMovementPlan;
use super::auto_explore::validate_revision;
use super::logistics::{
    AssignMerchantTradeRouteCommand, MerchantDestinationOption, MoveMerchantToCityCommand,
    MovementLogisticsError, MovementLogisticsUpdate,
};
use super::query::plan_route_for_unit;
use crate::{
    CommandRejectionCode, DomainEvent, EngineContext, LogisticsExecution,
    MerchantRouteAssignedEvent, MerchantTravelQueuedEvent,
};

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub(super) enum MerchantPlanKind {
    CyclicRoute,
    ExplicitTravel,
}

pub(crate) fn apply_assign_route(
    state: &GameState,
    context: EngineContext<'_>,
    command: AssignMerchantTradeRouteCommand<'_>,
) -> Result<MovementLogisticsUpdate, MovementLogisticsError> {
    validate_revision(state, command.expected_revision())?;
    let merchant = controlled_merchant(state, context, command.unit_id())?;
    validate_available(merchant, MerchantPlanKind::CyclicRoute)?;
    let origin = origin_city(state, merchant)
        .ok_or_else(|| MovementLogisticsError::new(CommandRejectionCode::MerchantNotInCity))?;
    let destination = destination_city(state, merchant, command.destination_city_id())?;
    if destination.id() == origin.id() {
        return Err(MovementLogisticsError::new(
            CommandRejectionCode::DestinationCityIsOrigin,
        ));
    }
    let plan = plan_to_city(
        state.revision().get(),
        state.units(),
        context,
        merchant,
        destination,
        MerchantPlanKind::CyclicRoute,
    )?;
    let route = route_from_plan(
        context,
        origin.id().clone(),
        destination.id().clone(),
        &plan,
    );
    let updated = merchant.after_merchant_route_assigned(route.clone());
    let revision = next_revision(state)?;
    let mut units = state.units().to_vec();
    replace_unit(&mut units, updated)?;
    Ok(MovementLogisticsUpdate {
        revision,
        units,
        fog_of_war: state.fog_of_war().clone(),
        diplomacy: state.diplomacy().clone(),
        interaction: state.interaction().clone().without_unit(merchant.id()),
        events: vec![DomainEvent::MerchantRouteAssigned(
            MerchantRouteAssignedEvent::new(
                merchant.id().clone(),
                origin.id().clone(),
                destination.id().clone(),
            ),
        )]
        .into_boxed_slice(),
        evidence: LogisticsExecution::MerchantRouteAssigned {
            unit_id: merchant.id().clone(),
            origin_city_id: origin.id().clone(),
            destination_city_id: destination.id().clone(),
            steps: route.steps().to_vec().into_boxed_slice(),
            transport_network_fingerprint: route.transport_network_fingerprint().into(),
        },
    })
}

pub(crate) fn apply_move_to_city(
    state: &GameState,
    context: EngineContext<'_>,
    command: MoveMerchantToCityCommand<'_>,
) -> Result<MovementLogisticsUpdate, MovementLogisticsError> {
    validate_revision(state, command.expected_revision())?;
    let merchant = controlled_merchant(state, context, command.unit_id())?;
    validate_available(merchant, MerchantPlanKind::ExplicitTravel)?;
    let destination = destination_city(state, merchant, command.destination_city_id())?;
    if destination.center() == merchant.position() {
        return Err(MovementLogisticsError::new(
            CommandRejectionCode::DestinationCityIsCurrent,
        ));
    }
    let plan = plan_to_city(
        state.revision().get(),
        state.units(),
        context,
        merchant,
        destination,
        MerchantPlanKind::ExplicitTravel,
    )?;
    let path =
        QueuedMovePath::try_new(destination.center(), plan.steps().to_vec()).map_err(|_| {
            MovementLogisticsError::new(CommandRejectionCode::InvalidQueuedMovementPath)
        })?;
    let updated = merchant
        .after_merchant_travel_queued(path)
        .map_err(|_| MovementLogisticsError::new(CommandRejectionCode::InvalidUnit))?;
    let revision = next_revision(state)?;
    let mut units = state.units().to_vec();
    replace_unit(&mut units, updated)?;
    Ok(MovementLogisticsUpdate {
        revision,
        units,
        fog_of_war: state.fog_of_war().clone(),
        diplomacy: state.diplomacy().clone(),
        interaction: state.interaction().clone().without_unit(merchant.id()),
        events: vec![DomainEvent::MerchantTravelQueued(
            MerchantTravelQueuedEvent::new(merchant.id().clone(), destination.id().clone()),
        )]
        .into_boxed_slice(),
        evidence: LogisticsExecution::MerchantTravelQueued {
            unit_id: merchant.id().clone(),
            destination_city_id: destination.id().clone(),
            steps: plan.steps().to_vec().into_boxed_slice(),
        },
    })
}

pub(super) fn route_destinations(
    state: &GameState,
    context: EngineContext<'_>,
    merchant: &Unit,
) -> Vec<MerchantDestinationOption> {
    let Some(origin) = origin_city(state, merchant) else {
        return Vec::new();
    };
    state
        .cities()
        .iter()
        .filter(|city| {
            city.owner_player_id() == merchant.owner_player_id() && city.id() != origin.id()
        })
        .filter_map(|city| {
            plan_to_city(
                state.revision().get(),
                state.units(),
                context,
                merchant,
                city,
                MerchantPlanKind::CyclicRoute,
            )
            .ok()
            .map(|plan| MerchantDestinationOption {
                city_id: city.id().clone(),
                total_cost_units: plan.total_cost().get(),
            })
        })
        .collect()
}

pub(super) fn travel_destinations(
    state: &GameState,
    context: EngineContext<'_>,
    merchant: &Unit,
) -> Vec<MerchantDestinationOption> {
    state
        .cities()
        .iter()
        .filter(|city| {
            city.owner_player_id() == merchant.owner_player_id()
                && city.center() != merchant.position()
        })
        .filter_map(|city| {
            plan_to_city(
                state.revision().get(),
                state.units(),
                context,
                merchant,
                city,
                MerchantPlanKind::ExplicitTravel,
            )
            .ok()
            .map(|plan| MerchantDestinationOption {
                city_id: city.id().clone(),
                total_cost_units: plan.total_cost().get(),
            })
        })
        .collect()
}

pub(super) fn plan_to_city(
    revision: u64,
    units: &[Unit],
    context: EngineContext<'_>,
    merchant: &Unit,
    destination: &City,
    kind: MerchantPlanKind,
) -> Result<TerrainMovementPlan, MovementLogisticsError> {
    let code = match kind {
        MerchantPlanKind::CyclicRoute => CommandRejectionCode::MerchantRouteNotFound,
        MerchantPlanKind::ExplicitTravel => CommandRejectionCode::MerchantCityPathNotFound,
    };
    plan_route_for_unit(
        revision,
        units,
        context
            .with_unrestricted_hidden_pathing()
            .with_owned_city_stacking(),
        merchant,
        destination.center(),
        merchant.movement_units(),
        false,
    )
    .map_err(|_| MovementLogisticsError::new(code))
}

pub(super) fn route_from_plan(
    context: EngineContext<'_>,
    origin_city_id: CityId,
    destination_city_id: CityId,
    plan: &TerrainMovementPlan,
) -> MerchantTradeRoute {
    MerchantTradeRoute::new(
        origin_city_id,
        destination_city_id,
        plan.steps().iter().copied(),
        context.routing_fingerprint(),
    )
}

fn controlled_merchant<'state>(
    state: &'state GameState,
    context: EngineContext<'_>,
    unit_id: &aonw_domain::UnitId,
) -> Result<&'state Unit, MovementLogisticsError> {
    let unit = state
        .unit(unit_id)
        .ok_or_else(|| MovementLogisticsError::new(CommandRejectionCode::UnitNotFound))?;
    if !context.can_act() || unit.owner_player_id() != context.actor_player_id() {
        return Err(MovementLogisticsError::new(
            CommandRejectionCode::UnitNotControlled,
        ));
    }
    if unit.kind() != UnitKind::Merchant {
        return Err(MovementLogisticsError::new(
            CommandRejectionCode::UnitNotMerchant,
        ));
    }
    Ok(unit)
}

fn validate_available(
    merchant: &Unit,
    kind: MerchantPlanKind,
) -> Result<(), MovementLogisticsError> {
    let route_conflict =
        kind == MerchantPlanKind::ExplicitTravel && merchant.merchant_trade_route().is_some();
    if merchant.activity().blocks_manual_movement()
        || merchant.posture() == UnitPosture::Fortified
        || route_conflict
    {
        return Err(MovementLogisticsError::new(
            CommandRejectionCode::UnitUnavailable,
        ));
    }
    Ok(())
}

fn origin_city<'state>(state: &'state GameState, merchant: &Unit) -> Option<&'state City> {
    state.cities().iter().find(|city| {
        city.owner_player_id() == merchant.owner_player_id() && city.center() == merchant.position()
    })
}

fn destination_city<'state>(
    state: &'state GameState,
    merchant: &Unit,
    city_id: &CityId,
) -> Result<&'state City, MovementLogisticsError> {
    let city = state.city(city_id).ok_or_else(|| {
        MovementLogisticsError::new(CommandRejectionCode::DestinationCityNotFound)
    })?;
    if city.owner_player_id() != merchant.owner_player_id() {
        return Err(MovementLogisticsError::new(
            CommandRejectionCode::DestinationCityNotControlled,
        ));
    }
    Ok(city)
}

fn next_revision(state: &GameState) -> Result<aonw_domain::StateRevision, MovementLogisticsError> {
    state
        .revision()
        .checked_next()
        .ok_or_else(|| MovementLogisticsError::new(CommandRejectionCode::StateRevisionOverflow))
}

fn replace_unit(units: &mut [Unit], updated: Unit) -> Result<(), MovementLogisticsError> {
    let target = units
        .iter_mut()
        .find(|unit| unit.id() == updated.id())
        .ok_or_else(|| {
            MovementLogisticsError::new(CommandRejectionCode::MovementUnitUpdateFailed)
        })?;
    *target = updated;
    Ok(())
}
