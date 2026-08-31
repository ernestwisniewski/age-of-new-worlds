use aonw_domain::UnitKind as Unit;

use crate::ResourceType as Resource;

use super::{StrategicResourceCost, UnitProductionDefinition};

const NONE: &[Resource] = &[];
const HORSES: &[Resource] = &[Resource::Horses];
const IRON: &[Resource] = &[Resource::Iron];
const NO_STOCKPILE_COST: &[StrategicResourceCost] = &[];
const OIL_TWO: &[StrategicResourceCost] = &[StrategicResourceCost::new(2, 0)];
const ALUMINIUM_OR_OIL: &[StrategicResourceCost] = &[
    StrategicResourceCost::new(0, 1),
    StrategicResourceCost::new(1, 0),
];

const fn definition(
    unit: Unit,
    base_cost: i64,
    upkeep: i64,
    supply_cost: i64,
    presence_resources: &'static [Resource],
    strategic_cost_options: &'static [StrategicResourceCost],
) -> UnitProductionDefinition {
    UnitProductionDefinition {
        unit,
        base_cost,
        upkeep,
        supply_cost,
        presence_resources,
        strategic_cost_options,
    }
}

pub(super) const STANDARD_UNITS: [UnitProductionDefinition; 17] = [
    definition(Unit::Commander, 54, 0, 0, NONE, NO_STOCKPILE_COST),
    definition(Unit::Warrior, 15, 1, 1, NONE, NO_STOCKPILE_COST),
    definition(Unit::Archer, 16, 1, 1, NONE, NO_STOCKPILE_COST),
    definition(Unit::Settler, 22, 2, 1, NONE, NO_STOCKPILE_COST),
    definition(Unit::Worker, 14, 1, 1, NONE, NO_STOCKPILE_COST),
    definition(Unit::Merchant, 24, 1, 1, NONE, NO_STOCKPILE_COST),
    definition(Unit::Scout, 12, 1, 1, NONE, NO_STOCKPILE_COST),
    definition(Unit::Spearman, 18, 1, 1, NONE, NO_STOCKPILE_COST),
    definition(Unit::Cavalry, 38, 2, 2, HORSES, NO_STOCKPILE_COST),
    definition(Unit::Catapult, 40, 2, 2, NONE, NO_STOCKPILE_COST),
    definition(Unit::HeavyInfantry, 46, 2, 2, IRON, NO_STOCKPILE_COST),
    definition(Unit::FieldCannon, 58, 2, 2, IRON, NO_STOCKPILE_COST),
    definition(Unit::Rifleman, 52, 2, 2, IRON, NO_STOCKPILE_COST),
    definition(Unit::Tank, 84, 3, 3, NONE, OIL_TWO),
    definition(Unit::ScoutShip, 34, 1, 1, NONE, NO_STOCKPILE_COST),
    definition(Unit::Warship, 70, 2, 2, IRON, NO_STOCKPILE_COST),
    definition(Unit::ReconPlane, 62, 2, 2, NONE, ALUMINIUM_OR_OIL),
];

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn runtime_constructor_preserves_unit_data() {
        let definition = definition(
            std::hint::black_box(Unit::Tank),
            std::hint::black_box(84),
            3,
            3,
            NONE,
            OIL_TWO,
        );
        assert_eq!(definition.unit(), Unit::Tank);
        assert_eq!(definition.base_cost(), 84);
        assert_eq!(definition.upkeep(), 3);
        assert_eq!(definition.supply_cost(), 3);
        assert_eq!(definition.presence_resources(), NONE);
        assert_eq!(definition.strategic_cost_options(), OIL_TWO);
    }
}
