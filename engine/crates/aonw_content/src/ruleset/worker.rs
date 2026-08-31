use aonw_domain::{FieldImprovementKind, PaceProfile};
use serde::Serialize;

use crate::{ResourceType, TerrainType};

/// Integer yield delta contributed by one worker improvement.
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct WorkerYield {
    food: i32,
    production: i32,
    gold: i32,
    defense: i32,
}

#[allow(missing_docs)]
impl WorkerYield {
    #[must_use]
    pub const fn food(self) -> i32 {
        self.food
    }
    #[must_use]
    pub const fn production(self) -> i32 {
        self.production
    }
    #[must_use]
    pub const fn gold(self) -> i32 {
        self.gold
    }
    #[must_use]
    pub const fn defense(self) -> i32 {
        self.defense
    }
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub(super) enum WorkerImprovementKindValue {
    Farm,
    RiverFarm,
    Mine,
    LumberMill,
    Pasture,
    Camp,
    Quarry,
    FishingBoats,
    Orchard,
    Plantation,
    Vineyard,
    TradingPost,
    ProspectorCamp,
    HorseRanch,
    PearlDivers,
    CoalShaft,
    OilWell,
    BauxiteMine,
    UraniumMine,
}

impl WorkerImprovementKindValue {
    const fn domain(self) -> FieldImprovementKind {
        match self {
            Self::Farm => FieldImprovementKind::Farm,
            Self::RiverFarm => FieldImprovementKind::RiverFarm,
            Self::Mine => FieldImprovementKind::Mine,
            Self::LumberMill => FieldImprovementKind::LumberMill,
            Self::Pasture => FieldImprovementKind::Pasture,
            Self::Camp => FieldImprovementKind::Camp,
            Self::Quarry => FieldImprovementKind::Quarry,
            Self::FishingBoats => FieldImprovementKind::FishingBoats,
            Self::Orchard => FieldImprovementKind::Orchard,
            Self::Plantation => FieldImprovementKind::Plantation,
            Self::Vineyard => FieldImprovementKind::Vineyard,
            Self::TradingPost => FieldImprovementKind::TradingPost,
            Self::ProspectorCamp => FieldImprovementKind::ProspectorCamp,
            Self::HorseRanch => FieldImprovementKind::HorseRanch,
            Self::PearlDivers => FieldImprovementKind::PearlDivers,
            Self::CoalShaft => FieldImprovementKind::CoalShaft,
            Self::OilWell => FieldImprovementKind::OilWell,
            Self::BauxiteMine => FieldImprovementKind::BauxiteMine,
            Self::UraniumMine => FieldImprovementKind::UraniumMine,
        }
    }
}

/// Immutable legality and scoring definition for one improvement.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct WorkerImprovementDefinition {
    kind: WorkerImprovementKindValue,
    yield_delta: WorkerYield,
    base_build_turns: u32,
    specialist: bool,
    required_resources: &'static [ResourceType],
    required_base_terrains: &'static [TerrainType],
    requires_river: bool,
}

#[allow(missing_docs)]
impl WorkerImprovementDefinition {
    #[must_use]
    pub const fn kind(self) -> FieldImprovementKind {
        self.kind.domain()
    }
    #[must_use]
    pub const fn yield_delta(self) -> WorkerYield {
        self.yield_delta
    }
    #[must_use]
    pub const fn base_build_turns(self) -> u32 {
        self.base_build_turns
    }
    #[must_use]
    pub const fn specialist(self) -> bool {
        self.specialist
    }
    #[must_use]
    pub const fn required_resources(self) -> &'static [ResourceType] {
        self.required_resources
    }
    #[must_use]
    pub const fn required_base_terrains(self) -> &'static [TerrainType] {
        self.required_base_terrains
    }
    #[must_use]
    pub const fn requires_river(self) -> bool {
        self.requires_river
    }
}

/// Immutable worker, assignment, road, and automation balance.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct WorkerBalance {
    improvements: &'static [WorkerImprovementDefinition],
    road_base_build_turns: u32,
    assignment_limit_base: u32,
    assignment_population_divisor: u32,
    automation_tile_budget: u32,
    automation_legality_budget: u32,
}

#[allow(missing_docs)]
impl WorkerBalance {
    pub(super) const STANDARD: Self = Self {
        improvements: &STANDARD_IMPROVEMENTS,
        road_base_build_turns: 1,
        assignment_limit_base: 1,
        assignment_population_divisor: 4,
        automation_tile_budget: 1_200,
        automation_legality_budget: 24_000,
    };
    #[must_use]
    pub const fn improvements(self) -> &'static [WorkerImprovementDefinition] {
        self.improvements
    }
    #[must_use]
    pub fn improvement(self, kind: FieldImprovementKind) -> Option<WorkerImprovementDefinition> {
        self.improvements
            .iter()
            .copied()
            .find(|definition| definition.kind() == kind)
    }
    #[must_use]
    pub const fn improvement_turns(self, base: u32, pace: PaceProfile) -> u32 {
        if base == 0 {
            return 0;
        }
        match pace {
            PaceProfile::Unlimited => base.saturating_add(1),
            PaceProfile::Standard60 | PaceProfile::Normal90 | PaceProfile::Long120 => base,
        }
    }
    #[must_use]
    pub const fn road_build_turns(self, pace: PaceProfile) -> u32 {
        self.improvement_turns(self.road_base_build_turns, pace)
    }
    #[must_use]
    pub fn assignment_limit(self, population: i64) -> u32 {
        let population = u32::try_from(population.max(0)).unwrap_or(u32::MAX);
        self.assignment_limit_base
            .saturating_add(population / self.assignment_population_divisor)
    }
    #[must_use]
    pub const fn automation_tile_budget(self) -> u32 {
        self.automation_tile_budget
    }
    #[must_use]
    pub const fn automation_legality_budget(self) -> u32 {
        self.automation_legality_budget
    }
}

const fn y(food: i32, production: i32, gold: i32) -> WorkerYield {
    WorkerYield {
        food,
        production,
        gold,
        defense: 0,
    }
}
const fn improvement(
    kind: WorkerImprovementKindValue,
    yield_delta: WorkerYield,
    base_build_turns: u32,
    specialist: bool,
    required_resources: &'static [ResourceType],
    required_base_terrains: &'static [TerrainType],
    requires_river: bool,
) -> WorkerImprovementDefinition {
    WorkerImprovementDefinition {
        kind,
        yield_delta,
        base_build_turns,
        specialist,
        required_resources,
        required_base_terrains,
        requires_river,
    }
}

const LAND_FARMS: &[TerrainType] = &[TerrainType::Grassland, TerrainType::Plains];
const HILLS: &[TerrainType] = &[TerrainType::Hills];
const FOREST: &[TerrainType] = &[TerrainType::Forest];
const STANDARD_IMPROVEMENTS: [WorkerImprovementDefinition; 19] = [
    improvement(
        WorkerImprovementKindValue::Farm,
        y(1, 0, 0),
        2,
        false,
        &[],
        LAND_FARMS,
        false,
    ),
    improvement(
        WorkerImprovementKindValue::RiverFarm,
        y(2, 0, 0),
        2,
        false,
        &[],
        LAND_FARMS,
        true,
    ),
    improvement(
        WorkerImprovementKindValue::Mine,
        y(0, 2, 0),
        3,
        false,
        &[],
        HILLS,
        false,
    ),
    improvement(
        WorkerImprovementKindValue::LumberMill,
        y(0, 1, 0),
        2,
        false,
        &[],
        FOREST,
        false,
    ),
    improvement(
        WorkerImprovementKindValue::Pasture,
        y(1, 1, 0),
        3,
        true,
        &[ResourceType::Cow, ResourceType::Sheep],
        &[],
        false,
    ),
    improvement(
        WorkerImprovementKindValue::Camp,
        y(1, 1, 0),
        3,
        true,
        &[ResourceType::Deer],
        &[],
        false,
    ),
    improvement(
        WorkerImprovementKindValue::Quarry,
        y(0, 2, 0),
        3,
        true,
        &[ResourceType::Marble],
        &[],
        false,
    ),
    improvement(
        WorkerImprovementKindValue::FishingBoats,
        y(2, 0, 0),
        3,
        true,
        &[ResourceType::Fish],
        &[],
        false,
    ),
    improvement(
        WorkerImprovementKindValue::Orchard,
        y(1, 0, 1),
        3,
        true,
        &[
            ResourceType::Apple,
            ResourceType::Banana,
            ResourceType::Citrus,
        ],
        &[],
        false,
    ),
    improvement(
        WorkerImprovementKindValue::Plantation,
        y(1, 0, 2),
        4,
        true,
        &[
            ResourceType::Silk,
            ResourceType::Spices,
            ResourceType::Cotton,
            ResourceType::Coffee,
            ResourceType::Cocoa,
            ResourceType::Tobacco,
            ResourceType::Sugar,
        ],
        &[],
        false,
    ),
    improvement(
        WorkerImprovementKindValue::Vineyard,
        y(1, 0, 2),
        3,
        true,
        &[ResourceType::Grapes],
        &[],
        false,
    ),
    improvement(
        WorkerImprovementKindValue::TradingPost,
        y(0, 0, 3),
        3,
        true,
        &[ResourceType::Ivory],
        &[],
        false,
    ),
    improvement(
        WorkerImprovementKindValue::ProspectorCamp,
        y(0, 1, 2),
        4,
        true,
        &[ResourceType::Gold, ResourceType::Silver, ResourceType::Gems],
        &[],
        false,
    ),
    improvement(
        WorkerImprovementKindValue::HorseRanch,
        y(1, 1, 0),
        3,
        true,
        &[ResourceType::Horses],
        &[],
        false,
    ),
    improvement(
        WorkerImprovementKindValue::PearlDivers,
        y(1, 0, 3),
        4,
        true,
        &[ResourceType::Pearls],
        &[],
        false,
    ),
    improvement(
        WorkerImprovementKindValue::CoalShaft,
        y(0, 3, 0),
        4,
        true,
        &[ResourceType::Coal],
        &[],
        false,
    ),
    improvement(
        WorkerImprovementKindValue::OilWell,
        y(0, 2, 2),
        5,
        true,
        &[ResourceType::Oil],
        &[],
        false,
    ),
    improvement(
        WorkerImprovementKindValue::BauxiteMine,
        y(0, 3, 1),
        5,
        true,
        &[ResourceType::Aluminium],
        &[],
        false,
    ),
    improvement(
        WorkerImprovementKindValue::UraniumMine,
        y(0, 2, 2),
        5,
        true,
        &[ResourceType::Uranium],
        &[],
        false,
    ),
];
