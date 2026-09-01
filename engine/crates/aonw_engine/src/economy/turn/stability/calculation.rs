use std::collections::{BTreeMap, BTreeSet};

use aonw_content::{MapDefinition, RulesetDefinition, StabilityValues};
use aonw_domain::{
    City, GameState, PlayerId, UnitMovementDomain, WorldArtifactLocation, WorldArtifactType,
};

use crate::{MovementCost, StabilityBand, terrain_entry_cost};

use crate::economy::StabilityBreakdown;

use super::EconomyTurnError;

#[derive(Clone, Copy)]
pub(super) struct TerritoryShare {
    controlled: i128,
    valid: i128,
}

#[derive(Clone, Copy)]
pub(super) struct StabilityFactors {
    player_count: usize,
    values: StabilityValues,
    territory: TerritoryShare,
}

impl StabilityFactors {
    pub(super) const fn new(
        player_count: usize,
        values: StabilityValues,
        territory: TerritoryShare,
    ) -> Self {
        Self {
            player_count,
            values,
            territory,
        }
    }
}

pub(super) fn stability_breakdown(
    state: &GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    player: &PlayerId,
    war_weariness: i64,
    factors: StabilityFactors,
) -> Result<StabilityBreakdown, EconomyTurnError> {
    let StabilityFactors {
        player_count,
        values,
        territory,
    } = factors;
    let cities = state
        .cities()
        .iter()
        .filter(|city| city.owner_player_id() == player)
        .collect::<Vec<_>>();
    let metrics = city_metrics(&cities, map, ruleset, player, values)?;
    let city_cost = metrics
        .city_count
        .saturating_sub(1)
        .checked_mul(values.cost_per_city)
        .ok_or_else(|| EconomyTurnError::new("city stability cost overflow"))?;
    let building_sources = required(
        checked_mul(metrics.order_buildings, values.stability_per_order_building),
        "order building stability overflow",
    )?;
    let luxury_sources = required(
        checked_mul_usize(metrics.luxury_count, values.stability_per_luxury_resource),
        "luxury stability overflow",
    )?;
    let technology_sources = required(
        order_technology_source(state, ruleset, player, values),
        "technology stability overflow",
    )?;
    let artifact_sources = required(
        artifact_source(state, player, values),
        "artifact stability overflow",
    )?;
    let wonder_sources = required(
        wonder_source(state, ruleset, player),
        "wonder stability overflow",
    )?;
    let sources = checked_sum(
        [
            values.base_order,
            building_sources,
            luxury_sources,
            technology_sources,
            artifact_sources,
            wonder_sources,
        ],
        "stability source overflow",
    )?;
    let population_cost = required(
        checked_mul(metrics.population_over, values.cost_per_population),
        "population stability cost overflow",
    )?;
    let conquered_city_cost = required(
        checked_mul(metrics.conquered, values.conquered_city_cost),
        "conquered city stability cost overflow",
    )?;
    let hegemony_tax = hegemony_tax(territory, player_count, values)?;
    let costs = checked_sum(
        [
            city_cost,
            population_cost,
            metrics.cohesion_cost,
            conquered_city_cost,
            war_weariness,
            hegemony_tax,
        ],
        "stability cost overflow",
    )?;
    let base_net = sources
        .checked_sub(costs)
        .ok_or_else(|| EconomyTurnError::new("stability net overflow"))?;
    let standing_adjustment = relative_standing_shift(territory, player_count, values)?
        .checked_neg()
        .ok_or_else(|| EconomyTurnError::new("relative standing adjustment overflow"))?;
    let effective_net = base_net
        .checked_add(standing_adjustment)
        .ok_or_else(|| EconomyTurnError::new("effective stability overflow"))?;
    Ok(StabilityBreakdown::new(
        values.base_order,
        building_sources,
        luxury_sources,
        technology_sources,
        artifact_sources,
        wonder_sources,
        city_cost,
        population_cost,
        metrics.cohesion_cost,
        conquered_city_cost,
        war_weariness,
        hegemony_tax,
        sources,
        costs,
        standing_adjustment,
        effective_net,
        stability_band(ruleset, effective_net),
    ))
}

struct CityStabilityMetrics {
    city_count: i64,
    population_over: i64,
    cohesion_cost: i64,
    conquered: i64,
    order_buildings: i64,
    luxury_count: usize,
}

fn city_metrics(
    cities: &[&City],
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    player: &PlayerId,
    values: StabilityValues,
) -> Result<CityStabilityMetrics, EconomyTurnError> {
    let core = core_city(cities, player);
    let mut population_over = 0_i64;
    let mut cohesion_cost = 0_i64;
    let mut conquered = 0_i64;
    let mut order_buildings = 0_i64;
    let mut luxuries = Vec::new();
    for city in cities {
        if city
            .founding_owner_player_id()
            .is_some_and(|founder| founder != player)
        {
            conquered = checked_add(conquered, 1, "conquered city count overflow")?;
        }
        let over_threshold = city
            .population()
            .checked_sub(values.population_cost_threshold)
            .ok_or_else(|| EconomyTurnError::new("population threshold overflow"))?
            .max(0);
        population_over = checked_add(
            population_over,
            over_threshold,
            "population stability cost overflow",
        )?;
        if let Some(core) = core {
            cohesion_cost = checked_add(
                cohesion_cost,
                city_cohesion_cost(city, core, values)?,
                "cohesion stability cost overflow",
            )?;
        }
        let count = city
            .buildings()
            .iter()
            .filter(|building| ruleset.economy().is_order_building(**building))
            .count();
        order_buildings = checked_add(
            order_buildings,
            i64::try_from(count).map_err(EconomyTurnError::new)?,
            "order building count overflow",
        )?;
        for coordinate in
            std::iter::once(city.center()).chain(city.controlled_hexes().iter().copied())
        {
            if let Some(tile) = map.tile_at(coordinate) {
                for resource in tile
                    .resources()
                    .iter()
                    .copied()
                    .filter(|resource| ruleset.economy().is_luxury_resource(*resource))
                {
                    if !luxuries.contains(&resource) {
                        luxuries.push(resource);
                    }
                }
            }
        }
    }
    Ok(CityStabilityMetrics {
        city_count: i64::try_from(cities.len()).map_err(EconomyTurnError::new)?,
        population_over,
        cohesion_cost,
        conquered,
        order_buildings,
        luxury_count: luxuries.len(),
    })
}

pub(super) fn stability_band(ruleset: &RulesetDefinition, net: i64) -> StabilityBand {
    if net >= ruleset.economy().content_stability_threshold() {
        StabilityBand::Content
    } else if net <= ruleset.economy().unrest_stability_threshold() {
        StabilityBand::Unrest
    } else if net < 0 {
        StabilityBand::Strained
    } else {
        StabilityBand::Stable
    }
}

fn core_city<'a>(cities: &[&'a City], player: &PlayerId) -> Option<&'a City> {
    cities
        .iter()
        .copied()
        .find(|city| {
            city.founding_owner_player_id()
                .unwrap_or(city.owner_player_id())
                == player
        })
        .or_else(|| cities.iter().copied().min_by_key(|city| city.id()))
}

fn city_cohesion_cost(
    city: &City,
    core: &City,
    values: StabilityValues,
) -> Result<i64, EconomyTurnError> {
    let distance =
        i64::try_from(city.center().distance_to(core.center())).map_err(EconomyTurnError::new)?;
    let frontier = distance
        .saturating_sub(i64::from(values.cohesion_reach_radius))
        .max(0)
        .checked_mul(values.frontier_cost_per_hex)
        .ok_or_else(|| EconomyTurnError::new("frontier cohesion overflow"))?;
    let disconnected = if territory_is_connected(city) {
        0
    } else {
        values.disconnected_city_cost
    };
    frontier
        .checked_add(disconnected)
        .ok_or_else(|| EconomyTurnError::new("city cohesion overflow"))
}

fn territory_is_connected(city: &City) -> bool {
    let territory = std::iter::once(city.center())
        .chain(city.controlled_hexes().iter().copied())
        .collect::<BTreeSet<_>>();
    let Some(start) = territory.first().copied() else {
        return true;
    };
    let mut visited = BTreeSet::from([start]);
    let mut frontier = vec![start];
    while let Some(current) = frontier.pop() {
        for neighbor in current.neighbors() {
            if territory.contains(&neighbor) && visited.insert(neighbor) {
                frontier.push(neighbor);
            }
        }
    }
    visited.len() == territory.len()
}

fn order_technology_source(
    state: &GameState,
    ruleset: &RulesetDefinition,
    player: &PlayerId,
    values: StabilityValues,
) -> Option<i64> {
    let count = state
        .research()
        .players()
        .get(player)
        .map(|research| {
            research
                .unlocked_technology_ids()
                .iter()
                .filter(|technology| ruleset.economy().is_order_technology(**technology))
                .count()
        })
        .unwrap_or_default();
    checked_mul_usize(count, values.stability_per_order_technology)
}

fn artifact_source(state: &GameState, player: &PlayerId, values: StabilityValues) -> Option<i64> {
    let owned = state
        .cities()
        .iter()
        .filter(|city| city.owner_player_id() == player)
        .map(City::id)
        .collect::<BTreeSet<_>>();
    let types = state
        .artifacts()
        .iter()
        .filter_map(|artifact| match artifact.location() {
            WorldArtifactLocation::Stored(city) if owned.contains(city) => {
                Some(artifact.artifact_type())
            }
            _ => None,
        })
        .collect::<BTreeSet<WorldArtifactType>>();
    checked_mul_usize(types.len(), values.stability_per_stored_artifact)
}

fn wonder_source(state: &GameState, ruleset: &RulesetDefinition, player: &PlayerId) -> Option<i64> {
    let mut total = 0_i64;
    for (wonder, owner) in state.wonder_registry().completed_by() {
        if owner == player {
            total = total.checked_add(ruleset.production().wonder(*wonder)?.stability_delta())?;
        }
    }
    Some(total)
}

pub(super) fn territory_shares(
    state: &GameState,
    map: &MapDefinition,
    players: &BTreeSet<PlayerId>,
) -> Result<BTreeMap<PlayerId, TerritoryShare>, EconomyTurnError> {
    let mut passable = vec![false; map.bounds().tile_count()];
    let mut valid_count = 0_usize;
    for (index, tile) in map.tiles().iter().enumerate() {
        if matches!(
            terrain_entry_cost(tile, UnitMovementDomain::Land),
            MovementCost::Passable(_)
        ) {
            passable[index] = true;
            valid_count += 1;
        }
    }
    let mut controlled = players
        .iter()
        .cloned()
        .map(|player| (player, BTreeSet::new()))
        .collect::<BTreeMap<_, _>>();
    for city in state.cities() {
        let Some(coordinates) = controlled.get_mut(city.owner_player_id()) else {
            continue;
        };
        for coordinate in
            std::iter::once(city.center()).chain(city.controlled_hexes().iter().copied())
        {
            if map
                .tile_index(coordinate)
                .is_some_and(|index| passable[index.get()])
            {
                coordinates.insert(coordinate);
            }
        }
    }
    let valid = i128::try_from(valid_count).map_err(EconomyTurnError::new)?;
    controlled
        .into_iter()
        .map(|(player, coordinates)| {
            Ok((
                player,
                TerritoryShare {
                    controlled: i128::try_from(coordinates.len()).map_err(EconomyTurnError::new)?,
                    valid,
                },
            ))
        })
        .collect()
}

fn hegemony_tax(
    territory: TerritoryShare,
    player_count: usize,
    values: StabilityValues,
) -> Result<i64, EconomyTurnError> {
    if values.hegemony_tax_points_per_cost <= 0 {
        return Ok(0);
    }
    let TerritoryShare { controlled, valid } = territory;
    if valid == 0 {
        return Ok(0);
    }
    let players = i128::try_from(player_count.max(1)).map_err(EconomyTurnError::new)?;
    let scale = 10_000_i128;
    let above = controlled
        .checked_mul(scale)
        .and_then(|value| value.checked_mul(players))
        .and_then(|value| {
            i128::from(values.hegemony_k_basis_points)
                .checked_mul(valid)
                .and_then(|threshold| value.checked_sub(threshold))
        })
        .ok_or_else(|| EconomyTurnError::new("hegemony stability cost overflow"))?;
    if above <= 0 {
        return Ok(0);
    }
    let numerator = above
        .checked_mul(100)
        .ok_or_else(|| EconomyTurnError::new("hegemony stability cost overflow"))?;
    let denominator = valid
        .checked_mul(scale)
        .and_then(|value| value.checked_mul(players))
        .and_then(|value| value.checked_mul(i128::from(values.hegemony_tax_points_per_cost)))
        .ok_or_else(|| EconomyTurnError::new("hegemony stability cost overflow"))?;
    i64::try_from(numerator / denominator).map_err(EconomyTurnError::new)
}

fn relative_standing_shift(
    territory: TerritoryShare,
    player_count: usize,
    values: StabilityValues,
) -> Result<i64, EconomyTurnError> {
    let TerritoryShare { controlled, valid } = territory;
    if valid == 0 {
        return Ok(0);
    }
    let players = i128::try_from(player_count.max(1)).map_err(EconomyTurnError::new)?;
    let standing = controlled
        .checked_mul(players)
        .and_then(|value| value.checked_sub(valid))
        .ok_or_else(|| EconomyTurnError::new("relative standing overflow"))?
        .clamp(-valid, valid);
    let numerator = standing
        .checked_mul(i128::from(values.relative_standing_offset))
        .ok_or_else(|| EconomyTurnError::new("relative standing shift overflow"))?;
    i64::try_from(round_div_away_from_zero(numerator, valid)).map_err(EconomyTurnError::new)
}

fn round_div_away_from_zero(numerator: i128, denominator: i128) -> i128 {
    if numerator >= 0 {
        (numerator + denominator / 2) / denominator
    } else {
        -((-numerator + denominator / 2) / denominator)
    }
}

fn checked_mul(left: i64, right: i64) -> Option<i64> {
    left.checked_mul(right)
}

fn checked_mul_usize(left: usize, right: i64) -> Option<i64> {
    i64::try_from(left).ok()?.checked_mul(right)
}

fn checked_add(left: i64, right: i64, message: &str) -> Result<i64, EconomyTurnError> {
    left.checked_add(right)
        .ok_or_else(|| EconomyTurnError::new(message))
}

fn checked_sum(
    values: impl IntoIterator<Item = i64>,
    message: &str,
) -> Result<i64, EconomyTurnError> {
    values.into_iter().try_fold(0_i64, |total, value| {
        total
            .checked_add(value)
            .ok_or_else(|| EconomyTurnError::new(message))
    })
}

fn required(value: Option<i64>, message: &str) -> Result<i64, EconomyTurnError> {
    value.ok_or_else(|| EconomyTurnError::new(message))
}
