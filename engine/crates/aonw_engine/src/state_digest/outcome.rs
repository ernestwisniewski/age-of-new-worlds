use aonw_domain::{GameOutcome, GameOutcomeCondition};

use super::writer::DigestWriter;

pub(super) fn hash_outcome(writer: &mut DigestWriter, outcome: &GameOutcome) {
    writer.u8(match outcome.condition() {
        GameOutcomeCondition::Ongoing => 0,
        GameOutcomeCondition::Conquest => 1,
        GameOutcomeCondition::Domination => 2,
        GameOutcomeCondition::Cultural => 3,
        GameOutcomeCondition::Score => 4,
        GameOutcomeCondition::Resignation => 5,
        GameOutcomeCondition::Draw => 6,
    });
    writer.optional_text(
        outcome
            .winner_player_id()
            .map(aonw_domain::PlayerId::as_str),
    );
    writer.usize(outcome.score_by_player_id().len());
    for (player, score) in outcome.score_by_player_id() {
        writer.text(player.as_str());
        writer.i64(*score);
    }
}
