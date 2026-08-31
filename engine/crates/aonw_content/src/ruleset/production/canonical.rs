use aonw_domain::{CityBuildingType, UnitKind, WonderType};
use serde::{Serialize, Serializer, ser::SerializeStruct};

use super::{BuildingProductionDefinition, UnitProductionDefinition, WonderProductionDefinition};

impl Serialize for BuildingProductionDefinition {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let mut value = serializer.serialize_struct("BuildingProductionDefinition", 9)?;
        value.serialize_field("building", building_name(self.building))?;
        value.serialize_field("baseCost", &self.base_cost)?;
        value.serialize_field("requirements", self.requirements)?;
        value.serialize_field("yieldDelta", &self.yield_delta)?;
        value.serialize_field("riverYieldPerHex", &self.river_yield_per_hex)?;
        value.serialize_field("maxRiverApplications", &self.max_river_applications)?;
        value.serialize_field("sciencePerTurn", &self.science_per_turn)?;
        value.serialize_field("maxControlledHexesDelta", &self.max_controlled_hexes_delta)?;
        value.serialize_field("foodDepositBasisPoints", &self.food_deposit_basis_points)?;
        value.end()
    }
}

impl Serialize for UnitProductionDefinition {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let mut value = serializer.serialize_struct("UnitProductionDefinition", 6)?;
        value.serialize_field("unit", unit_name(self.unit))?;
        value.serialize_field("baseCost", &self.base_cost)?;
        value.serialize_field("upkeep", &self.upkeep)?;
        value.serialize_field("supplyCost", &self.supply_cost)?;
        value.serialize_field("presenceResources", self.presence_resources)?;
        value.serialize_field("strategicCostOptions", self.strategic_cost_options)?;
        value.end()
    }
}

impl Serialize for WonderProductionDefinition {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let mut value = serializer.serialize_struct("WonderProductionDefinition", 12)?;
        value.serialize_field("wonder", wonder_name(self.wonder))?;
        value.serialize_field("baseCost", &self.base_cost)?;
        value.serialize_field("requirements", self.requirements)?;
        value.serialize_field("hostYield", &self.host_yield)?;
        value.serialize_field("empireYieldPerCity", &self.empire_yield_per_city)?;
        value.serialize_field("empireSciencePerCity", &self.empire_science_per_city)?;
        value.serialize_field("empireGoldBasisPoints", &self.empire_gold_basis_points)?;
        let production_basis_points = &self.empire_production_basis_points;
        value.serialize_field("empireProductionBasisPoints", production_basis_points)?;
        value.serialize_field("stabilityDelta", &self.stability_delta)?;
        let free_technology = &self.grant_free_active_technology;
        value.serialize_field("grantFreeActiveTechnology", free_technology)?;
        value.serialize_field("productionBurst", &self.production_burst)?;
        value.serialize_field("grantGold", &self.grant_gold)?;
        value.end()
    }
}

const fn building_name(value: CityBuildingType) -> &'static str {
    match value {
        CityBuildingType::Granary => "granary",
        CityBuildingType::WaterMill => "waterMill",
        CityBuildingType::Workshop => "workshop",
        CityBuildingType::Storehouse => "storehouse",
        CityBuildingType::Housing => "housing",
        CityBuildingType::MerchantHall => "merchantHall",
        CityBuildingType::Stonemason => "stonemason",
        CityBuildingType::Barracks => "barracks",
        CityBuildingType::Marketplace => "marketplace",
        CityBuildingType::Port => "port",
        CityBuildingType::Aqueduct => "aqueduct",
        CityBuildingType::Forge => "forge",
        CityBuildingType::Stable => "stable",
        CityBuildingType::Bank => "bank",
        CityBuildingType::BuildersGuild => "buildersGuild",
        CityBuildingType::Factory => "factory",
        CityBuildingType::Lighthouse => "lighthouse",
        CityBuildingType::TrainingGrounds => "trainingGrounds",
        CityBuildingType::TownHall => "townHall",
        CityBuildingType::Monument => "monument",
        CityBuildingType::Archive => "archive",
        CityBuildingType::Academy => "academy",
        CityBuildingType::University => "university",
        CityBuildingType::Observatory => "observatory",
        CityBuildingType::Laboratory => "laboratory",
        CityBuildingType::Reactor => "reactor",
        CityBuildingType::Courthouse => "courthouse",
        CityBuildingType::Court => "court",
        CityBuildingType::GovernorsOffice => "governorsOffice",
        CityBuildingType::SurveyorsOffice => "surveyorsOffice",
        CityBuildingType::PlanningOffice => "planningOffice",
        CityBuildingType::Apothecary => "apothecary",
        CityBuildingType::PublicBaths => "publicBaths",
        CityBuildingType::Hospital => "hospital",
        CityBuildingType::Ministries => "ministries",
        CityBuildingType::Walls => "walls",
        CityBuildingType::Armory => "armory",
        CityBuildingType::SiegeWorkshop => "siegeWorkshop",
        CityBuildingType::Citadel => "citadel",
        CityBuildingType::WarCollege => "warCollege",
        CityBuildingType::ConscriptionOffice => "conscriptionOffice",
        CityBuildingType::BorderFort => "borderFort",
        CityBuildingType::Airfield => "airfield",
        CityBuildingType::ArtisansGuild => "artisansGuild",
        CityBuildingType::MasterWorkshop => "masterWorkshop",
        CityBuildingType::Steelworks => "steelworks",
        CityBuildingType::RailDepot => "railDepot",
        CityBuildingType::PowerPlant => "powerPlant",
        CityBuildingType::AssemblyPlant => "assemblyPlant",
        CityBuildingType::Refinery => "refinery",
        CityBuildingType::MapRoom => "mapRoom",
        CityBuildingType::Shipyard => "shipyard",
        CityBuildingType::DryDock => "dryDock",
        CityBuildingType::NavalAcademy => "navalAcademy",
        CityBuildingType::HarborCustoms => "harborCustoms",
        CityBuildingType::Museum => "museum",
        CityBuildingType::Parliament => "parliament",
        CityBuildingType::BroadcastTower => "broadcastTower",
        CityBuildingType::WorldFairGrounds => "worldFairGrounds",
    }
}

const fn unit_name(value: UnitKind) -> &'static str {
    match value {
        UnitKind::Commander => "commander",
        UnitKind::Warrior => "warrior",
        UnitKind::Archer => "archer",
        UnitKind::Settler => "settler",
        UnitKind::Worker => "worker",
        UnitKind::Merchant => "merchant",
        UnitKind::Scout => "scout",
        UnitKind::Spearman => "spearman",
        UnitKind::Cavalry => "cavalry",
        UnitKind::Catapult => "catapult",
        UnitKind::HeavyInfantry => "heavyInfantry",
        UnitKind::FieldCannon => "fieldCannon",
        UnitKind::Rifleman => "rifleman",
        UnitKind::Tank => "tank",
        UnitKind::ScoutShip => "scoutShip",
        UnitKind::Warship => "warship",
        UnitKind::ReconPlane => "reconPlane",
    }
}

const fn wonder_name(value: WonderType) -> &'static str {
    match value {
        WonderType::GreatLibrary => "greatLibrary",
        WonderType::HangingGardens => "hangingGardens",
        WonderType::GreatWall => "greatWall",
        WonderType::Petra => "petra",
        WonderType::CentralBank => "centralBank",
        WonderType::ImperialUniversity => "imperialUniversity",
        WonderType::GrandCathedral => "grandCathedral",
        WonderType::MotherFactory => "motherFactory",
        WonderType::NationalObservatory => "nationalObservatory",
        WonderType::SvalbardSeedVault => "svalbardSeedVault",
        WonderType::GrandExposition => "grandExposition",
    }
}
