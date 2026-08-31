use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};

use super::WonderTypeDto;

/// Complete per-player research state.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ResearchStateDto {
    pub players: BTreeMap<String, PlayerResearchStateDto>,
}

/// One player's persisted research selection and progress.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerResearchStateDto {
    pub unlocked_technology_ids: Vec<TechnologyIdDto>,
    pub active_technology_id: Option<TechnologyIdDto>,
    pub progress_by_technology_id: BTreeMap<TechnologyIdDto, i64>,
    pub science_overflow: i64,
}

/// Globally completed wonders and the player credited with each completion.
#[derive(Clone, Debug, Default, Eq, PartialEq, Deserialize, Serialize)]
#[serde(transparent)]
pub struct WonderRegistryDto(pub BTreeMap<WonderTypeDto, String>);

/// Stable identity of one technology in the current ruleset.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Ord, PartialEq, PartialOrd, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum TechnologyIdDto {
    Agriculture,
    Woodworking,
    Mining,
    AnimalHusbandry,
    Hunting,
    Fishing,
    Craftsmanship,
    Trade,
    Storage,
    WaterEngineering,
    Stoneworking,
    MilitaryOrganization,
    AdvancedTrade,
    Construction,
    Navigation,
    Irrigation,
    Banking,
    Engineering,
    Metallurgy,
    HorsebackRiding,
    IronWorking,
    CoalMining,
    Machinery,
    Administration,
    Logistics,
    Shipbuilding,
    Tactics,
    Economy,
    Urbanization,
    Fortifications,
    Strategy,
    Specialization,
    Writing,
    Mathematics,
    Medicine,
    CivilService,
    Siegecraft,
    Cartography,
    Guilds,
    Law,
    Education,
    UrbanPlanning,
    NavalDoctrine,
    Steel,
    Bureaucracy,
    Nationalism,
    ScientificMethod,
    SteamPower,
    Electricity,
    Combustion,
    Flight,
    MassProduction,
    Radio,
    NuclearPhysics,
}
