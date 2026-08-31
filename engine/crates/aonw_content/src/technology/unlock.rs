use aonw_domain::{CityBuildingType, FieldImprovementKind, ResourceType, UnitKind, WonderType};
use serde::Serialize;

/// City building unlocked by research.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum TechnologyBuilding {
    Workshop,
    MerchantHall,
    Storehouse,
    WaterMill,
    Stonemason,
    Barracks,
    Marketplace,
    Housing,
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

impl TechnologyBuilding {
    /// Maps the unlock identity to the canonical domain building.
    #[must_use]
    pub const fn domain(self) -> CityBuildingType {
        match self {
            Self::Workshop => CityBuildingType::Workshop,
            Self::MerchantHall => CityBuildingType::MerchantHall,
            Self::Storehouse => CityBuildingType::Storehouse,
            Self::WaterMill => CityBuildingType::WaterMill,
            Self::Stonemason => CityBuildingType::Stonemason,
            Self::Barracks => CityBuildingType::Barracks,
            Self::Marketplace => CityBuildingType::Marketplace,
            Self::Housing => CityBuildingType::Housing,
            Self::Port => CityBuildingType::Port,
            Self::Aqueduct => CityBuildingType::Aqueduct,
            Self::Forge => CityBuildingType::Forge,
            Self::Stable => CityBuildingType::Stable,
            Self::Bank => CityBuildingType::Bank,
            Self::BuildersGuild => CityBuildingType::BuildersGuild,
            Self::Factory => CityBuildingType::Factory,
            Self::Lighthouse => CityBuildingType::Lighthouse,
            Self::TrainingGrounds => CityBuildingType::TrainingGrounds,
            Self::TownHall => CityBuildingType::TownHall,
            Self::Monument => CityBuildingType::Monument,
            Self::Archive => CityBuildingType::Archive,
            Self::Academy => CityBuildingType::Academy,
            Self::University => CityBuildingType::University,
            Self::Observatory => CityBuildingType::Observatory,
            Self::Laboratory => CityBuildingType::Laboratory,
            Self::Reactor => CityBuildingType::Reactor,
            Self::Courthouse => CityBuildingType::Courthouse,
            Self::Court => CityBuildingType::Court,
            Self::GovernorsOffice => CityBuildingType::GovernorsOffice,
            Self::SurveyorsOffice => CityBuildingType::SurveyorsOffice,
            Self::PlanningOffice => CityBuildingType::PlanningOffice,
            Self::Apothecary => CityBuildingType::Apothecary,
            Self::PublicBaths => CityBuildingType::PublicBaths,
            Self::Hospital => CityBuildingType::Hospital,
            Self::Ministries => CityBuildingType::Ministries,
            Self::Walls => CityBuildingType::Walls,
            Self::Armory => CityBuildingType::Armory,
            Self::SiegeWorkshop => CityBuildingType::SiegeWorkshop,
            Self::Citadel => CityBuildingType::Citadel,
            Self::WarCollege => CityBuildingType::WarCollege,
            Self::ConscriptionOffice => CityBuildingType::ConscriptionOffice,
            Self::BorderFort => CityBuildingType::BorderFort,
            Self::Airfield => CityBuildingType::Airfield,
            Self::ArtisansGuild => CityBuildingType::ArtisansGuild,
            Self::MasterWorkshop => CityBuildingType::MasterWorkshop,
            Self::Steelworks => CityBuildingType::Steelworks,
            Self::RailDepot => CityBuildingType::RailDepot,
            Self::PowerPlant => CityBuildingType::PowerPlant,
            Self::AssemblyPlant => CityBuildingType::AssemblyPlant,
            Self::Refinery => CityBuildingType::Refinery,
            Self::MapRoom => CityBuildingType::MapRoom,
            Self::Shipyard => CityBuildingType::Shipyard,
            Self::DryDock => CityBuildingType::DryDock,
            Self::NavalAcademy => CityBuildingType::NavalAcademy,
            Self::HarborCustoms => CityBuildingType::HarborCustoms,
            Self::Museum => CityBuildingType::Museum,
            Self::Parliament => CityBuildingType::Parliament,
            Self::BroadcastTower => CityBuildingType::BroadcastTower,
            Self::WorldFairGrounds => CityBuildingType::WorldFairGrounds,
        }
    }
}

/// Field improvement unlocked by research.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum TechnologyImprovement {
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

impl TechnologyImprovement {
    /// Maps the unlock identity to the canonical domain improvement.
    #[must_use]
    pub const fn domain(self) -> FieldImprovementKind {
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

/// Unit kind unlocked by research.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum TechnologyUnit {
    Commander,
    Archer,
    Merchant,
    Spearman,
    Cavalry,
    Catapult,
    HeavyInfantry,
    FieldCannon,
    Rifleman,
    Tank,
    ScoutShip,
    Warship,
    ReconPlane,
}

impl TechnologyUnit {
    /// Maps the unlock identity to the canonical domain unit kind.
    #[must_use]
    pub const fn domain(self) -> UnitKind {
        match self {
            Self::Commander => UnitKind::Commander,
            Self::Archer => UnitKind::Archer,
            Self::Merchant => UnitKind::Merchant,
            Self::Spearman => UnitKind::Spearman,
            Self::Cavalry => UnitKind::Cavalry,
            Self::Catapult => UnitKind::Catapult,
            Self::HeavyInfantry => UnitKind::HeavyInfantry,
            Self::FieldCannon => UnitKind::FieldCannon,
            Self::Rifleman => UnitKind::Rifleman,
            Self::Tank => UnitKind::Tank,
            Self::ScoutShip => UnitKind::ScoutShip,
            Self::Warship => UnitKind::Warship,
            Self::ReconPlane => UnitKind::ReconPlane,
        }
    }
}

/// Wonder unlocked by research.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum TechnologyWonder {
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

impl TechnologyWonder {
    /// Maps the unlock identity to the canonical domain wonder.
    #[must_use]
    pub const fn domain(self) -> WonderType {
        match self {
            Self::GreatLibrary => WonderType::GreatLibrary,
            Self::HangingGardens => WonderType::HangingGardens,
            Self::GreatWall => WonderType::GreatWall,
            Self::Petra => WonderType::Petra,
            Self::CentralBank => WonderType::CentralBank,
            Self::ImperialUniversity => WonderType::ImperialUniversity,
            Self::GrandCathedral => WonderType::GrandCathedral,
            Self::MotherFactory => WonderType::MotherFactory,
            Self::NationalObservatory => WonderType::NationalObservatory,
            Self::SvalbardSeedVault => WonderType::SvalbardSeedVault,
            Self::GrandExposition => WonderType::GrandExposition,
        }
    }
}

/// Resource referenced by a technology boost or effect.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum TechnologyResource {
    Wheat,
    Fish,
    Rice,
    Iron,
    Coal,
    Oil,
    Aluminium,
    Uranium,
    Horses,
    Marble,
}

impl TechnologyResource {
    /// Maps the ruleset identity to the canonical domain resource.
    #[must_use]
    pub const fn domain(self) -> ResourceType {
        match self {
            Self::Wheat => ResourceType::Wheat,
            Self::Fish => ResourceType::Fish,
            Self::Rice => ResourceType::Rice,
            Self::Iron => ResourceType::Iron,
            Self::Coal => ResourceType::Coal,
            Self::Oil => ResourceType::Oil,
            Self::Aluminium => ResourceType::Aluminium,
            Self::Uranium => ResourceType::Uranium,
            Self::Horses => ResourceType::Horses,
            Self::Marble => ResourceType::Marble,
        }
    }
}
