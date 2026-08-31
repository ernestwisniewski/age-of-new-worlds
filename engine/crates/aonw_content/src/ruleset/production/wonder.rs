use aonw_domain::WonderType as Wonder;

use crate::{ResourceType as Resource, TerrainType as Terrain};

use super::{EconomyYield, ProductionRequirement, WonderProductionDefinition};

const NONE: &[ProductionRequirement] = &[];
const RIVER: &[ProductionRequirement] = &[ProductionRequirement::AdjacentRiver];
const MOUNTAIN: &[ProductionRequirement] = &[ProductionRequirement::AdjacentMountain];
const DESERT: &[ProductionRequirement] =
    &[ProductionRequirement::HostTerrainAny(&[Terrain::Desert])];
const SNOW: &[ProductionRequirement] = &[ProductionRequirement::HostTerrainAny(&[Terrain::Snow])];
const MARBLE: &[ProductionRequirement] = &[ProductionRequirement::ResourceAny(&[Resource::Marble])];
const COAL_OR_IRON: &[ProductionRequirement] = &[ProductionRequirement::ResourceAny(&[
    Resource::Coal,
    Resource::Iron,
])];
const ZERO: EconomyYield = EconomyYield::new(0, 0, 0, 0);

#[derive(Clone, Copy)]
struct StandingEffects {
    host_yield: EconomyYield,
    empire_yield_per_city: EconomyYield,
    empire_science_per_city: i64,
    empire_gold_basis_points: u32,
    empire_production_basis_points: u32,
    stability_delta: i64,
}

#[derive(Clone, Copy)]
struct CompletionEffects {
    grant_free_active_technology: bool,
    production_burst: i64,
    grant_gold: i64,
}

const fn standing(
    host_yield: EconomyYield,
    empire_yield_per_city: EconomyYield,
    empire_science_per_city: i64,
    empire_gold_basis_points: u32,
    empire_production_basis_points: u32,
    stability_delta: i64,
) -> StandingEffects {
    StandingEffects {
        host_yield,
        empire_yield_per_city,
        empire_science_per_city,
        empire_gold_basis_points,
        empire_production_basis_points,
        stability_delta,
    }
}

const fn completion(
    grant_free_active_technology: bool,
    production_burst: i64,
    grant_gold: i64,
) -> CompletionEffects {
    CompletionEffects {
        grant_free_active_technology,
        production_burst,
        grant_gold,
    }
}

const fn definition(
    wonder: Wonder,
    base_cost: i64,
    requirements: &'static [ProductionRequirement],
    standing: StandingEffects,
    completion: CompletionEffects,
) -> WonderProductionDefinition {
    WonderProductionDefinition {
        wonder,
        base_cost,
        requirements,
        host_yield: standing.host_yield,
        empire_yield_per_city: standing.empire_yield_per_city,
        empire_science_per_city: standing.empire_science_per_city,
        empire_gold_basis_points: standing.empire_gold_basis_points,
        empire_production_basis_points: standing.empire_production_basis_points,
        stability_delta: standing.stability_delta,
        grant_free_active_technology: completion.grant_free_active_technology,
        production_burst: completion.production_burst,
        grant_gold: completion.grant_gold,
    }
}

pub(super) const STANDARD_WONDERS: [WonderProductionDefinition; 11] = [
    definition(
        Wonder::GreatLibrary,
        120,
        NONE,
        standing(ZERO, ZERO, 1, 0, 0, 0),
        completion(true, 0, 0),
    ),
    definition(
        Wonder::HangingGardens,
        120,
        RIVER,
        standing(
            EconomyYield::new(2, 0, 0, 0),
            EconomyYield::new(1, 0, 0, 0),
            0,
            0,
            0,
            0,
        ),
        completion(false, 0, 0),
    ),
    definition(
        Wonder::GreatWall,
        140,
        NONE,
        standing(ZERO, EconomyYield::new(0, 0, 0, 3), 0, 0, 0, 0),
        completion(false, 0, 0),
    ),
    definition(
        Wonder::Petra,
        150,
        DESERT,
        standing(EconomyYield::new(2, 2, 1, 0), ZERO, 0, 0, 0, 0),
        completion(false, 0, 0),
    ),
    definition(
        Wonder::CentralBank,
        220,
        NONE,
        standing(ZERO, ZERO, 0, 1_500, 0, 0),
        completion(false, 0, 120),
    ),
    definition(
        Wonder::ImperialUniversity,
        240,
        NONE,
        standing(ZERO, ZERO, 2, 0, 0, 0),
        completion(false, 0, 0),
    ),
    definition(
        Wonder::GrandCathedral,
        200,
        MARBLE,
        standing(ZERO, ZERO, 0, 0, 0, 4),
        completion(false, 0, 0),
    ),
    definition(
        Wonder::MotherFactory,
        360,
        COAL_OR_IRON,
        standing(ZERO, ZERO, 0, 0, 1_000, 0),
        completion(false, 80, 0),
    ),
    definition(
        Wonder::NationalObservatory,
        380,
        MOUNTAIN,
        standing(ZERO, ZERO, 3, 0, 0, 0),
        completion(false, 0, 0),
    ),
    definition(
        Wonder::SvalbardSeedVault,
        340,
        SNOW,
        standing(ZERO, EconomyYield::new(1, 0, 0, 0), 0, 0, 0, 3),
        completion(false, 0, 0),
    ),
    definition(
        Wonder::GrandExposition,
        400,
        NONE,
        standing(ZERO, EconomyYield::new(0, 0, 2, 0), 0, 0, 0, 2),
        completion(false, 0, 0),
    ),
];

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn runtime_constructors_preserve_wonder_data() {
        let standing = standing(
            std::hint::black_box(EconomyYield::new(1, 2, 3, 4)),
            EconomyYield::new(5, 6, 7, 8),
            9,
            10,
            11,
            12,
        );
        let completion = completion(std::hint::black_box(true), 13, 14);
        let definition = definition(
            std::hint::black_box(Wonder::GreatLibrary),
            std::hint::black_box(15),
            NONE,
            standing,
            completion,
        );
        assert_eq!(definition.wonder(), Wonder::GreatLibrary);
        assert_eq!(definition.base_cost(), 15);
        assert_eq!(definition.host_yield(), EconomyYield::new(1, 2, 3, 4));
        assert_eq!(
            definition.empire_yield_per_city(),
            EconomyYield::new(5, 6, 7, 8)
        );
        assert_eq!(definition.empire_science_per_city(), 9);
        assert_eq!(definition.empire_gold_basis_points(), 10);
        assert_eq!(definition.empire_production_basis_points(), 11);
        assert_eq!(definition.stability_delta(), 12);
        assert!(definition.grants_free_active_technology());
        assert_eq!(definition.production_burst(), 13);
        assert_eq!(definition.grant_gold(), 14);
    }
}
