use aonw_domain::{FieldImprovementKind, InfrastructureState, TransportCondition, TransportKind};

use super::writer::DigestWriter;

pub(super) fn hash_infrastructure(writer: &mut DigestWriter, state: &InfrastructureState) {
    let mut improvements = state.field_improvements().iter().collect::<Vec<_>>();
    improvements.sort_unstable_by_key(|improvement| improvement.coordinate());
    writer.usize(improvements.len());
    for improvement in improvements {
        writer.coordinate(improvement.coordinate());
        writer.u8(improvement_tag(improvement.kind()));
        writer.optional_text(
            improvement
                .built_by_city_id()
                .map(aonw_domain::CityId::as_str),
        );
    }

    writer.usize(state.transport_network().segments().len());
    for segment in state.transport_network().segments() {
        writer.coordinate(segment.coordinate());
        writer.u8(match segment.kind() {
            TransportKind::Road => 0,
        });
        writer.u8(match segment.condition() {
            TransportCondition::Operational => 0,
            TransportCondition::Pillaged => 1,
        });
        writer.text(segment.built_by_player_id().as_str());
        writer.optional_text(segment.built_by_city_id().map(aonw_domain::CityId::as_str));
    }
}

pub(super) const fn improvement_tag(kind: FieldImprovementKind) -> u8 {
    match kind {
        FieldImprovementKind::Farm => 0,
        FieldImprovementKind::RiverFarm => 1,
        FieldImprovementKind::Mine => 2,
        FieldImprovementKind::LumberMill => 3,
        FieldImprovementKind::Pasture => 4,
        FieldImprovementKind::Camp => 5,
        FieldImprovementKind::Quarry => 6,
        FieldImprovementKind::FishingBoats => 7,
        FieldImprovementKind::Orchard => 8,
        FieldImprovementKind::Plantation => 9,
        FieldImprovementKind::Vineyard => 10,
        FieldImprovementKind::TradingPost => 11,
        FieldImprovementKind::ProspectorCamp => 12,
        FieldImprovementKind::HorseRanch => 13,
        FieldImprovementKind::PearlDivers => 14,
        FieldImprovementKind::CoalShaft => 15,
        FieldImprovementKind::OilWell => 16,
        FieldImprovementKind::BauxiteMine => 17,
        FieldImprovementKind::UraniumMine => 18,
    }
}
