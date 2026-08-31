use aonw_content::TerrainType;
use aonw_domain::{City, Unit, UnitId, UnitKind, UnitMovementDomain, UnitOccupancyPolicy};

use super::ProductionError;
use super::support::{invalid, spawn_candidates};
use crate::{EngineContext, MovementCost, maximum_movement_units, terrain_entry_cost};

pub(super) fn produced_unit(
    context: EngineContext<'_>,
    city: &City,
    kind: UnitKind,
    current_units: &[Unit],
    occupancy_policy: UnitOccupancyPolicy,
) -> Result<Option<Unit>, ProductionError> {
    let definition = context
        .ruleset()
        .unit(kind)
        .ok_or_else(|| invalid("produced unit is absent from ruleset content"))?;
    let domain = definition.capabilities().movement_domain.domain();
    let position = spawn_candidates(context, city).find(|candidate| {
        let can_share_city_center = kind == UnitKind::Merchant
            && *candidate == city.center()
            && current_units
                .iter()
                .filter(|unit| unit.position() == *candidate)
                .all(|unit| {
                    occupancy_policy.permits(city.owner_player_id(), unit.owner_player_id())
                });
        let occupied = current_units
            .iter()
            .any(|unit| unit.position() == *candidate);
        if occupied && !can_share_city_center {
            return false;
        }
        can_spawn_at(context, *candidate, domain)
    });
    let Some(position) = position else {
        return Ok(None);
    };
    let id = next_unit_id(current_units, city, kind)?;
    let worker_charges = u32::from(kind == UnitKind::Worker);
    Unit::builder(
        id,
        city.owner_player_id().clone(),
        kind,
        unit_name(kind),
        position,
        maximum_movement_units(context.ruleset(), kind, false),
    )
    .with_worker_build_charges(worker_charges)
    .build()
    .map(Some)
    .map_err(|error| invalid(error.to_string()))
}

fn can_spawn_at(
    context: EngineContext<'_>,
    coordinate: aonw_domain::HexCoord,
    domain: UnitMovementDomain,
) -> bool {
    let Some(tile) = context.map().tile_at(coordinate) else {
        return false;
    };
    if domain == UnitMovementDomain::Naval
        && (!tile.terrain_tags().contains(&TerrainType::Coast)
            || !coordinate.neighbors().any(|neighbor| {
                context
                    .map()
                    .tile_at(neighbor)
                    .is_some_and(|neighbor_tile| {
                        neighbor_tile.terrain_tags().contains(&TerrainType::Ocean)
                    })
            }))
    {
        return false;
    }
    matches!(terrain_entry_cost(tile, domain), MovementCost::Passable(_))
}

fn next_unit_id(units: &[Unit], city: &City, kind: UnitKind) -> Result<UnitId, ProductionError> {
    let prefix = format!("{}_{}", city.id().as_str(), unit_name(kind));
    for index in 1_u64..=u64::MAX {
        let candidate =
            UnitId::new(format!("{prefix}_{index}")).map_err(|error| invalid(error.to_string()))?;
        if units.iter().all(|unit| unit.id() != &candidate) {
            return Ok(candidate);
        }
    }
    Err(invalid("produced unit identifier space exhausted"))
}

const fn unit_name(kind: UnitKind) -> &'static str {
    match kind {
        UnitKind::Commander => "commander",
        UnitKind::Warrior => "warrior",
        UnitKind::Archer => "archer",
        UnitKind::Settler => "settler",
        UnitKind::Worker => "worker",
        UnitKind::Merchant => "merchant",
        UnitKind::Scout => "scout",
        UnitKind::Spearman => "spearman",
        UnitKind::Cavalry => "cavalry",
        UnitKind::Catapult => "catapult",
        UnitKind::HeavyInfantry => "heavyInfantry",
        UnitKind::FieldCannon => "fieldCannon",
        UnitKind::Rifleman => "rifleman",
        UnitKind::Tank => "tank",
        UnitKind::ScoutShip => "scoutShip",
        UnitKind::Warship => "warship",
        UnitKind::ReconPlane => "reconPlane",
    }
}

#[cfg(test)]
mod tests {
    use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
    use aonw_domain::{HexCoord, PlayerId, UnitKind, UnitMovementDomain};

    use super::{can_spawn_at, unit_name};
    use crate::EngineContext;

    #[test]
    fn unit_names_cover_every_identity() {
        let names = [
            (UnitKind::Commander, "commander"),
            (UnitKind::Warrior, "warrior"),
            (UnitKind::Archer, "archer"),
            (UnitKind::Settler, "settler"),
            (UnitKind::Worker, "worker"),
            (UnitKind::Merchant, "merchant"),
            (UnitKind::Scout, "scout"),
            (UnitKind::Spearman, "spearman"),
            (UnitKind::Cavalry, "cavalry"),
            (UnitKind::Catapult, "catapult"),
            (UnitKind::HeavyInfantry, "heavyInfantry"),
            (UnitKind::FieldCannon, "fieldCannon"),
            (UnitKind::Rifleman, "rifleman"),
            (UnitKind::Tank, "tank"),
            (UnitKind::ScoutShip, "scoutShip"),
            (UnitKind::Warship, "warship"),
            (UnitKind::ReconPlane, "reconPlane"),
        ];
        for (kind, expected) in names {
            assert_eq!(unit_name(std::hint::black_box(kind)), expected);
        }
    }

    #[test]
    fn naval_spawn_requires_coast_with_an_adjacent_ocean() {
        let map = MapDefinition::try_new(
            "spawn-test",
            GridLayout::OddQFlatTop,
            3,
            3,
            (0..3)
                .flat_map(|row| {
                    (0..3).map(move |col| {
                        let coordinate = HexCoord::new(col, row);
                        let terrain = match (col, row) {
                            (1, 1) => TerrainType::Coast,
                            (2, 1) => TerrainType::Ocean,
                            _ => TerrainType::Plains,
                        };
                        TileDefinition::try_new_for_simulation(
                            coordinate,
                            vec![terrain],
                            Vec::new(),
                            0,
                        )
                        .expect("tile")
                    })
                })
                .collect(),
            Vec::new(),
        )
        .expect("map");
        let actor = PlayerId::new("player").expect("player");
        let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());

        assert!(can_spawn_at(
            context,
            HexCoord::new(1, 1),
            UnitMovementDomain::Naval
        ));
        assert!(!can_spawn_at(
            context,
            HexCoord::new(0, 0),
            UnitMovementDomain::Naval
        ));
        assert!(can_spawn_at(
            context,
            HexCoord::new(0, 0),
            UnitMovementDomain::Land
        ));
        assert!(!can_spawn_at(
            context,
            HexCoord::new(9, 9),
            UnitMovementDomain::Land
        ));
    }
}
