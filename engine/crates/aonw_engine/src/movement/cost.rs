use aonw_content::{MapDefinition, TerrainType, TileDefinition};
use aonw_domain::{HexCoord, MovementUnits, UnitMovementDomain};

use super::MovementAccess;
use super::terrain_profile::TerrainProfile;
use crate::EngineContext;

/// Result of applying terrain passability and entry-cost rules.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum MovementCost {
    /// The destination cannot be entered.
    Blocked,
    /// The destination is passable at the given fixed-point cost.
    Passable(MovementUnits),
}

/// Computes the canonical terrain cost for entering a tile.
#[must_use]
pub fn terrain_entry_cost(tile: &TileDefinition, domain: UnitMovementDomain) -> MovementCost {
    let profile = TerrainProfile::from_tile(tile);
    if profile.has_mountain() {
        return MovementCost::Blocked;
    }
    if domain == UnitMovementDomain::Naval {
        return match profile.base {
            Some(TerrainType::Coast | TerrainType::Ocean) => {
                MovementCost::Passable(MovementUnits::new(2))
            }
            _ => MovementCost::Blocked,
        };
    }

    let Some(mut cost) = base_land_cost(profile.base) else {
        return MovementCost::Blocked;
    };
    if profile.has_forest()
        && (profile.base != Some(TerrainType::Snow)
            || profile.has_jungle()
            || profile.has_wetlands()
            || profile.has_hills())
    {
        cost += MovementUnits::PER_POINT;
    }
    if profile.has_jungle() {
        cost += MovementUnits::PER_POINT;
    }
    if profile.has_wetlands() {
        cost += MovementUnits::PER_POINT;
    }
    if profile.has_hills() {
        cost += MovementUnits::PER_POINT;
    }
    MovementCost::Passable(MovementUnits::new(cost))
}

fn movement_cost_for_edge(
    from_index: usize,
    to_index: usize,
    tile: &TileDefinition,
    domain: UnitMovementDomain,
    access: &MovementAccess,
) -> MovementCost {
    let base = terrain_entry_cost(tile, domain);
    movement_cost_for_base_edge(from_index, to_index, base, domain, access)
}

fn movement_cost_for_base_edge(
    from_index: usize,
    to_index: usize,
    base: MovementCost,
    domain: UnitMovementDomain,
    access: &MovementAccess,
) -> MovementCost {
    if domain != UnitMovementDomain::Land || matches!(base, MovementCost::Blocked) {
        return base;
    }
    let from_road = access.has_known_operational_road(from_index);
    let to_road = access.has_known_operational_road(to_index);
    if (from_road || access.has_known_city_center(from_index)) && to_road
        || (from_road && access.has_known_city_center(to_index))
    {
        MovementCost::Passable(MovementUnits::new(1))
    } else {
        base
    }
}

pub(super) fn movement_cost_for_index(
    from_index: usize,
    to: HexCoord,
    to_index: usize,
    map: &MapDefinition,
    domain: UnitMovementDomain,
    context: EngineContext<'_>,
    access: &MovementAccess,
) -> MovementCost {
    if let Some(compiled) = context.compiled_movement_map() {
        return movement_cost_for_base_edge(
            from_index,
            to_index,
            compiled.entry_cost(to_index, domain),
            domain,
            access,
        );
    }
    map.tile_at(to).map_or(MovementCost::Blocked, |tile| {
        movement_cost_for_edge(from_index, to_index, tile, domain, access)
    })
}

const fn base_land_cost(base: Option<TerrainType>) -> Option<u32> {
    match base {
        Some(TerrainType::Grassland | TerrainType::Plains | TerrainType::Coast) => Some(2),
        Some(TerrainType::Desert | TerrainType::Tundra | TerrainType::Wetlands) => Some(4),
        Some(TerrainType::Snow) => Some(6),
        Some(
            TerrainType::Ocean
            | TerrainType::Lake
            | TerrainType::Forest
            | TerrainType::Jungle
            | TerrainType::Hills
            | TerrainType::Mountain
            | TerrainType::River,
        )
        | None => None,
    }
}

#[cfg(test)]
mod tests {
    use aonw_content::{TerrainType, TileDefinition};
    use aonw_domain::{HexCoord, MovementUnits, UnitMovementDomain};

    use super::{MovementCost, terrain_entry_cost};

    fn tile(terrains: Vec<TerrainType>) -> TileDefinition {
        TileDefinition::try_new_for_simulation(HexCoord::new(0, 0), terrains, Vec::new(), 0)
            .expect("valid terrain fixture")
    }

    #[test]
    fn land_costs_match_the_standard_rules() {
        assert_eq!(
            terrain_entry_cost(
                &tile(vec![TerrainType::Plains, TerrainType::Forest]),
                UnitMovementDomain::Land
            ),
            MovementCost::Passable(MovementUnits::new(4))
        );
        assert_eq!(
            terrain_entry_cost(
                &tile(vec![
                    TerrainType::Grassland,
                    TerrainType::Forest,
                    TerrainType::Hills
                ]),
                UnitMovementDomain::Land
            ),
            MovementCost::Passable(MovementUnits::new(6))
        );
        assert_eq!(
            terrain_entry_cost(&tile(vec![TerrainType::Mountain]), UnitMovementDomain::Land),
            MovementCost::Blocked
        );
    }

    #[test]
    fn primary_terrain_is_explicit() {
        assert!(
            TileDefinition::try_new_for_simulation(
                HexCoord::new(0, 0),
                vec![TerrainType::Forest],
                Vec::new(),
                0,
            )
            .is_err()
        );
    }

    #[test]
    fn naval_units_only_enter_coast_and_ocean() {
        assert_eq!(
            terrain_entry_cost(&tile(vec![TerrainType::Ocean]), UnitMovementDomain::Naval),
            MovementCost::Passable(MovementUnits::new(2))
        );
        assert_eq!(
            terrain_entry_cost(&tile(vec![TerrainType::Lake]), UnitMovementDomain::Naval),
            MovementCost::Blocked
        );
    }

    #[test]
    fn air_units_use_land_terrain_semantics() {
        assert_eq!(
            terrain_entry_cost(
                &tile(vec![TerrainType::Plains, TerrainType::Hills]),
                UnitMovementDomain::Air
            ),
            MovementCost::Passable(MovementUnits::new(4))
        );
    }
}
