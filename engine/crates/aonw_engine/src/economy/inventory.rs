use aonw_domain::{City, GameState, PlayerResearchState, ResourceType};

use crate::{EngineContext, TechnologyUnlockQuery};

use super::{
    EconomyQueryError, StrategicResourceAllocation, StrategicResourceBalance,
    StrategicResourceDeposit, StrategicResourceInventory, StrategicResourceProjection,
    rules::{domain_resource, strategic_resource_projection_for_player},
    strategic_resource_shortages,
};

const RESOURCES: [ResourceType; 7] = [
    ResourceType::Iron,
    ResourceType::Coal,
    ResourceType::Oil,
    ResourceType::Aluminium,
    ResourceType::Uranium,
    ResourceType::Horses,
    ResourceType::Marble,
];

/// Computes the recipient's complete strategic inventory without changing state.
/// Presence availability counts domestic deposits and active import agreements;
/// stockpiled availability is the free balance, excluding committed production.
/// Trade flows describe agreements, not a guarantee of next-turn settlement.
///
/// # Errors
/// Returns an error for an unknown participant or an overflowing balance.
pub fn strategic_resource_inventory(
    state: &GameState,
    context: EngineContext<'_>,
) -> Result<StrategicResourceInventory, EconomyQueryError> {
    let actor = context.actor_player_id();
    if !state.match_lifecycle().identity().contains(actor) {
        return Err(EconomyQueryError::ProjectionInvalid(
            "resource inventory participant is not in the match".into(),
        ));
    }
    let production = strategic_resource_projection_for_player(state, context, actor)?;
    let deposits = controlled_deposits(state, context, &production);
    let allocations = city_allocations(state, context);
    let mut balances = RESOURCES.map(StrategicResourceBalance::empty);
    for balance in &mut balances {
        fill_balance(
            state,
            context,
            balance,
            &production,
            &deposits,
            &allocations,
        )?;
    }
    for resource in strategic_resource_shortages(state, context) {
        if let Some(balance) = balances.iter_mut().find(|row| row.resource == resource) {
            balance.shortage = true;
        }
    }
    let expiring_trade_ids = state
        .diplomacy()
        .resource_trade_agreements()
        .iter()
        .filter(|trade| {
            (trade.exporter_player_id() == actor || trade.importer_player_id() == actor)
                && trade.remaining_turns() <= 2
        })
        .map(|trade| trade.id().to_owned())
        .collect::<Box<[_]>>();
    let attention_count = u32::try_from(expiring_trade_ids.len())
        .ok()
        .and_then(|count| {
            count.checked_add(balances.iter().fold(0, |sum, row| {
                sum + u32::from(row.shortage || row.no_free_stock)
            }))
        })
        .ok_or(EconomyQueryError::ArithmeticOverflow)?;
    Ok(StrategicResourceInventory {
        attention_count,
        expiring_trade_ids,
        available_type_count: balances
            .iter()
            .fold(0, |count, row| count + u8::from(row.available > 0)),
        shortage_type_count: balances
            .iter()
            .fold(0, |count, row| count + u8::from(row.shortage)),
        balances,
        allocations: allocations.into_boxed_slice(),
        deposits: deposits.into_boxed_slice(),
        production,
    })
}

fn controlled_deposits(
    state: &GameState,
    context: EngineContext<'_>,
    production: &StrategicResourceProjection,
) -> Vec<StrategicResourceDeposit> {
    let empty = PlayerResearchState::default();
    let research = state
        .research()
        .players()
        .get(context.actor_player_id())
        .unwrap_or(&empty);
    let technology = TechnologyUnlockQuery::new(context.ruleset(), research);
    let mut deposits = Vec::new();
    for city in own_cities(state, context) {
        // Canonical cities have disjoint territories and unique controlled hexes.
        let territory = core::iter::once(city.center()).chain(
            city.controlled_hexes()
                .iter()
                .copied()
                .filter(|coordinate| *coordinate != city.center()),
        );
        for coordinate in territory {
            for resource in resources_at(state, context, coordinate) {
                if technology.is_resource_revealed(resource) {
                    deposits.push(deposit(state, production, city, coordinate, resource));
                }
            }
        }
    }
    deposits.sort_unstable_by(|left, right| {
        (left.resource, &left.city_id, left.coordinate).cmp(&(
            right.resource,
            &right.city_id,
            right.coordinate,
        ))
    });
    deposits
}

fn resources_at<'a>(
    state: &'a GameState,
    context: EngineContext<'a>,
    coordinate: aonw_domain::HexCoord,
) -> impl Iterator<Item = ResourceType> + 'a {
    let tile_resources = context
        .map()
        .tile_at(coordinate)
        .map_or(&[][..], aonw_content::TileDefinition::resources);
    let placements = state.economy().initial_resource_distribution().placements();
    let placed = placements
        .binary_search_by_key(&coordinate, |placement| placement.coordinate())
        .ok()
        .map(|index| placements[index].resource());
    RESOURCES.into_iter().filter(move |resource| {
        placed == Some(*resource)
            || tile_resources
                .iter()
                .any(|value| domain_resource(*value) == *resource)
    })
}

fn deposit(
    state: &GameState,
    production: &StrategicResourceProjection,
    city: &City,
    coordinate: aonw_domain::HexCoord,
    resource: ResourceType,
) -> StrategicResourceDeposit {
    let improvement = state
        .infrastructure()
        .field_improvement_at(coordinate)
        .map(aonw_domain::FieldImprovement::kind);
    let amount_per_turn = production
        .sources()
        .iter()
        .find(|source| {
            source.city_id() == city.id()
                && source.coordinate() == coordinate
                && source.resource() == resource
        })
        .map(super::StrategicResourceSource::amount_per_turn);
    StrategicResourceDeposit {
        city_id: city.id().clone(),
        coordinate,
        resource,
        improvement,
        amount_per_turn,
    }
}

fn city_allocations(
    state: &GameState,
    context: EngineContext<'_>,
) -> Vec<StrategicResourceAllocation> {
    own_cities(state, context)
        .flat_map(|city| {
            city.production_queue().into_iter().flat_map(move |queue| {
                queue
                    .resource_allocation()
                    .amounts()
                    .iter()
                    .map(move |(resource, amount)| StrategicResourceAllocation {
                        city_id: city.id().clone(),
                        resource: *resource,
                        amount: *amount,
                    })
            })
        })
        .collect()
}

fn own_cities<'a>(
    state: &'a GameState,
    context: EngineContext<'a>,
) -> impl Iterator<Item = &'a City> {
    state
        .cities()
        .iter()
        .filter(move |city| city.owner_player_id() == context.actor_player_id())
}

fn fill_balance(
    state: &GameState,
    context: EngineContext<'_>,
    balance: &mut StrategicResourceBalance,
    production: &StrategicResourceProjection,
    deposits: &[StrategicResourceDeposit],
    allocations: &[StrategicResourceAllocation],
) -> Result<(), EconomyQueryError> {
    let actor = context.actor_player_id();
    let resource = balance.resource;
    balance.controlled_deposits = i64::try_from(
        deposits
            .iter()
            .filter(|row| row.resource == resource)
            .count(),
    )
    .map_err(|_| EconomyQueryError::ArithmeticOverflow)?;
    balance.allocated = checked_sum(
        allocations
            .iter()
            .filter(|row| row.resource == resource)
            .map(|row| row.amount),
    )?;
    balance.domestic_production = production.output().get(&resource).copied().unwrap_or(0);
    let trades = || {
        state
            .diplomacy()
            .resource_trade_agreements()
            .iter()
            .filter(|trade| trade.resource() == resource)
    };
    let imports = || trades().filter(|trade| trade.importer_player_id() == actor);
    balance.imports = checked_sum(imports().map(|trade| i64::from(trade.amount_per_turn())))?;
    balance.exports = checked_sum(
        trades()
            .filter(|trade| trade.exporter_player_id() == actor)
            .map(|trade| i64::from(trade.amount_per_turn())),
    )?;
    balance.available = if balance.stockpiled {
        state
            .economy()
            .strategic_resources()
            .get(actor)
            .and_then(|stockpile| stockpile.amounts().get(&resource))
            .copied()
            .unwrap_or(0)
    } else {
        checked_sum(core::iter::once(balance.controlled_deposits).chain(imports().map(|_| 1)))?
    };
    balance.stored_total = checked_sum([balance.available, balance.allocated])?;
    balance.no_free_stock = balance.available == 0 && balance.allocated > 0;
    balance.net_per_turn = checked_sum([
        balance.domestic_production,
        balance.imports,
        -balance.exports,
    ])?;
    balance.source_count = if balance.stockpiled {
        i64::try_from(
            production
                .sources()
                .iter()
                .filter(|source| source.resource() == resource)
                .count(),
        )
        .map_err(|_| EconomyQueryError::ArithmeticOverflow)?
    } else {
        balance.controlled_deposits
    };
    Ok(())
}

fn checked_sum(values: impl IntoIterator<Item = i64>) -> Result<i64, EconomyQueryError> {
    values.into_iter().try_fold(0_i64, |sum, value| {
        sum.checked_add(value)
            .ok_or(EconomyQueryError::ArithmeticOverflow)
    })
}
