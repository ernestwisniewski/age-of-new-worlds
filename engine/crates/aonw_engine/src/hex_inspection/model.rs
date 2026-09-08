use crate::YieldValue;
use aonw_content::{ResourceType, TerrainType};
use aonw_domain::{CityId, FieldImprovementKind, HexCoord, TechnologyId};

/// Read-only, revision-bound inspection of a logical map coordinate.
#[derive(Clone, Copy, Debug)]
pub struct HexInspectionQuery {
    pub(crate) expected_revision: u64,
    pub(crate) coordinate: HexCoord,
}
impl HexInspectionQuery {
    /// Creates an inspection request; the engine derives resource disclosure.
    #[must_use]
    pub const fn new(expected_revision: u64, coordinate: HexCoord) -> Self {
        Self {
            expected_revision,
            coordinate,
        }
    }
}

/// Scores used to classify a hex, independent of command legality.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub struct HexAssessmentScore {
    pub city: i32,
    pub defense: i32,
    pub economy: i32,
}
impl HexAssessmentScore {
    pub(super) const fn new(city: i32, defense: i32, economy: i32) -> Self {
        Self {
            city,
            defense,
            economy,
        }
    }
    pub(super) const fn plus(self, other: Self) -> Self {
        Self::new(
            self.city + other.city,
            self.defense + other.defense,
            self.economy + other.economy,
        )
    }
}

/// Semantic classification of disclosed terrain and resources.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum HexAssessmentKind {
    IdealCitySite,
    GoodCitySite,
    FertileField,
    FertilePlains,
    RichPlain,
    StrategicBorderland,
    StrategicField,
    DefensivePosition,
    FertileForest,
    ForestBackline,
    ForestForge,
    WildLand,
    RichWilds,
    ExoticBackline,
    DifficultStrategicTerrain,
    HighGround,
    RiverHills,
    IndustrialStronghold,
    RichHills,
    BarrenLand,
    Oasis,
    TradeOasis,
    DesertDeposits,
    HarshLand,
    ColdPastures,
    ResourceOutpost,
    HostileLand,
    ArcticDeposits,
    Coast,
    FishingCoast,
    RichCoast,
    RiverPort,
    RegionalPortHeart,
    OpenSea,
    NaturalBarrier,
    PromisingLand,
    WeakLand,
    OrdinaryLand,
    MapTile,
}

/// Recommendation derived from the disclosed hex profile.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum HexRecommendation {
    FoundCity,
    DefendHere,
    ExploitEconomy,
    Avoid,
    Neutral,
}

/// Canonical ordered tags for the disclosed hex profile.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum HexAssessmentTag {
    City,
    Defense,
    Trade,
    Fertile,
    Production,
    Hostile,
    Strategic,
    Water,
}

/// Public context for possible improvements; never authorizes a worker command.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum HexImprovementAccess {
    OutsideControlledCity,
    CityCenter,
    AlreadyImproved,
    ControlledCity(CityId),
}

/// A terrain-compatible improvement and its actor-owned technology requirement.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct HexImprovementOption {
    pub kind: FieldImprovementKind,
    pub required_technology: Option<TechnologyId>,
    pub technology_unlocked: bool,
    pub build_turns: u32,
    pub yield_delta: YieldValue,
}

/// Display-ready hex profile computed after filtering unrevealed resources.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct HexInspection {
    pub coordinate: HexCoord,
    pub base_terrain: TerrainType,
    pub terrain_tags: Vec<TerrainType>,
    pub resources: Vec<ResourceType>,
    pub height: u8,
    pub has_river: bool,
    /// Terrain suitability only; does not assert current founding legality.
    pub can_found_city_on_terrain: bool,
    pub yield_value: YieldValue,
    pub score: HexAssessmentScore,
    pub kind: HexAssessmentKind,
    pub recommendation: HexRecommendation,
    pub tags: Vec<HexAssessmentTag>,
    pub improvement_access: HexImprovementAccess,
    pub improvements: Vec<HexImprovementOption>,
}
