use aonw_domain::{
    City, CityBuildingType, CityProductionTarget, CityProjectType, CitySpecializationType,
    WonderType,
};

use super::economy::hash_stockpile;
use super::writer::DigestWriter;

pub(super) fn hash_city(writer: &mut DigestWriter, city: &City) {
    writer.text(city.id().as_str());
    writer.text(city.owner_player_id().as_str());
    writer.optional_text(
        city.founding_owner_player_id()
            .map(aonw_domain::PlayerId::as_str),
    );
    writer.text(city.name());
    writer.i64(city.population());
    writer.i64(city.stored_food());
    writer.i64(city.max_hexes());
    writer.i64(city.territory_radius());
    writer.coordinate(city.center());
    writer.coordinates(city.controlled_hexes());
    writer.coordinates(city.worked_hexes());
    writer.usize(city.buildings().len());
    for building in city.buildings() {
        writer.u8(building_tag(*building));
    }
    writer.usize(city.wonders().len());
    for wonder in city.wonders() {
        writer.u8(wonder_tag(*wonder));
    }
    match city.production_queue() {
        None => writer.u8(0),
        Some(queue) => {
            writer.u8(1);
            match queue.target() {
                CityProductionTarget::Building(value) => {
                    writer.u8(0);
                    writer.u8(building_tag(value));
                }
                CityProductionTarget::Unit(value) => {
                    writer.u8(1);
                    writer.u8(super::unit_kind_tag(value));
                }
                CityProductionTarget::Project(value) => {
                    writer.u8(2);
                    writer.u8(match value {
                        CityProjectType::Wealth => 0,
                        CityProjectType::Research => 1,
                    });
                }
                CityProductionTarget::Wonder(value) => {
                    writer.u8(3);
                    writer.u8(wonder_tag(value));
                }
            }
            writer.i64(queue.invested_production());
            hash_stockpile(writer, queue.resource_allocation());
        }
    }
    writer.i64(city.production_overflow());
    match city.specialization() {
        None => writer.u8(0),
        Some(value) => {
            writer.u8(1);
            writer.u8(match value {
                CitySpecializationType::Growth => 0,
                CitySpecializationType::Industry => 1,
                CitySpecializationType::Commerce => 2,
                CitySpecializationType::Science => 3,
                CitySpecializationType::Military => 4,
            });
        }
    }
    writer.optional_coordinate(city.preferred_expansion_hex());
    writer.optional_i64(city.hit_points());
}

pub(super) const fn wonder_tag(value: WonderType) -> u8 {
    match value {
        WonderType::GreatLibrary => 0,
        WonderType::HangingGardens => 1,
        WonderType::GreatWall => 2,
        WonderType::Petra => 3,
        WonderType::CentralBank => 4,
        WonderType::ImperialUniversity => 5,
        WonderType::GrandCathedral => 6,
        WonderType::MotherFactory => 7,
        WonderType::NationalObservatory => 8,
        WonderType::SvalbardSeedVault => 9,
        WonderType::GrandExposition => 10,
    }
}

pub(super) const fn building_tag(value: CityBuildingType) -> u8 {
    match value {
        CityBuildingType::Granary => 0,
        CityBuildingType::WaterMill => 1,
        CityBuildingType::Workshop => 2,
        CityBuildingType::Storehouse => 3,
        CityBuildingType::Housing => 4,
        CityBuildingType::MerchantHall => 5,
        CityBuildingType::Stonemason => 6,
        CityBuildingType::Barracks => 7,
        CityBuildingType::Marketplace => 8,
        CityBuildingType::Port => 9,
        CityBuildingType::Aqueduct => 10,
        CityBuildingType::Forge => 11,
        CityBuildingType::Stable => 12,
        CityBuildingType::Bank => 13,
        CityBuildingType::BuildersGuild => 14,
        CityBuildingType::Factory => 15,
        CityBuildingType::Lighthouse => 16,
        CityBuildingType::TrainingGrounds => 17,
        CityBuildingType::TownHall => 18,
        CityBuildingType::Monument => 19,
        CityBuildingType::Archive => 20,
        CityBuildingType::Academy => 21,
        CityBuildingType::University => 22,
        CityBuildingType::Observatory => 23,
        CityBuildingType::Laboratory => 24,
        CityBuildingType::Reactor => 25,
        CityBuildingType::Courthouse => 26,
        CityBuildingType::Court => 27,
        CityBuildingType::GovernorsOffice => 28,
        CityBuildingType::SurveyorsOffice => 29,
        CityBuildingType::PlanningOffice => 30,
        CityBuildingType::Apothecary => 31,
        CityBuildingType::PublicBaths => 32,
        CityBuildingType::Hospital => 33,
        CityBuildingType::Ministries => 34,
        CityBuildingType::Walls => 35,
        CityBuildingType::Armory => 36,
        CityBuildingType::SiegeWorkshop => 37,
        CityBuildingType::Citadel => 38,
        CityBuildingType::WarCollege => 39,
        CityBuildingType::ConscriptionOffice => 40,
        CityBuildingType::BorderFort => 41,
        CityBuildingType::Airfield => 42,
        CityBuildingType::ArtisansGuild => 43,
        CityBuildingType::MasterWorkshop => 44,
        CityBuildingType::Steelworks => 45,
        CityBuildingType::RailDepot => 46,
        CityBuildingType::PowerPlant => 47,
        CityBuildingType::AssemblyPlant => 48,
        CityBuildingType::Refinery => 49,
        CityBuildingType::MapRoom => 50,
        CityBuildingType::Shipyard => 51,
        CityBuildingType::DryDock => 52,
        CityBuildingType::NavalAcademy => 53,
        CityBuildingType::HarborCustoms => 54,
        CityBuildingType::Museum => 55,
        CityBuildingType::Parliament => 56,
        CityBuildingType::BroadcastTower => 57,
        CityBuildingType::WorldFairGrounds => 58,
    }
}
