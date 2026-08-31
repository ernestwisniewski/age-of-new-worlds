use serde::{Deserialize, Serialize};

use super::{CoordinateDto, StrategicResourceStockpileDto};
use crate::UnitKindDto;

/// Complete persisted city state.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct CityDto {
    pub id: String,
    pub owner_player_id: String,
    pub founding_owner_player_id: Option<String>,
    pub name: String,
    pub population: i64,
    pub stored_food: i64,
    pub max_hexes: i64,
    pub territory_radius: i64,
    pub center: CoordinateDto,
    pub controlled_hexes: Vec<CoordinateDto>,
    pub worked_hexes: Vec<CoordinateDto>,
    pub buildings: Vec<CityBuildingTypeDto>,
    pub wonders: Vec<WonderTypeDto>,
    pub production_queue: Option<CityProductionQueueDto>,
    pub production_overflow: i64,
    pub specialization: Option<CitySpecializationTypeDto>,
    pub preferred_expansion_hex: Option<CoordinateDto>,
    pub hit_points: Option<i64>,
}

/// Persisted production investment and reserved strategic resources.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct CityProductionQueueDto {
    pub target: CityProductionTargetDto,
    pub invested_production: i64,
    pub resource_allocation: StrategicResourceStockpileDto,
}

/// One typed city production target.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "kind",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum CityProductionTargetDto {
    Building { building_type: CityBuildingTypeDto },
    Unit { unit_type: UnitKindDto },
    Project { project_type: CityProjectTypeDto },
    Wonder { wonder_type: WonderTypeDto },
}

/// Repeatable city project.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Ord, PartialEq, PartialOrd, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum CityProjectTypeDto {
    Wealth,
    Research,
}

/// Optional city specialization.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Ord, PartialEq, PartialOrd, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum CitySpecializationTypeDto {
    Growth,
    Industry,
    Commerce,
    Science,
    Military,
}

/// Wonder identity retained in city ownership.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Ord, PartialEq, PartialOrd, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum WonderTypeDto {
    GreatLibrary,
    HangingGardens,
    GreatWall,
    Petra,
    CentralBank,
    ImperialUniversity,
    GrandCathedral,
    MotherFactory,
    NationalObservatory,
    SvalbardSeedVault,
    GrandExposition,
}

/// Building identity retained in city ownership and production.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Ord, PartialEq, PartialOrd, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum CityBuildingTypeDto {
    Granary,
    WaterMill,
    Workshop,
    Storehouse,
    Housing,
    MerchantHall,
    Stonemason,
    Barracks,
    Marketplace,
    Port,
    Aqueduct,
    Forge,
    Stable,
    Bank,
    BuildersGuild,
    Factory,
    Lighthouse,
    TrainingGrounds,
    TownHall,
    Monument,
    Archive,
    Academy,
    University,
    Observatory,
    Laboratory,
    Reactor,
    Courthouse,
    Court,
    GovernorsOffice,
    SurveyorsOffice,
    PlanningOffice,
    Apothecary,
    PublicBaths,
    Hospital,
    Ministries,
    Walls,
    Armory,
    SiegeWorkshop,
    Citadel,
    WarCollege,
    ConscriptionOffice,
    BorderFort,
    Airfield,
    ArtisansGuild,
    MasterWorkshop,
    Steelworks,
    RailDepot,
    PowerPlant,
    AssemblyPlant,
    Refinery,
    MapRoom,
    Shipyard,
    DryDock,
    NavalAcademy,
    HarborCustoms,
    Museum,
    Parliament,
    BroadcastTower,
    WorldFairGrounds,
}
