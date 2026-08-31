use std::collections::BTreeSet;

use aonw_content::{CityBalance, MapDefinition, TerrainType};
use aonw_domain::{City, CityFoundingJob, GameState, HexCoord, TroopKind, Unit, UnitId, UnitKind};

use super::CityRuleError;
use crate::{CommandRejectionCode, EngineContext};

pub(super) fn validate_founder_start<'state>(
    state: &'state GameState,
    context: EngineContext<'_>,
    founder_id: &UnitId,
) -> Result<&'state Unit, CityRuleError> {
    let founder = state
        .unit(founder_id)
        .ok_or(CommandRejectionCode::CityFounderNotFound)?;
    if !context.can_act() || founder.owner_player_id() != context.actor_player_id() {
        return Err(CommandRejectionCode::CityFounderNotControlled.into());
    }
    if founder.activity().blocks_manual_movement() {
        return Err(CommandRejectionCode::CityFounderBusy.into());
    }
    if !can_found_city(founder) {
        return Err(if founder.kind() == UnitKind::Commander {
            CommandRejectionCode::CityFounderNoSettlers
        } else {
            CommandRejectionCode::CityFounderInvalid
        }
        .into());
    }
    let center = founder.position();
    let tile = context
        .map()
        .tile_at(center)
        .ok_or(CommandRejectionCode::CitySiteInvalid)?;
    if matches!(
        tile.yield_terrain(),
        TerrainType::Ocean | TerrainType::Lake | TerrainType::Mountain
    ) {
        return Err(CommandRejectionCode::CitySiteInvalid.into());
    }
    if state.cities().iter().any(|city| city.center() == center) {
        return Err(CommandRejectionCode::CityCenterOccupied.into());
    }
    if state
        .cities()
        .iter()
        .any(|city| city.controlled_hexes().contains(&center))
    {
        return Err(CommandRejectionCode::CityCenterClaimed.into());
    }
    let minimum = u64::from(context.ruleset().city().minimum_center_distance());
    if state
        .cities()
        .iter()
        .any(|city| city.center().distance_to(center) < minimum)
    {
        return Err(CommandRejectionCode::CityCenterTooClose.into());
    }
    Ok(founder)
}

pub(super) fn validate_controlled_hexes(
    center: HexCoord,
    selected: &[HexCoord],
    cities: &[City],
    map: &MapDefinition,
    required: u32,
    maximum_radius: u32,
) -> Result<(), CityRuleError> {
    if selected.len() != usize::try_from(required).unwrap_or(usize::MAX)
        || selected.iter().copied().collect::<BTreeSet<_>>().len() != selected.len()
        || !territory_connected(center, selected)
        || selected.iter().any(|coordinate| {
            !valid_founding_candidate(center, *coordinate, cities, map, maximum_radius)
        })
    {
        return Err(CommandRejectionCode::CityControlledHexesInvalid.into());
    }
    Ok(())
}

pub(super) fn valid_founding_candidate(
    center: HexCoord,
    target: HexCoord,
    cities: &[City],
    map: &MapDefinition,
    maximum_radius: u32,
) -> bool {
    target != center
        && map.tile_at(target).is_some()
        && center.distance_to(target) <= u64::from(maximum_radius)
        && !cities.iter().any(|city| city.controls(target))
}

pub(super) fn territory_connected(center: HexCoord, selected: &[HexCoord]) -> bool {
    let territory = std::iter::once(center)
        .chain(selected.iter().copied())
        .collect::<BTreeSet<_>>();
    let mut visited = BTreeSet::from([center]);
    let mut frontier = vec![center];
    while let Some(current) = frontier.pop() {
        for neighbor in current.neighbors() {
            if territory.contains(&neighbor) && visited.insert(neighbor) {
                frontier.push(neighbor);
            }
        }
    }
    visited.len() == territory.len()
}

pub(super) fn selectable_founding_hexes(
    center: HexCoord,
    selected: &[HexCoord],
    cities: &[City],
    map: &MapDefinition,
    required: u32,
    maximum_radius: u32,
) -> Vec<HexCoord> {
    if selected.len() >= usize::try_from(required).unwrap_or(usize::MAX)
        || !territory_connected(center, selected)
    {
        return Vec::new();
    }
    let selected_set = selected.iter().copied().collect::<BTreeSet<_>>();
    let mut candidates = BTreeSet::new();
    for coordinate in std::iter::once(center).chain(selected.iter().copied()) {
        for candidate in coordinate.neighbors() {
            if !selected_set.contains(&candidate)
                && valid_founding_candidate(center, candidate, cities, map, maximum_radius)
            {
                candidates.insert(candidate);
            }
        }
    }
    candidates.into_iter().collect()
}

pub(super) fn can_complete_founding(
    center: HexCoord,
    selected: &[HexCoord],
    cities: &[City],
    map: &MapDefinition,
    required: u32,
    maximum_radius: u32,
) -> bool {
    if selected.len() == usize::try_from(required).unwrap_or(usize::MAX) {
        return territory_connected(center, selected);
    }
    selectable_founding_hexes(center, selected, cities, map, required, maximum_radius)
        .into_iter()
        .any(|candidate| {
            let mut next = selected.to_vec();
            next.push(candidate);
            can_complete_founding(center, &next, cities, map, required, maximum_radius)
        })
}

fn can_found_city(unit: &Unit) -> bool {
    unit.kind() == UnitKind::Settler
        || unit.kind() == UnitKind::Commander
            && unit
                .army()
                .iter()
                .any(|troop| troop.kind() == TroopKind::Settler && troop.count() > 0)
}

pub(crate) fn founding_job_is_valid(
    unit: &Unit,
    cities: &[City],
    map: &MapDefinition,
    balance: CityBalance,
    job: &CityFoundingJob,
) -> bool {
    if unit.position() != job.center() || !can_found_city(unit) {
        return false;
    }
    let Some(tile) = map.tile_at(job.center()) else {
        return false;
    };
    if matches!(
        tile.yield_terrain(),
        TerrainType::Ocean | TerrainType::Lake | TerrainType::Mountain
    ) || cities.iter().any(|city| city.controls(job.center()))
        || cities.iter().any(|city| {
            city.center().distance_to(job.center()) < u64::from(balance.minimum_center_distance())
        })
    {
        return false;
    }
    validate_controlled_hexes(
        job.center(),
        job.controlled_hexes(),
        cities,
        map,
        balance.founding_controlled_hexes(),
        balance.founding_max_radius(),
    )
    .is_ok()
}
