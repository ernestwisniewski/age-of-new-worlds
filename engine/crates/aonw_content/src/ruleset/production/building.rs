use aonw_domain::CityBuildingType as Building;

use crate::ResourceType as Resource;

use super::{BuildingProductionDefinition, EconomyYield, ProductionRequirement};

const NONE: &[ProductionRequirement] = &[];
const COAST: &[ProductionRequirement] = &[ProductionRequirement::CoastalAccess];
const MARBLE: &[ProductionRequirement] = &[ProductionRequirement::ResourceAny(&[Resource::Marble])];
const IRON: &[ProductionRequirement] = &[ProductionRequirement::ResourceAny(&[Resource::Iron])];
const HORSES: &[ProductionRequirement] = &[ProductionRequirement::ResourceAny(&[Resource::Horses])];
const PRECIOUS: &[ProductionRequirement] = &[ProductionRequirement::ResourceAny(&[
    Resource::Gold,
    Resource::Silver,
    Resource::Gems,
])];
const COAL_OR_OIL: &[ProductionRequirement] = &[ProductionRequirement::ResourceAny(&[
    Resource::Coal,
    Resource::Oil,
])];
const URANIUM: &[ProductionRequirement] =
    &[ProductionRequirement::ResourceAny(&[Resource::Uranium])];
const OIL_OR_ALUMINIUM: &[ProductionRequirement] = &[ProductionRequirement::ResourceAny(&[
    Resource::Oil,
    Resource::Aluminium,
])];
const IRON_OR_COAL: &[ProductionRequirement] = &[ProductionRequirement::ResourceAny(&[
    Resource::Iron,
    Resource::Coal,
])];
const OIL: &[ProductionRequirement] = &[ProductionRequirement::ResourceAny(&[Resource::Oil])];

const ZERO: EconomyYield = EconomyYield::new(0, 0, 0, 0);

const fn definition(
    building: Building,
    base_cost: i64,
    requirements: &'static [ProductionRequirement],
    yield_delta: EconomyYield,
    science_per_turn: i64,
    max_controlled_hexes_delta: i64,
    food_deposit_basis_points: u32,
) -> BuildingProductionDefinition {
    BuildingProductionDefinition {
        building,
        base_cost,
        requirements,
        yield_delta,
        river_yield_per_hex: ZERO,
        max_river_applications: 0,
        science_per_turn,
        max_controlled_hexes_delta,
        food_deposit_basis_points,
    }
}

const fn water_mill() -> BuildingProductionDefinition {
    BuildingProductionDefinition {
        building: Building::WaterMill,
        base_cost: 15,
        requirements: NONE,
        yield_delta: ZERO,
        river_yield_per_hex: EconomyYield::new(1, 0, 0, 0),
        max_river_applications: 3,
        science_per_turn: 0,
        max_controlled_hexes_delta: 0,
        food_deposit_basis_points: 10_000,
    }
}

// Keep the complete balance table compact and directly auditable against the content catalog.
#[rustfmt::skip]
pub(super) const STANDARD_BUILDINGS: [BuildingProductionDefinition; 59] = [
    definition(Building::Granary, 6, NONE, EconomyYield::new(2, 0, 0, 0), 0, 0, 10_000),
    water_mill(),
    definition(Building::Workshop, 15, NONE, EconomyYield::new(0, 2, 0, 0), 0, 0, 10_000),
    definition(Building::Storehouse, 12, NONE, ZERO, 0, 0, 12_000),
    definition(Building::Housing, 18, NONE, ZERO, 0, 2, 10_000),
    definition(Building::MerchantHall, 12, NONE, EconomyYield::new(0, 0, 2, 0), 0, 0, 10_000),
    definition(Building::Stonemason, 15, MARBLE, EconomyYield::new(0, 1, 0, 1), 0, 0, 10_000),
    definition(Building::Barracks, 16, NONE, EconomyYield::new(0, 1, 0, 1), 0, 0, 10_000),
    definition(Building::Marketplace, 20, NONE, EconomyYield::new(0, 0, 4, 0), 0, 0, 10_000),
    definition(Building::Port, 18, COAST, EconomyYield::new(1, 0, 2, 0), 0, 0, 10_000),
    definition(Building::Aqueduct, 20, NONE, EconomyYield::new(2, 0, 0, 0), 0, 1, 10_000),
    definition(Building::Forge, 22, IRON, EconomyYield::new(0, 3, 0, 0), 0, 0, 10_000),
    definition(Building::Stable, 18, HORSES, EconomyYield::new(1, 1, 0, 0), 0, 0, 10_000),
    definition(Building::Bank, 22, PRECIOUS, EconomyYield::new(0, 0, 5, 0), 0, 0, 10_000),
    definition(Building::BuildersGuild, 21, NONE, EconomyYield::new(0, 2, 0, 0), 0, 1, 10_000),
    definition(Building::Factory, 30, COAL_OR_OIL, EconomyYield::new(0, 4, 0, 0), 0, 0, 10_000),
    definition(Building::Lighthouse, 20, COAST, EconomyYield::new(1, 0, 3, 0), 0, 0, 10_000),
    definition(Building::TrainingGrounds, 22, NONE, EconomyYield::new(0, 1, 0, 2), 0, 0, 10_000),
    definition(Building::TownHall, 24, NONE, EconomyYield::new(0, 0, 2, 1), 0, 1, 10_000),
    definition(Building::Monument, 15, NONE, EconomyYield::new(0, 0, 1, 1), 0, 0, 10_000),
    definition(Building::Archive, 15, NONE, EconomyYield::new(0, 0, 1, 0), 2, 0, 10_000),
    definition(Building::Academy, 22, NONE, EconomyYield::new(0, 1, 1, 0), 3, 0, 10_000),
    definition(Building::University, 36, NONE, EconomyYield::new(0, 0, 3, 0), 3, 0, 10_000),
    definition(Building::Observatory, 30, NONE, EconomyYield::new(0, 0, 2, 1), 3, 0, 10_000),
    definition(Building::Laboratory, 46, NONE, EconomyYield::new(0, 2, 2, 0), 4, 0, 10_000),
    definition(Building::Reactor, 80, URANIUM, EconomyYield::new(0, 6, 2, 1), 3, 0, 10_000),
    definition(Building::Courthouse, 22, NONE, EconomyYield::new(0, 0, 1, 2), 0, 0, 10_000),
    definition(Building::Court, 28, NONE, EconomyYield::new(0, 0, 2, 2), 0, 0, 10_000),
    definition(Building::GovernorsOffice, 32, NONE, EconomyYield::new(0, 1, 2, 1), 0, 1, 10_000),
    definition(Building::SurveyorsOffice, 20, NONE, ZERO, 2, 2, 10_000),
    definition(Building::PlanningOffice, 30, NONE, EconomyYield::new(0, 1, 1, 0), 0, 2, 10_000),
    definition(Building::Apothecary, 18, NONE, EconomyYield::new(1, 0, 0, 1), 1, 0, 10_000),
    definition(Building::PublicBaths, 28, NONE, EconomyYield::new(2, 0, 1, 0), 0, 0, 10_000),
    definition(Building::Hospital, 42, NONE, EconomyYield::new(3, 0, 1, 1), 2, 0, 10_000),
    definition(Building::Ministries, 48, NONE, EconomyYield::new(0, 1, 4, 1), 0, 0, 10_000),
    definition(Building::Walls, 18, NONE, EconomyYield::new(0, 0, 0, 4), 0, 0, 10_000),
    definition(Building::Armory, 26, NONE, EconomyYield::new(0, 2, 0, 2), 0, 0, 10_000),
    definition(Building::SiegeWorkshop, 36, NONE, EconomyYield::new(0, 3, 0, 1), 0, 0, 10_000),
    definition(Building::Citadel, 46, NONE, EconomyYield::new(0, 1, 0, 6), 0, 0, 10_000),
    definition(Building::WarCollege, 42, NONE, EconomyYield::new(0, 2, 1, 3), 0, 0, 10_000),
    definition(Building::ConscriptionOffice, 34, NONE, EconomyYield::new(0, 3, 0, 1), 0, 0, 10_000),
    definition(Building::BorderFort, 30, NONE, EconomyYield::new(0, 0, 1, 4), 0, 0, 10_000),
    definition(Building::Airfield, 54, OIL_OR_ALUMINIUM, EconomyYield::new(0, 3, 1, 2), 0, 0, 10_000),
    definition(Building::ArtisansGuild, 22, NONE, EconomyYield::new(0, 2, 1, 0), 0, 0, 10_000),
    definition(Building::MasterWorkshop, 34, NONE, EconomyYield::new(0, 3, 1, 0), 0, 0, 10_000),
    definition(Building::Steelworks, 52, IRON_OR_COAL, EconomyYield::new(0, 5, 0, 1), 0, 0, 10_000),
    definition(Building::RailDepot, 42, NONE, EconomyYield::new(0, 2, 2, 0), 0, 0, 10_000),
    definition(Building::PowerPlant, 62, COAL_OR_OIL, EconomyYield::new(0, 5, 1, 0), 0, 0, 10_000),
    definition(Building::AssemblyPlant, 70, NONE, EconomyYield::new(0, 6, 1, 0), 0, 0, 10_000),
    definition(Building::Refinery, 58, OIL, EconomyYield::new(0, 3, 3, 0), 0, 0, 10_000),
    definition(Building::MapRoom, 20, NONE, EconomyYield::new(0, 0, 1, 1), 2, 0, 10_000),
    definition(Building::Shipyard, 34, COAST, EconomyYield::new(0, 3, 1, 0), 0, 0, 10_000),
    definition(Building::DryDock, 48, COAST, EconomyYield::new(0, 4, 1, 2), 0, 0, 10_000),
    definition(Building::NavalAcademy, 42, COAST, EconomyYield::new(0, 2, 1, 3), 0, 0, 10_000),
    definition(Building::HarborCustoms, 30, COAST, EconomyYield::new(0, 0, 4, 0), 0, 0, 10_000),
    definition(Building::Museum, 36, NONE, EconomyYield::new(0, 0, 3, 1), 2, 0, 10_000),
    definition(Building::Parliament, 58, NONE, EconomyYield::new(0, 1, 5, 2), 0, 1, 10_000),
    definition(Building::BroadcastTower, 48, NONE, EconomyYield::new(0, 0, 4, 2), 0, 0, 10_000),
    definition(Building::WorldFairGrounds, 54, NONE, EconomyYield::new(1, 1, 5, 0), 0, 0, 10_000),
];

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn runtime_constructors_preserve_building_data() {
        let definition = definition(
            std::hint::black_box(Building::Granary),
            std::hint::black_box(7),
            NONE,
            EconomyYield::new(1, 2, 3, 4),
            5,
            6,
            7,
        );
        assert_eq!(definition.building(), Building::Granary);
        assert_eq!(definition.base_cost(), 7);
        assert_eq!(definition.yield_delta(), EconomyYield::new(1, 2, 3, 4));
        assert_eq!(definition.science_per_turn(), 5);
        assert_eq!(definition.max_controlled_hexes_delta(), 6);
        assert_eq!(definition.food_deposit_basis_points(), 7);

        let water_mill = std::hint::black_box(water_mill());
        assert_eq!(water_mill.river_yield_per_hex().food(), 1);
        assert_eq!(water_mill.max_river_applications(), 3);
    }
}
