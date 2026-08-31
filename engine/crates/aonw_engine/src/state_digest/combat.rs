use aonw_domain::{CityConquestAction, CombatState};

use super::writer::DigestWriter;

pub(super) fn hash_combat(writer: &mut DigestWriter, state: &CombatState) {
    writer.usize(state.intended_attacks().len());
    for attack in state.intended_attacks() {
        writer.text(attack.attacker_unit_id().as_str());
        writer.coordinate(attack.defender());
        writer.u64(attack.declared_at_tick().get());
        writer.text(attack.declaring_player_id().as_str());
        writer.u8(match attack.city_conquest_action() {
            CityConquestAction::Capture => 0,
            CityConquestAction::Destroy => 1,
        });
    }
}
