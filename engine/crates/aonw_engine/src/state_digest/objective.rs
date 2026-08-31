use aonw_domain::ObjectiveState;

use super::writer::DigestWriter;

pub(super) fn hash_objectives(writer: &mut DigestWriter, state: &ObjectiveState) {
    hash_player_holds(writer, state.domination_hold_turns_by_player_id());
    hash_player_holds(writer, state.cultural_victory_hold_turns_by_player_id());
    writer.usize(state.map_objective_hold_states().len());
    for hold in state.map_objective_hold_states() {
        writer.text(hold.objective_id());
        writer.text(hold.player_id().as_str());
        writer.u32(hold.hold_turns());
    }
}

fn hash_player_holds(
    writer: &mut DigestWriter,
    holds: &std::collections::BTreeMap<aonw_domain::PlayerId, u32>,
) {
    writer.usize(holds.len());
    for (player, turns) in holds {
        writer.text(player.as_str());
        writer.u32(*turns);
    }
}
