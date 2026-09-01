use serde::{Deserialize, Serialize};

/// One revision-bound player command stored in a replay.
///
/// Client dispatch and deterministic replay intentionally share one closed
/// wire shape so adding a player command cannot update only one boundary.
pub type ReplayCommandDto = crate::client::ClientCommandDto;

/// Trusted host commands stored separately from player-authored requests.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ReplaySystemCommandDto {
    /// Finalizes one expired simultaneous turn.
    FinalizeTimedOutTurn {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Ordered participant scope selected by the host.
        player_ids: Vec<String>,
        /// Ordered participants finalized because of timeout.
        skipped_player_ids: Vec<String>,
        /// Explicit host-provided next-turn UTC time when rule-relevant.
        next_turn_started_at: Option<String>,
    },
    /// Removes one participant from the active match lifecycle.
    KickParticipant {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Participant selected by the host.
        player_id: String,
        /// Stable host-owned reason.
        reason: String,
        /// Timeout streak observed by the host.
        timeout_streak: i64,
    },
}
