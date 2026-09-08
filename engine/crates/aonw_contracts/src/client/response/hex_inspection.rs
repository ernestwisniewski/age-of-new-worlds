use crate::client::{MapResourceDto, MapTerrainDto, YieldValueDto};
use crate::{CoordinateDto, FieldImprovementKindDto, TechnologyIdDto};
use serde::{Deserialize, Serialize};

/// Closed wire values for the engine-owned `HexAssessmentKind`.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum HexAssessmentKindDto {
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

/// Closed wire values for the engine-owned `HexRecommendation`.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum HexRecommendationDto {
    FoundCity,
    DefendHere,
    ExploitEconomy,
    Avoid,
    Neutral,
}

/// Closed wire values for the engine-owned `HexAssessmentTag`.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum HexAssessmentTagDto {
    City,
    Defense,
    Trade,
    Fertile,
    Production,
    Hostile,
    Strategic,
    Water,
}

/// Public improvement context; this does not authorize a worker command.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "kind",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum HexImprovementAccessDto {
    OutsideControlledCity {},
    CityCenter {},
    AlreadyImproved {},
    ControlledCity { city_id: String },
}

/// Scores calculated after filtering unrevealed resources.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct HexAssessmentScoreDto {
    pub city: i32,
    pub defense: i32,
    pub economy: i32,
}

/// Terrain-compatible improvement with actor-owned technology requirements.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct HexImprovementOptionDto {
    pub kind: FieldImprovementKindDto,
    #[serde(deserialize_with = "deserialize_required_technology")]
    pub required_technology: Option<TechnologyIdDto>,
    pub technology_unlocked: bool,
    pub build_turns: u32,
    pub yield_delta: YieldValueDto,
}

/// Complete disclosed profile of one map coordinate.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct HexInspectionDto {
    pub coordinate: CoordinateDto,
    pub base_terrain: MapTerrainDto,
    pub terrain_tags: Vec<MapTerrainDto>,
    pub resources: Vec<MapResourceDto>,
    pub height: u8,
    pub has_river: bool,
    /// Terrain suitability only, independent of current command legality.
    pub can_found_city_on_terrain: bool,
    pub yield_value: YieldValueDto,
    pub score: HexAssessmentScoreDto,
    pub kind: HexAssessmentKindDto,
    pub recommendation: HexRecommendationDto,
    pub tags: Vec<HexAssessmentTagDto>,
    pub improvement_access: HexImprovementAccessDto,
    pub improvements: Vec<HexImprovementOptionDto>,
}

fn deserialize_required_technology<'de, D: serde::Deserializer<'de>>(
    deserializer: D,
) -> Result<Option<TechnologyIdDto>, D::Error> {
    Option::<TechnologyIdDto>::deserialize(deserializer)
}
