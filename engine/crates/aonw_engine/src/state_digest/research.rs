use aonw_domain::{KnowledgeState, TechnologyId};

use super::city::wonder_tag;
use super::writer::DigestWriter;

pub(super) fn hash_knowledge(writer: &mut DigestWriter, state: &KnowledgeState) {
    writer.usize(state.research().players().len());
    for (player, research) in state.research().players() {
        writer.text(player.as_str());
        writer.usize(research.unlocked_technology_ids().len());
        for technology in research.unlocked_technology_ids() {
            writer.u8(technology_tag(*technology));
        }
        match research.active_technology_id() {
            None => writer.u8(0),
            Some(technology) => {
                writer.u8(1);
                writer.u8(technology_tag(technology));
            }
        }
        writer.usize(research.progress_by_technology_id().len());
        for (technology, progress) in research.progress_by_technology_id() {
            writer.u8(technology_tag(*technology));
            writer.i64(*progress);
        }
        writer.i64(research.science_overflow());
    }

    writer.usize(state.wonder_registry().completed_by().len());
    for (wonder, player) in state.wonder_registry().completed_by() {
        writer.u8(wonder_tag(*wonder));
        writer.text(player.as_str());
    }
}

pub(super) const fn technology_tag(value: TechnologyId) -> u8 {
    match value {
        TechnologyId::Agriculture => 0,
        TechnologyId::Woodworking => 1,
        TechnologyId::Mining => 2,
        TechnologyId::AnimalHusbandry => 3,
        TechnologyId::Hunting => 4,
        TechnologyId::Fishing => 5,
        TechnologyId::Craftsmanship => 6,
        TechnologyId::Trade => 7,
        TechnologyId::Storage => 8,
        TechnologyId::WaterEngineering => 9,
        TechnologyId::Stoneworking => 10,
        TechnologyId::MilitaryOrganization => 11,
        TechnologyId::AdvancedTrade => 12,
        TechnologyId::Construction => 13,
        TechnologyId::Navigation => 14,
        TechnologyId::Irrigation => 15,
        TechnologyId::Banking => 16,
        TechnologyId::Engineering => 17,
        TechnologyId::Metallurgy => 18,
        TechnologyId::HorsebackRiding => 19,
        TechnologyId::IronWorking => 20,
        TechnologyId::CoalMining => 21,
        TechnologyId::Machinery => 22,
        TechnologyId::Administration => 23,
        TechnologyId::Logistics => 24,
        TechnologyId::Shipbuilding => 25,
        TechnologyId::Tactics => 26,
        TechnologyId::Economy => 27,
        TechnologyId::Urbanization => 28,
        TechnologyId::Fortifications => 29,
        TechnologyId::Strategy => 30,
        TechnologyId::Specialization => 31,
        TechnologyId::Writing => 32,
        TechnologyId::Mathematics => 33,
        TechnologyId::Medicine => 34,
        TechnologyId::CivilService => 35,
        TechnologyId::Siegecraft => 36,
        TechnologyId::Cartography => 37,
        TechnologyId::Guilds => 38,
        TechnologyId::Law => 39,
        TechnologyId::Education => 40,
        TechnologyId::UrbanPlanning => 41,
        TechnologyId::NavalDoctrine => 42,
        TechnologyId::Steel => 43,
        TechnologyId::Bureaucracy => 44,
        TechnologyId::Nationalism => 45,
        TechnologyId::ScientificMethod => 46,
        TechnologyId::SteamPower => 47,
        TechnologyId::Electricity => 48,
        TechnologyId::Combustion => 49,
        TechnologyId::Flight => 50,
        TechnologyId::MassProduction => 51,
        TechnologyId::Radio => 52,
        TechnologyId::NuclearPhysics => 53,
    }
}
