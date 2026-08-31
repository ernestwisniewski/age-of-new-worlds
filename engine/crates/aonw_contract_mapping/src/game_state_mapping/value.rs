use aonw_contracts::{CoordinateDto, FieldImprovementKindDto, MovementStepDto, TroopKindDto};
use aonw_domain::{FieldImprovementKind, HexCoord, MovementStep, MovementUnits, TroopKind};

pub(super) const fn decode_coordinate(value: CoordinateDto) -> HexCoord {
    HexCoord::new(value.col, value.row)
}

pub(super) const fn encode_coordinate(value: HexCoord) -> CoordinateDto {
    CoordinateDto {
        col: value.col(),
        row: value.row(),
    }
}

pub(super) fn decode_step(step: MovementStepDto) -> MovementStep {
    MovementStep::new(
        HexCoord::new(step.col, step.row),
        MovementUnits::new(step.enter_cost_units),
        MovementUnits::new(step.cumulative_cost_units),
    )
}

pub(super) fn encode_step(step: MovementStep) -> MovementStepDto {
    MovementStepDto {
        col: step.coordinate().col(),
        row: step.coordinate().row(),
        enter_cost_units: step.enter_cost().get(),
        cumulative_cost_units: step.cumulative_cost().get(),
    }
}

/// Converts a strict wire troop kind into its domain value.
#[must_use]
pub const fn decode_troop(kind: TroopKindDto) -> TroopKind {
    match kind {
        TroopKindDto::Warrior => TroopKind::Warrior,
        TroopKindDto::Archer => TroopKind::Archer,
        TroopKindDto::Settler => TroopKind::Settler,
    }
}

/// Converts a domain troop kind into its strict wire value.
#[must_use]
pub const fn encode_troop(kind: TroopKind) -> TroopKindDto {
    match kind {
        TroopKind::Warrior => TroopKindDto::Warrior,
        TroopKind::Archer => TroopKindDto::Archer,
        TroopKind::Settler => TroopKindDto::Settler,
    }
}

macro_rules! improvement_mapping {
    ($value:expr, $source:path => $target:path, $($rest_source:path => $rest_target:path),+ $(,)?) => {
        match $value {
            $source => $target,
            $($rest_source => $rest_target),+
        }
    };
}

/// Converts one current wire improvement identity into the domain value.
#[must_use]
pub const fn decode_improvement(kind: FieldImprovementKindDto) -> FieldImprovementKind {
    improvement_mapping!(
        kind,
        FieldImprovementKindDto::Farm => FieldImprovementKind::Farm,
        FieldImprovementKindDto::RiverFarm => FieldImprovementKind::RiverFarm,
        FieldImprovementKindDto::Mine => FieldImprovementKind::Mine,
        FieldImprovementKindDto::LumberMill => FieldImprovementKind::LumberMill,
        FieldImprovementKindDto::Pasture => FieldImprovementKind::Pasture,
        FieldImprovementKindDto::Camp => FieldImprovementKind::Camp,
        FieldImprovementKindDto::Quarry => FieldImprovementKind::Quarry,
        FieldImprovementKindDto::FishingBoats => FieldImprovementKind::FishingBoats,
        FieldImprovementKindDto::Orchard => FieldImprovementKind::Orchard,
        FieldImprovementKindDto::Plantation => FieldImprovementKind::Plantation,
        FieldImprovementKindDto::Vineyard => FieldImprovementKind::Vineyard,
        FieldImprovementKindDto::TradingPost => FieldImprovementKind::TradingPost,
        FieldImprovementKindDto::ProspectorCamp => FieldImprovementKind::ProspectorCamp,
        FieldImprovementKindDto::HorseRanch => FieldImprovementKind::HorseRanch,
        FieldImprovementKindDto::PearlDivers => FieldImprovementKind::PearlDivers,
        FieldImprovementKindDto::CoalShaft => FieldImprovementKind::CoalShaft,
        FieldImprovementKindDto::OilWell => FieldImprovementKind::OilWell,
        FieldImprovementKindDto::BauxiteMine => FieldImprovementKind::BauxiteMine,
        FieldImprovementKindDto::UraniumMine => FieldImprovementKind::UraniumMine,
    )
}

/// Converts a validated field improvement into its stable contract value.
#[must_use]
pub const fn encode_improvement(kind: FieldImprovementKind) -> FieldImprovementKindDto {
    improvement_mapping!(
        kind,
        FieldImprovementKind::Farm => FieldImprovementKindDto::Farm,
        FieldImprovementKind::RiverFarm => FieldImprovementKindDto::RiverFarm,
        FieldImprovementKind::Mine => FieldImprovementKindDto::Mine,
        FieldImprovementKind::LumberMill => FieldImprovementKindDto::LumberMill,
        FieldImprovementKind::Pasture => FieldImprovementKindDto::Pasture,
        FieldImprovementKind::Camp => FieldImprovementKindDto::Camp,
        FieldImprovementKind::Quarry => FieldImprovementKindDto::Quarry,
        FieldImprovementKind::FishingBoats => FieldImprovementKindDto::FishingBoats,
        FieldImprovementKind::Orchard => FieldImprovementKindDto::Orchard,
        FieldImprovementKind::Plantation => FieldImprovementKindDto::Plantation,
        FieldImprovementKind::Vineyard => FieldImprovementKindDto::Vineyard,
        FieldImprovementKind::TradingPost => FieldImprovementKindDto::TradingPost,
        FieldImprovementKind::ProspectorCamp => FieldImprovementKindDto::ProspectorCamp,
        FieldImprovementKind::HorseRanch => FieldImprovementKindDto::HorseRanch,
        FieldImprovementKind::PearlDivers => FieldImprovementKindDto::PearlDivers,
        FieldImprovementKind::CoalShaft => FieldImprovementKindDto::CoalShaft,
        FieldImprovementKind::OilWell => FieldImprovementKindDto::OilWell,
        FieldImprovementKind::BauxiteMine => FieldImprovementKindDto::BauxiteMine,
        FieldImprovementKind::UraniumMine => FieldImprovementKindDto::UraniumMine,
    )
}
